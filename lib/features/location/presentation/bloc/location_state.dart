import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/location_entities.dart';

part 'location_state.freezed.dart';

@freezed
sealed class LocationState with _$LocationState {
  const factory LocationState.idle() = LocationIdle;
  const factory LocationState.loading() = LocationLoading;
  const factory LocationState.tracking(LocationEntity last) = LocationTracking;
  const factory LocationState.failure(String message, {@Default(false) bool openSettings}) = LocationFailure;
}

String render(LocationState state) => switch (state) {
  LocationIdle() => 'Tap below to fetch your location.',
  LocationLoading() => 'Locating...',
  LocationTracking(:final last) => 'Last location: ${last.latitude}, ${last.longitude}',
  LocationFailure(:final message) => message,
};

