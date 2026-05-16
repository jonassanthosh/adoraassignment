// Entry point for the Location Tracking application.
//
// This file is responsible for:
//   * Wiring up dependency injection via `get_it` so that services
//     (e.g. [LocationService]) can be resolved anywhere in the widget tree
//     without being passed manually through constructors.
//   * Bootstrapping the Flutter app by calling [runApp] with the root widget.
//   * Configuring the global [MaterialApp] (theme, title) and providing the
//     [LocationBloc] to the widget subtree rooted at [HomePage].

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import 'bloc/location_bloc.dart';
import 'location_service.dart';
import 'home_page.dart';

/// Global service locator used to register and retrieve singletons such as
/// [LocationService]. Exposed at the library level so any widget or bloc can
/// access shared dependencies without prop drilling.
final getIt = GetIt.instance;

/// Application entry point.
///
/// Registers the [LocationService] as a lazy singleton (created only the first
/// time it is requested) and then starts the Flutter app.
void main() {
  // Lazy registration keeps startup cheap; the service is only instantiated
  // when something actually asks for it.
  getIt.registerLazySingleton<LocationService>(() => LocationService());
  runApp(const LocationTrackingApp());
}

/// Root widget of the application.
///
/// Sets up the global [MaterialApp] configuration (theme, title) and provides
/// a [LocationBloc] scoped to the [HomePage] subtree. Using [BlocProvider]
/// here ensures the bloc lives for the entire lifetime of the home screen and
/// is automatically disposed when removed from the tree.
class LocationTrackingApp extends StatelessWidget {
  const LocationTrackingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Location Tracking',
      theme: ThemeData(
        // Material 3 color scheme derived from a single seed color for a
        // cohesive, accessible palette across light/dark surfaces.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: BlocProvider(
        // The bloc receives the [LocationService] resolved from the service
        // locator, keeping this widget free of concrete dependency wiring.
        create: (_) => LocationBloc(getIt<LocationService>()),
        child: const HomePage(),
        ),
    );
  }
}
