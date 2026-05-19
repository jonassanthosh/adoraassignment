import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/location_bloc.dart';
import '../bloc/location_state.dart';
import '../widgets/action_buttons.dart';
import '../widgets/location_card.dart';
import '../widgets/tracking_toggle.dart';
import 'history_page.dart';

/// The only screen the user starts on. Composed of three reusable
/// widgets — [LocationCard], [TrackingToggle], [ActionButtons] — so each
/// section can be reasoned about (and reused) on its own.
///
/// The page itself is intentionally dumb: it doesn't dispatch events or
/// read settings; it just renders whatever [LocationBloc] currently
/// holds. All interaction lives inside the child widgets.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trail'),
        actions: [
          IconButton(
            tooltip: 'History',
            icon: const Icon(Icons.history_rounded),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const HistoryPage()),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        // Rebuilds whenever the BLoC emits — every child below the
        // builder sees the same `state` snapshot, so the page is always
        // internally consistent (the toggle, the card, and the buttons
        // never disagree about what's going on).
        child: BlocBuilder<LocationBloc, LocationState>(
          builder: (context, state) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 16, left: 4),
                  child: Text(
                    'Your live location',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                LocationCard(state: state),
                const SizedBox(height: 16),
                const TrackingToggle(),
                const SizedBox(height: 24),
                ActionButtons(state: state),
              ],
            );
          },
        ),
      ),
    );
  }
}
