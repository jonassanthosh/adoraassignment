// Events accepted by the [LocationBloc].
//
// Events represent *user intent* (or, more broadly, things that happen to the
// bloc from the outside). Keeping them as a sealed class hierarchy lets the
// bloc and the test suite reason about the full set of inputs exhaustively,
// and guarantees a compile-time error if a new event is added without being
// handled somewhere.

import 'package:equatable/equatable.dart';

/// Base type for all events handled by [LocationBloc].
///
/// Marked `sealed` so only the subclasses defined in this file may extend it.
/// Extends [Equatable] so two instances of the same event compare equal,
/// which is useful in tests and for bloc internals that deduplicate events.
sealed class LocationEvent extends Equatable {
  const LocationEvent();

  @override
  List<Object?> get props => const [];
}

/// "Fetch my current location once" — dispatched when the user taps the
/// primary action button. The bloc responds by moving through
/// Loading -> Success/Failure exactly once per event.
class FetchOnce extends LocationEvent {
  const FetchOnce();
}

/// "Take me to the app's settings screen" — dispatched when the user taps
/// the recovery button shown after a permanently-denied permission failure.
/// The bloc forwards this to the OS via `openAppSettings()`.
class OpenSettingsRequested extends LocationEvent {
  const OpenSettingsRequested();
}
