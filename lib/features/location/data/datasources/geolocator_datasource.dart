import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:injectable/injectable.dart';

/// Thin wrapper over the `geolocator` plugin that centralises platform-aware
/// `LocationSettings`. The rest of the data layer never builds these
/// settings inline so we have a single place to tune accuracy / distance
/// filter / background behaviour.
@lazySingleton
class GeolocatorDataSource {
  Future<bool> isServiceEnabled() => Geolocator.isLocationServiceEnabled();

  Future<Position> getCurrent() => Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10, // emit when moved 10 m
          timeLimit: Duration(seconds: 10),
        ),
      );

  /// Continuous position stream. Callers can pass `settings` to override
  /// the platform default — e.g. the background isolate uses its own
  /// because it doesn't need iOS-specific background flags.
  Stream<Position> stream([LocationSettings? settings]) =>
      Geolocator.getPositionStream(
        locationSettings: settings ?? _locationSettings(),
      );

  /// Branches on `defaultTargetPlatform` because each OS needs different
  /// knobs:
  ///   - **iOS** needs `allowBackgroundLocationUpdates: true` and
  ///     `showBackgroundLocationIndicator: true` for the blue status bar
  ///     while the app is in the background. `pauseLocationUpdatesAutomatically`
  ///     is disabled so iOS doesn't quietly stop the stream when it thinks
  ///     the user has stopped moving.
  ///   - **Android** intentionally omits `foregroundNotificationConfig`:
  ///     the foreground-service notification is owned by
  ///     `flutter_background_service`, so letting geolocator post its own
  ///     would result in two competing notifications.
  LocationSettings _locationSettings() {
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return AppleSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
          activityType: ActivityType.other,
          pauseLocationUpdatesAutomatically: false,
          showBackgroundLocationIndicator: true,
          allowBackgroundLocationUpdates: true,
        );
      case TargetPlatform.android:
        return AndroidSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        );
      default:
        return const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        );
    }
  }
}
