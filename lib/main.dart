import 'package:flutter/material.dart';
import 'package:location_tracking/services/background/background_service_setup.dart';
import 'core/di/injector.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  await initializeBackgroundService();
  runApp(const LocationTrackingApp());
}