// Thin wrapper around the `permission_handler` package that encapsulates the
// platform-specific quirks of asking for "location while in use" permission.
//
// The goal is to return a small, easy-to-consume value object
// ([LocationPermissionResult]) so callers don't have to reason about the
// different [PermissionStatus] enum values themselves.

import 'package:permission_handler/permission_handler.dart';

/// Outcome of a permission request, designed to express the three things a
/// caller usually cares about:
///   * [granted]      — was permission ultimately granted?
///   * [openSettings] — should the UI offer a "go to Settings" affordance
///                      because the user permanently denied the permission
///                      and can no longer grant it through a runtime prompt?
///   * [error]        — optional human-readable message for the non-permanent
///                      denial case (useful for surfacing in a SnackBar).
class LocationPermissionResult{
  const LocationPermissionResult(this.granted, { this.openSettings = false, this.error });
  final bool granted;
  final bool openSettings;
  final String? error;
}

/// Ensures the app has "location while in use" permission, requesting it from
/// the user if necessary.
///
/// Flow:
///   1. If the permission is already granted, return early.
///   2. If it has been permanently denied, do *not* re-prompt (the OS will
///      silently reject the request); instead signal the caller to send the
///      user to the system settings.
///   3. Otherwise request the permission and translate the resulting status
///      into a [LocationPermissionResult].
Future<LocationPermissionResult> ensureLocationPermission() async {

  // Check the current status first to avoid showing a redundant prompt to a
  // user who has already made a decision.
  var status = await Permission.locationWhenInUse.status;
  if (status.isGranted) { return LocationPermissionResult(true); }

  // A "permanently denied" status means iOS/Android will not show the system
  // prompt again — the only path forward is for the user to flip the toggle
  // in the OS settings.
  if (status.isPermanentlyDenied) { return LocationPermissionResult(false, openSettings: true); }

  // Trigger the native permission dialog. This is the only call here that
  // may actually present UI to the user.
  status = await Permission.locationWhenInUse.request();

  if (status.isGranted) return const LocationPermissionResult(true); 

  // The user may have tapped "Don't ask again" during the request itself, in
  // which case the status becomes permanently denied right after asking.
  if (status.isPermanentlyDenied) { return LocationPermissionResult(false, openSettings: true); }

  // Plain denial (the user said no but can be asked again in the future).
  return LocationPermissionResult(false, error: 'Location permission denied');
}
