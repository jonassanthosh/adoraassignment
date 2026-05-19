import 'package:flutter/material.dart';
import 'package:location_tracking/services/background/background_service_setup.dart';
import 'core/di/injector.dart';
import 'app.dart';

/// Entry point. Order matters:
///   1. `ensureInitialized` — the platform channels we use below all require
///      the binding to exist.
///   2. `configureDependencies` — resolves every `@preResolve` factory
///      (notably `LocationDatabase.open()`) so the rest of the graph can be
///      pulled synchronously from `getIt` at first use.
///   3. `initializeBackgroundService` — registers the Android notification
///      channel and configures `flutter_background_service`. Must run before
///      anything calls `BackgroundServiceController.start()`.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  await initializeBackgroundService();
  runApp(const LocationTrackingApp());
}
