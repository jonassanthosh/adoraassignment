import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/location_bloc.dart';
import '../bloc/location_event.dart';
import '../bloc/location_state.dart';

class LocationPage extends StatelessWidget {
  const LocationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Location')),
      body: Center(
        child: BlocBuilder<LocationBloc, LocationState>(
          builder: (context, state) {
            return switch (state) {
              LocationIdle() => const Text('Tap Start to begin'),
              LocationLoading() => const CircularProgressIndicator(),
              LocationTracking(:final last) => Text(
                  '${last.latitude.toStringAsFixed(5)}, '
                  '${last.longitude.toStringAsFixed(5)}',
                ),
              LocationFailure(:final message) => Text(
                  'Error: $message',
                  style: const TextStyle(color: Colors.red),
                ),
            };
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context
            .read<LocationBloc>()
            .add(const LocationEvent.startTracking()),
        child: const Icon(Icons.my_location),
      ),
    );
  }
}