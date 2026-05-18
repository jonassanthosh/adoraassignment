import 'package:geolocator/geolocator.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class GeolocatorDataSource {
  Future<bool> isServiceEnabled() => Geolocator.isLocationServiceEnabled();

  Future<Position> getCurrent() => Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,            // emit when moved 10 m
          timeLimit: Duration(seconds: 10),
        ),
      );

  Stream<Position> stream() => Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,            // emit when moved 10 m
        ),
      );
}