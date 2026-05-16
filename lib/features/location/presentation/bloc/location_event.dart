import 'package:freezed_annotation/freezed_annotation.dart';

part 'location_event.freezed.dart';

@freezed
class LocationEvent with _$LocationEvent {
  const factory LocationEvent.startTracking() = StartTracking;
  const factory LocationEvent.stopTracking() = StopTracking;
  const factory LocationEvent.toggleBackground(bool enabled) = ToggleBackground;
  const factory LocationEvent.openSettingsRequested() = OpenSettingsRequested;
}

