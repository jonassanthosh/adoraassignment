// Domain-level service that owns the "fetch current device location" use case.
//
// It hides the details of the `geolocator` package and the
// `permission_handler` flow behind a single [getCurrentPosition] method that
// either resolves with a [Position] or throws a [LocationFetchException] the
// UI/bloc layer can render directly.

import 'package:geolocator/geolocator.dart';
import 'permission_helper.dart';

/// Domain exception thrown by [LocationService.getCurrentPosition] whenever
/// the location cannot be obtained for any reason (services off, permission
/// denied, timeout, etc.).
///
/// The [message] is intended to be user-facing — keep it concise and free of
/// technical jargon. [openSettings] is set to true when the only way for the
/// user to recover is to open the system settings (e.g. they have permanently
/// denied the permission). Consumers can use this flag to decide whether to
/// display an "Open Settings" button.
class LocationFetchException implements Exception {
  LocationFetchException(this.message, { this.openSettings = false });
  final String message;
  final bool openSettings;

  @override
  String toString() => message;
}

/// Service responsible for fetching the current device location.
///
/// Kept as a class (rather than a top-level function) so that it can be
/// registered with `get_it` and easily swapped out for a fake/mock in tests.
class LocationService {

  /// Fetches a single high-accuracy location reading.
  ///
  /// Performs all the necessary preflight checks before talking to the GPS:
  ///   1. Verifies that the OS-level location services switch is on. If not,
  ///      throws a [LocationFetchException] because the app itself cannot
  ///      enable it (the user must do so in system settings).
  ///   2. Ensures the app has runtime permission via [ensureLocationPermission].
  ///   3. Requests a position with a 10 second timeout so the call cannot
  ///      hang indefinitely in poor GPS conditions (indoors, underground...).
  ///
  /// Any error raised by the underlying plugin is wrapped in a
  /// [LocationFetchException] so callers only ever have to catch a single
  /// exception type.
  Future<Position> getCurrentPosition() async {

  // Step 1 — system-wide location services must be enabled.
  final serviceOn = await Geolocator.isLocationServiceEnabled();
  if (!serviceOn) {
    throw LocationFetchException('Location services are disabled. Please enable them in your settings.');
  }

  // Step 2 — app-level runtime permission.
  final perm = await ensureLocationPermission();
  if (!perm.granted) {
    // Use a more descriptive message for the permanently-denied case and
    // forward the `openSettings` flag so the UI can offer a settings button.
    throw LocationFetchException(
      perm.openSettings ?
      'Location permission is permanently denied. Please open settings and grant permission to use location services.' :
      (perm.error ?? "Permission denied"),
      openSettings: perm.openSettings,
    );
  }

  // Step 3 — actually request the position. The 10 s timeout is a defensive
  // upper bound; without it the future could remain unresolved indefinitely
  // when the device cannot get a GPS fix.
  try {
    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      )
    );
  } on Object catch (e){
    // Catch-all so platform errors, timeouts and other unexpected failures
    // are normalised into the single exception type used by this service.
    throw LocationFetchException('Failed to fetch location: $e');
  }
}

}

