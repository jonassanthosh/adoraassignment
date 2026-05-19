import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/location_entities.dart';

part 'location_state.freezed.dart';

/// Sealed union of every state the home screen can be in. The widget tree
/// exhaustively `switch`es on this type so a new variant added here will
/// cause a compile error in the UI until it's handled — the safety net
/// freezed gives us in exchange for the codegen tax.
@freezed
sealed class LocationState with _$LocationState {
  /// Nothing tracking yet, no errors to show.
  const factory LocationState.idle() = LocationIdle;

  /// A start has been requested; waiting on the permission flow or the
  /// first GPS fix.
  const factory LocationState.loading() = LocationLoading;

  /// We have at least one fix and tracking is live.
  const factory LocationState.tracking(LocationEntity last) = LocationTracking;

  /// Tracking can't proceed. [openSettings] is set when the only recovery
  /// path is the system settings page (services off, permanent denial).
  const factory LocationState.failure(
    String message, {
    @Default(false) bool openSettings,
  }) = LocationFailure;
}

/// Plain-text rendering of the current state. Handy for tests and
/// logging — the production UI uses richer per-state widgets.
String render(LocationState state) => switch (state) {
      LocationIdle() => 'Tap below to fetch your location.',
      LocationLoading() => 'Locating...',
      LocationTracking(:final last) =>
        'Last location: ${last.latitude}, ${last.longitude}',
      LocationFailure(:final message) => message,
    };
