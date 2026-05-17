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
              LocationFailure(:final message, :final openSettings) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Error: $message',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                    if (openSettings) ...[
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () => context
                            .read<LocationBloc>()
                            .add(const LocationEvent.openSettingsRequested()),
                        icon: const Icon(Icons.settings),
                        label: const Text('Open Settings'),
                      ),
                    ],
                  ],
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