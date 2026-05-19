import 'dart:async';
import 'dart:io';

import 'package:geolocator/geolocator.dart';
import 'package:injectable/injectable.dart';
import '../../domain/entities/location_entities.dart';
import '../../domain/repositories/location_repository.dart';
import '../datasources/geolocator_datasource.dart';
import '../models/location_model.dart';
import '../../../../services/background/background_service_controller.dart';
import '../../../../storage/location_database.dart';
import '../../../../services/background/ios_slc_bridge.dart';

/// Single concrete implementation of [LocationRepository]. Acts as the
/// **orchestrator** for the three location streams the app can be on at
/// once:
///   - **foreground** — `geolocator` while the UI is visible.
///   - **background** — Android foreground service (Dart isolate).
///   - **slc** — iOS Significant Location Changes (native isolate).
///
/// All three feed into a single broadcast `_controller` so the BLoC only
/// has to subscribe to one stream regardless of platform.
@LazySingleton(as: LocationRepository)
class LocationRepositoryImpl implements LocationRepository {
  LocationRepositoryImpl(this._geo, this._bg, this._db, this._slc);

  final GeolocatorDataSource _geo;
  final BackgroundServiceController _bg;
  final LocationDatabase _db;
  final IosSlcBridge _slc;

  // Held separately so we can cancel each subscription independently when
  // the user toggles background mode without fully stopping tracking.
  StreamSubscription<dynamic>? _fgSub;
  StreamSubscription<LocationEntity>? _bgSub;
  StreamSubscription<LocationEntity>? _slcSub;
  final _controller = StreamController<LocationEntity>.broadcast();

  @override
  Future<LocationEntity> getCurrentLocation() async {
    final pos = await _geo.getCurrent();
    return LocationModel.fromPosition(pos, source: 'foreground').toEntity();
  }

  /// Starts tracking. Stops any previous session first so callers can use
  /// this method as a "reconfigure" trigger (e.g. when the background
  /// toggle flips while tracking is already live).
  @override
  Future<void> startTracking({bool useBackground = false}) async {
    await stopTracking();

    if (useBackground) {
      if (Platform.isIOS) {
        // iOS background path = SLC. Low frequency, battery friendly,
        // survives termination.
        await _slc.start();
        _slcSub = _slc.updates().listen(_controller.add);
      } else if (Platform.isAndroid) {
        // Android background path = foreground service in a separate isolate.
        await _bg.start();
        _bgSub = _bg.updates().listen(_controller.add);
      }
    }

    // Foreground stream always runs while the app is in front; it's what
    // populates the UI between the slower background callbacks.
    _fgSub = _geo.stream().listen((p) {
      _controller.add(
        LocationModel.fromPosition(p, source: 'foreground').toEntity(),
      );
    });
  }

  @override
  Future<void> stopTracking() async {
    await _fgSub?.cancel();
    _fgSub = null;
    await _bgSub?.cancel();
    _bgSub = null;
    await _slcSub?.cancel();
    _slcSub = null;
    // `BackgroundServiceController.stop()` is idempotent, so the
    // unconditional call on the next line is safe even when the service
    // never started on this platform.
    await _bg.stop();
    if (Platform.isAndroid) await _bg.stop();
    if (Platform.isIOS) await _slc.stop();
  }

  @override
  Stream<LocationEntity> watchLocations() => _controller.stream;

  @override
  Future<LocationEntity?> getLastKnown() async {
    final row = await _db.last();
    if (row == null) return null;
    return LocationModel.fromRow(row).toEntity();
  }

  @override
  Stream<bool> watchTrackingState() async* {
    yield await _bg.isRunning();
    // Polling because flutter_background_service doesn't expose a state
    // stream — 2 s is a deliberate trade-off between responsiveness and
    // not burning CPU on a tight loop.
    yield* Stream.periodic(
      const Duration(seconds: 2),
    ).asyncMap((_) => _bg.isRunning()).distinct();
  }
}
