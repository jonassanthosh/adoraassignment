import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/location_bloc.dart';
import '../bloc/location_state.dart';
import '../widgets/location_card.dart';
import '../widgets/tracking_toggle.dart';
import '../widgets/action_buttons.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Location')),
      body: BlocBuilder<LocationBloc, LocationState>(
        builder: (context, state) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                LocationCard(state: state),
                const SizedBox(height: 16),
                const TrackingToggle(),
                const SizedBox(height: 16),
                ActionButtons(state: state),
              ],
            ),
          );
        },
      ),
    );
  }
}