// Legacy standalone implementation of the "get current position" use case.
//
// NOTE: The same [LocationFetchException] class and an equivalent procedural
// helper ([getCurrentPositionSafe]) also exist inside `location_service.dart`,
// where they are wrapped in the [LocationService] class that the rest of the
// app actually depends on. This file is kept as a top-level alternative for
// callers that prefer a plain function over a service object — but new code
// should prefer using [LocationService] so it can be injected and mocked.

import 'package:geolocator/geolocator.dart';
import 'permission_helper.dart';

/// Exception raised whenever a location cannot be obtained. Mirrors the
/// definition in `location_service.dart` so callers using either entry point
/// see the same shape.
///
/// [message] is intended to be shown directly to the user. [openSettings] is
/// true when the user must visit system settings to recover (e.g. they have
/// permanently denied the permission and the in-app prompt can no longer be
/// shown).
class LocationFetchException implements Exception {
  LocationFetchException(this.message, { this.openSettings = false });
  final String message;
  final bool openSettings;

  @override
  String toString() => message;
}

/// Fetches the current device location with all the necessary preflight
/// checks already performed:
///   1. Verifies that OS-level location services are enabled.
///   2. Requests / verifies the app's runtime location permission.
///   3. Calls [Geolocator.getCurrentPosition] with a 10 second timeout so the
///      future is guaranteed to settle even when the device cannot acquire a
///      GPS fix.
///
/// Any error is normalised into a [LocationFetchException] so callers only
/// need to catch one exception type.
Future<Position> getCurrentPositionSafe() async {

  // Step 1 — system-wide services must be on; the app cannot turn them on
  // itself, so we surface a clear message asking the user to do it.
  final serviceOn = await Geolocator.isLocationServiceEnabled();
  if (!serviceOn) {
    throw LocationFetchException('Location services are disabled. Please enable them in your settings.');
  }

  // Step 2 — make sure we have runtime permission (prompting if needed).
  final perm = await ensureLocationPermission();
  if (!perm.granted) {
    throw LocationFetchException(
      // Use a longer, more actionable message in the permanently-denied case
      // and forward the flag so the UI knows whether to show an "Open
      // Settings" button.
      perm.openSettings ?
      'Location permission is permanently denied. Please open settings and grant permission to use location services.' :
      (perm.error ?? "Permission denied"),
      openSettings: perm.openSettings,
    );
  }

  // Step 3 — actual GPS request. The 10 s `timeLimit` is a safety net; in
  // poor signal conditions Geolocator can otherwise keep waiting indefinitely.
  try {
    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      )
    );
  } on Object catch (e){
    // Wrap *any* failure (platform exception, timeout, etc.) so callers have
    // a single, predictable exception type to handle.
    throw LocationFetchException('Failed to fetch location: $e');
  }
}
