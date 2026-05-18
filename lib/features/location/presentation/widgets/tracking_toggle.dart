import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/location_bloc.dart';
import '../bloc/location_event.dart';
import '../bloc/settings_cubit.dart';

class TrackingToggle extends StatelessWidget {
  const TrackingToggle({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) {
        return SwitchListTile(
          title: const Text('Track in background'),
          subtitle: const Text(
            'Continues recording when the app is minimized or closed.',
          ),
          value: state.backgroundEnabled,
          onChanged: (v) {
            context.read<SettingsCubit>().setBackgroundEnabled(v);
            context.read<LocationBloc>().add(LocationEvent.toggleBackground(v));
          },
        );
      },
    );
  }
}