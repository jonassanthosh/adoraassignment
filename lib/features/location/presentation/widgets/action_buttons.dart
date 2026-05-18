import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/location_bloc.dart';
import '../bloc/location_event.dart';
import '../bloc/location_state.dart';
import '../bloc/settings_cubit.dart';

class ActionButtons extends StatelessWidget {
  const ActionButtons({super.key, required this.state});

  final LocationState state;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<LocationBloc>();
    final isTracking = state is LocationTracking || state is LocationLoading;
    final failure = state is LocationFailure ? state as LocationFailure : null;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: isTracking
                    ? null
                    : () {
                        final useBackground = context
                            .read<SettingsCubit>()
                            .state
                            .backgroundEnabled;
                        bloc.add(LocationEvent.startTracking(
                          useBackground: useBackground,
                        ));
                      },
                icon: const Icon(Icons.play_arrow),
                label: const Text('Start'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: isTracking
                    ? () => bloc.add(const LocationEvent.stopTracking())
                    : null,
                icon: const Icon(Icons.stop),
                label: const Text('Stop'),
              ),
            ),
          ],
        ),
        if (failure?.openSettings == true) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () =>
                  bloc.add(const LocationEvent.openSettingsRequested()),
              icon: const Icon(Icons.settings),
              label: const Text('Open Settings'),
            ),
          ),
        ],
      ],
    );
  }
}
