import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:location_tracking/features/location/domain/usecases/watch_locations.dart';
import '../../domain/entities/location_entities.dart';
import '../../domain/repositories/location_repository.dart';
import '../datasources/geolocator_datasource.dart';
import '../models/location_model.dart';
import '../../../../services/background/background_service_controller.dart';
import '../../../../storage/location_database.dart';

@LazySingleton(as: LocationRepository)
class LocationRepositoryImpl implements LocationRepository {
  LocationRepositoryImpl(this._geo, this._bg, this._db);

  final GeolocatorDataSource _geo;
  final BackgroundServiceController _bg;
  final LocationDatabase _db;

  StreamSubscription<dynamic>? _fgSub;
  StreamSubscription<LocationEntity>? _bgSub;
  final _controller = StreamController<LocationEntity>.broadcast();
  LocationEntity? _last;

  @override
  Future<LocationEntity> getCurrentLocation() async {
    final pos = await _geo.getCurrent();
    final entity = LocationModel.fromPosition(
      pos,
      source: 'foreground',
    ).toEntity();
    _last = entity;
    return entity;
  }

  @override
  Future<void> startTracking({bool useBackground = false}) async {
    await stopTracking();
    if (useBackground) {
      await _bg.start();
      _bgSub = _bg.updates().listen(
        (entity) async {
          try {
            await _db.insertLocation(
              lat: entity.latitude,
              lon: entity.longitude,
              accuracy: entity.accuracy,
              tsMillis: entity.timestamp.millisecondsSinceEpoch,
              source: 'background',
            );
          } catch (_) {
            // Best-effort persistence: never let a DB error stop the stream.
          }
          _controller.add(entity);
        },
        onError: (Object e, StackTrace st) {
          _controller.addError(e, st);
        },
      );
    } else {
      _fgSub = _geo.stream().listen((p) async {
        final entity = LocationModel.fromPosition(
          p,
          source: 'foreground',
        ).toEntity();
        await _db.insertLocation(
          lat: p.latitude,
          lon: p.longitude,
          accuracy: p.accuracy,
          tsMillis: (p.timestamp).millisecondsSinceEpoch,
          source: 'foreground',
        );
        _controller.add(entity);
      });
    }
  }

  @override
  Future<void> stopTracking() async {
    await _fgSub?.cancel();
    _fgSub = null;
    await _bgSub?.cancel();
    _bgSub = null;
    await _bg.stop();
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
