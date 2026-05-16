// States emitted by the [LocationBloc].
//
// The states form a small finite state machine consumed by the UI layer:
//
//        +------+   FetchOnce   +---------+   success   +---------+
//        | Idle | ------------> | Loading | ----------> | Success |
//        +------+               +---------+             +---------+
//                                    |
//                                    | failure
//                                    v
//                               +---------+
//                               | Failure |
//                               +---------+
//
// `sealed` enforces exhaustive pattern matching at the call sites (see the
// `switch (state)` expression in `home_page.dart`).

import 'package:equatable/equatable.dart';
import 'package:geolocator/geolocator.dart';


/// Base type for every state the [LocationBloc] can be in.
///
/// Extending [Equatable] means two states with identical payloads compare
/// equal, so the BLoC framework will not trigger redundant rebuilds when the
/// "same" state is emitted twice in a row.
sealed class LocationState extends Equatable {
  const LocationState();
  @override
  List<Object?> get props => const [];
}

/// Initial state before the user has requested a location. The UI shows a
/// neutral prompt encouraging the user to tap the action button.
class Idle extends LocationState {
  const Idle();
}

/// A location request is in flight. The UI uses this to disable the button
/// and show an inline progress indicator.
class Loading extends LocationState {
  const Loading();
}

/// Terminal success state carrying the resolved [Position]. The UI extracts
/// latitude/longitude/accuracy/timestamp from this object for display.
class Success extends LocationState {
  const Success(this.position);
  final Position position;
  @override
  // Equality is based on a stable subset of the [Position] data rather than
  // the whole object: longitude, latitude and a millisecond-resolution
  // timestamp uniquely identify a reading, while comparing the full
  // [Position] (which includes mutable fields like speed/heading) would
  // produce spurious inequalities.
  List<Object?> get props => [
    position.longitude,
    position.latitude,
    position.timestamp.millisecondsSinceEpoch
  ];
}

/// Terminal failure state carrying a user-facing [message] and an
/// [openSettings] hint. The UI shows the message in the card (and via a
/// SnackBar) and, when [openSettings] is true, surfaces a secondary button
/// that lets the user jump directly to the OS settings page.
class Failure extends LocationState {
  const Failure(this.message, { this.openSettings = false });
  final String message;
  final bool openSettings;
  @override
  List<Object?> get props => [message, openSettings];
}
