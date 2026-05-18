import '../entities/location_entities.dart';

abstract class LocationRepository {
  Future<LocationEntity> getCurrentLocation();

  Stream<LocationEntity> watchLocations();

  Future<void> startTracking({bool useBackground = false});

  Future<void> stopTracking();

  Future<LocationEntity?> getLastKnown();
}