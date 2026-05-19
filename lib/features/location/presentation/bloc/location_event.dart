import 'package:freezed_annotation/freezed_annotation.dart';

part 'location_event.freezed.dart';

/// Intent events the UI sends to [LocationBloc]. Sealed via `freezed` so
/// the bloc's `on<>` handlers can exhaustively match on the union.
@freezed
class LocationEvent with _$LocationEvent {
  /// Kick off a tracking session. `useBackground` controls whether the
  /// platform-specific background path (Android foreground service or
  /// iOS SLC) is armed in addition to the foreground stream.
  const factory LocationEvent.startTracking({@Default(false) bool useBackground}) =
      StartTracking;

  const factory LocationEvent.stopTracking() = StopTracking;

  /// User flipped the background switch. The bloc will request the
  /// "Always" permission upgrade if needed and reconfigure any in-flight
  /// session.
  const factory LocationEvent.toggleBackground(bool enabled) = ToggleBackground;

  /// User tapped the "Open system settings" recovery action shown on
  /// permanent-denial failures.
  const factory LocationEvent.openSettingsRequested() = OpenSettingsRequested;
}
