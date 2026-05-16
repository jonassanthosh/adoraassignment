import 'dart:async';

import 'package:injectable/injectable.dart';
import '../../domain/entities/location_entities.dart';
import '../../domain/repositories/location_repository.dart';
import '../datasources/geolocator_datasource.dart';
import '../models/location_model.dart';


@LazySingleton(as: LocationRepository)
class LocationRepositoryImpl implements LocationRepository {
  LocationRepositoryImpl(this._geo);

  final GeolocatorDataSource _geo;
  StreamSubscription<dynamic>? _sub;
  final _controller = StreamController<LocationEntity>.broadcast();
  LocationEntity? _last;

  @override
  Future<LocationEntity> getCurrentLocation() async {
    final pos = await _geo.getCurrent();
    final entity = LocationModel.fromPosition(pos, source: 'foreground').toEntity();
    _last = entity;
    return entity;
  }

  @override
  Stream<LocationEntity> watchLocations() => _controller.stream;

  @override
  Future<void> startTracking() async {
    if (_sub != null) return;
    _sub = _geo.stream().listen((pos) {
      final entity = LocationModel.fromPosition(pos, source: 'foreground').toEntity();
      _last = entity;
      _controller.add(entity);
    });
  }

  @override
  Future<void> stopTracking() async {
    await _sub?.cancel();
    _sub = null;
  }

  @override
  Future<LocationEntity?> getLastKnown() async => _last;
}