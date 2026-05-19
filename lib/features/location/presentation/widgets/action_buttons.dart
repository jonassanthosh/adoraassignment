import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/location_bloc.dart';
import '../bloc/location_event.dart';
import '../bloc/location_state.dart';
import '../bloc/settings_cubit.dart';

/// Foot of the home screen. Single, hero primary action that morphs between
/// Start and Stop, with a contextual "Open Settings" button when the BLoC
/// asks for it.
class ActionButtons extends StatelessWidget {
  const ActionButtons({super.key, required this.state});

  final LocationState state;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<LocationBloc>();
    final isTracking = state is LocationTracking || state is LocationLoading;
    final failure = state is LocationFailure ? state as LocationFailure : null;

    final scheme = Theme.of(context).colorScheme;

    final primary = isTracking
        ? FilledButton.tonalIcon(
            onPressed: () => bloc.add(const LocationEvent.stopTracking()),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
              backgroundColor: scheme.errorContainer,
              foregroundColor: scheme.onErrorContainer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: const Icon(Icons.stop_rounded),
            label: const Text('Stop tracking'),
          )
        : FilledButton.icon(
            onPressed: () {
              final useBackground = context
                  .read<SettingsCubit>()
                  .state
                  .backgroundEnabled;
              bloc.add(
                LocationEvent.startTracking(useBackground: useBackground),
              );
            },
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Start tracking'),
          );

    return Column(
      children: [
        SizedBox(width: double.infinity, child: primary),
        if (failure?.openSettings == true) ...[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () =>
                  bloc.add(const LocationEvent.openSettingsRequested()),
              icon: const Icon(Icons.settings_outlined),
              label: const Text('Open system settings'),
            ),
          ),
        ],
      ],
    );
  }
}
