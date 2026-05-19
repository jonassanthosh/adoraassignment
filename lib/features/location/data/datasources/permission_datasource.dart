import 'package:geolocator/geolocator.dart';
import 'package:injectable/injectable.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../domain/entities/permission_status.dart';

/// Adapter that collapses the matrix of `permission_handler` enum values
/// into the small [LocationAuth] domain enum the BLoC actually reasons
/// about.
@lazySingleton
class PermissionDataSource {
  /// Reads the current authorization without prompting the user. Order
  /// matters: we check the OS-level toggle first because no app permission
  /// will help if the user has location services switched off entirely.
  Future<LocationAuth> current() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return LocationAuth.serviceDisabled;
    }

    final whileInUse = await Permission.locationWhenInUse.status;
    if (whileInUse.isPermanentlyDenied) return LocationAuth.deniedForever;
    if (whileInUse.isDenied) return LocationAuth.denied;

    // "Always" implies "while in use", so we only need to check it when
    // the first call already returned a granted status.
    final always = await Permission.locationAlways.status;
    if (always.isGranted) return LocationAuth.always;

    return LocationAuth.whileInUse;
  }

  /// Shows the standard "Allow While Using" prompt. If the OS dialog
  /// returns `permanentlyDenied` (the user picked "Don't ask again") we
  /// surface that explicitly so the UI can offer an Open-Settings button.
  Future<LocationAuth> requestWhileInUse() async {
    final result = await Permission.locationWhenInUse.request();
    if (result.isGranted) return current();
    if (result.isPermanentlyDenied) return LocationAuth.deniedForever;
    return LocationAuth.denied;
  }

  /// Upgrade prompt for background tracking. On iOS this is the
  /// "Change to Always Allow?" sheet; on Android 11+ this kicks the user
  /// out to the system settings page (the OS doesn't allow an in-app
  /// prompt anymore). We re-check via `current()` afterwards so the
  /// returned value is always grounded in reality.
  Future<LocationAuth> requestAlways() async {
    final result = await Permission.locationAlways.request();
    if (result.isGranted) return LocationAuth.always;
    return current();
  }

  Future<bool> openSettings() => openAppSettings();
}
