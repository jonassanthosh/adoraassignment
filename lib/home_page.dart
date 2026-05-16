// UI for the single-screen Location Tracking app.
//
// The screen observes [LocationBloc] via a [BlocConsumer]:
//   * The `builder` rebuilds the visible card and action button whenever the
//     state changes (Idle / Loading / Success / Failure).
//   * The `listener` handles one-off side effects such as showing a SnackBar
//     when a [Failure] state is emitted — these effects should not be in the
//     `builder`, because the builder may run multiple times for the same state.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:location_tracking/bloc/location_bloc.dart';
import 'package:location_tracking/bloc/location_event.dart';
import 'package:location_tracking/bloc/location_state.dart';


/// The single screen of the app. Stateless because all mutable state lives in
/// the [LocationBloc] above it in the widget tree.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Location Tracking')),
      // [BlocConsumer] combines [BlocBuilder] and [BlocListener]: it both
      // rebuilds on state changes and lets us react with side effects.
      body: BlocConsumer<LocationBloc, LocationState>(
        listener: _listenForSideEffects,
        builder: (context, state) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // The card visualises whatever the bloc is currently reporting.
              _LocationCard(state: state),
              const SizedBox(height: 16),
              // The action button(s) below the card depend on the state too
              // (e.g. disabled while loading, extra "Open Settings" on errors).
              _ActionButton(state: state),
            ],
          ),
        ),
        ) ,
      );
  }

  /// Reacts to state changes that should *not* be expressed by rebuilding the
  /// UI — currently only showing a SnackBar when the request fails. Hiding any
  /// previous SnackBar first prevents them from queueing up if errors repeat.
  void _listenForSideEffects(BuildContext context, LocationState state) {
    if (state is Failure) {
      ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(state.message)));
    }
  }
}


/// Card that renders the *content area* of the screen and switches between
/// representations based on the current [LocationState]. The Dart 3 pattern
/// `switch` exhaustively maps each sealed subclass to its own widget, which
/// makes it a compile-time error to forget a new case in the future.
class _LocationCard extends StatelessWidget {
  const _LocationCard({required this.state});
  final LocationState state;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: SizedBox(
        // Stretch horizontally so the card always fills the available width
        // regardless of how short the message inside is.
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: switch (state) {
            Idle()    => const _CardText('Tap below to fetch your location.'),
            Loading() => const _CardText('Locating...'),
            Success(:final position) => _SuccessBody(position),
            Failure(:final message)  => _CardText(message, isError: true),
          },
        ),
      ),
    );
  }
}

/// Simple text label used inside the card for Idle/Loading/Failure states.
/// When [isError] is true, the text is rendered using the theme's error color
/// so failures stand out without needing a separate widget per state.
class _CardText extends StatelessWidget {
  const _CardText(this.text, {this.isError = false});
  final String text;
  final bool isError;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      style: theme.textTheme.titleMedium?.copyWith(
        color: isError ? theme.colorScheme.error : null,
      ),
    );
  }
}

/// Detailed body shown inside the card when a location has been successfully
/// fetched. Displays latitude/longitude (rounded for readability), the radial
/// accuracy estimate in metres and the local timestamp of the reading.
class _SuccessBody extends StatelessWidget {
  const _SuccessBody(this.position);
  final Position position;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Six decimal places is roughly 11 cm of precision — more than enough
        // for any consumer-facing display and avoids overwhelming the user
        // with the raw double representation.
        Text(
          'Latitude  ${position.latitude.toStringAsFixed(6)}',
          style: theme.textTheme.bodyLarge,
        ),
        Text(
          'Longitude ${position.longitude.toStringAsFixed(6)}',
          style: theme.textTheme.bodyLarge,
        ),
        const SizedBox(height: 8),
        // \u00b1 is the Unicode "plus-minus" sign used to indicate accuracy.
        Text(
          'Accuracy: \u00b1${position.accuracy.toStringAsFixed(0)} m',
          style: theme.textTheme.bodyMedium,
        ),
        // Convert from UTC (Geolocator default) to the device's local time
        // zone so the timestamp is meaningful to the user.
        Text(
          'At ${position.timestamp.toLocal()}',
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}

/// Bottom action area of the screen.
///
/// Always shows a primary "Get my location" button which dispatches a
/// [FetchOnce] event. When the bloc is in a [Failure] state caused by a
/// permanently denied permission ([Failure.openSettings] true), an additional
/// "Open Settings" button is shown to guide the user to the system settings.
class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.state});
  final LocationState state;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<LocationBloc>();
    final isLoading = state is Loading;
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            // Disable taps while a request is already in flight to prevent
            // duplicate dispatches from rapid presses.
            onPressed: isLoading ? null : () => bloc.add(const FetchOnce()),
            icon: isLoading
                // Show a small inline spinner inside the button instead of
                // replacing the whole button with a separate loader, so the
                // layout doesn't jump while loading.
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.my_location),
            label: const Text('Get my location'),
          ),
        ),
        // Only surface the "Open Settings" affordance when the failure was
        // caused by a permission that the user can no longer grant in-app
        // (i.e. permanently denied). The cast is safe because of the `is`
        // check on the previous line.
        if (state is Failure && (state as Failure).openSettings) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => bloc.add(const OpenSettingsRequested()),
              icon: const Icon(Icons.settings),
              label: const Text('Open Settings'),
            ),
          ),
        ],
      ],
    );
  }
}
