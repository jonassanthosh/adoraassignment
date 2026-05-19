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

@LazySingleton(as: LocationRepository)
class LocationRepositoryImpl implements LocationRepository {
  LocationRepositoryImpl(this._geo, this._bg, this._db, this._slc);

  final GeolocatorDataSource _geo;
  final BackgroundServiceController _bg;
  final LocationDatabase _db;
  final IosSlcBridge _slc;

  StreamSubscription<dynamic>? _fgSub;
  StreamSubscription<LocationEntity>? _bgSub;
  StreamSubscription<LocationEntity>? _slcSub;
  final _controller = StreamController<LocationEntity>.broadcast();

  @override
  Future<LocationEntity> getCurrentLocation() async {
    final pos = await _geo.getCurrent();
    final entity = LocationModel.fromPosition(
      pos,
      source: 'foreground',
    ).toEntity();
    return entity;
  }

  @override
  Future<void> startTracking({bool useBackground = false}) async {
    await stopTracking();

    if (useBackground) {
      if (Platform.isIOS) {
        await _slc.start();
        _slcSub = _slc.updates().listen((e) {
          _controller.add(e);
        });
      } else if (Platform.isAndroid) {
        await _bg.start();
        _bgSub = _bg.updates().listen(_controller.add);
      }
    }

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
    yield* Stream.periodic(
      const Duration(seconds: 2),
    ).asyncMap((_) => _bg.isRunning()).distinct();
  }
}
