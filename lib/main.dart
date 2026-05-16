import 'package:flutter/material.dart';
import 'core/di/injector.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  runApp(const LocationTrackingApp());
}