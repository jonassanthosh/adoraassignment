/// Domain-level location authorization. A deliberate simplification of
/// `permission_handler`'s `PermissionStatus` so the BLoC can `switch` on
/// the small set of states it actually needs to handle.
///
///   - [serviceDisabled] — OS toggle is off; no app permission can help.
///   - [notDetermined]   — user has never been prompted.
///   - [denied]          — user said no but can be asked again.
///   - [deniedForever]   — user picked "Don't ask again"; only the
///                         system settings can flip this back.
///   - [whileInUse]      — granted while the app is in the foreground.
///   - [always]          — granted in the background too. Required for
///                         background tracking and iOS SLC.
enum LocationAuth {
  notDetermined,
  whileInUse,
  always,
  denied,
  deniedForever,
  serviceDisabled,
}
