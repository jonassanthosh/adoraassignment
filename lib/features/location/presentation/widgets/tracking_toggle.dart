import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/location_bloc.dart';
import '../bloc/location_event.dart';
import '../bloc/settings_cubit.dart';

/// Card-wrapped switch for the background-tracking preference.
///
/// Flipping the switch does two things, deliberately in this order:
///   1. Persist the new preference via [SettingsCubit] — survives
///      restarts and is what [ActionButtons] reads on the next Start.
///   2. Tell [LocationBloc] about it so any *in-flight* session can
///      reconfigure (and trigger the "Always" permission upgrade)
///      without the user having to stop and restart.
class TrackingToggle extends StatelessWidget {
  const TrackingToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.travel_explore_rounded,
                  color: theme.colorScheme.onPrimaryContainer,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Background tracking',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Keeps recording when the app is minimized or closed.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              // `Switch.adaptive` renders as a Cupertino switch on
              // iOS and Material on Android with no extra work.
              Switch.adaptive(
                value: state.backgroundEnabled,
                onChanged: (v) {
                  context.read<SettingsCubit>().setBackgroundEnabled(v);
                  context
                      .read<LocationBloc>()
                      .add(LocationEvent.toggleBackground(v));
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
