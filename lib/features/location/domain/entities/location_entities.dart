import 'package:freezed_annotation/freezed_annotation.dart';

part 'location_entities.freezed.dart';

/// Platform-free representation of a single GPS fix. Whatever source
/// produced it (foreground stream, Android background service, iOS
/// significant-location-changes), it gets normalised to this type before
/// crossing into the domain layer.
///
/// [source] is a free-form string deliberately — it lets the UI badge
/// rows without the domain caring which producers exist. Known values:
/// `'foreground'`, `'background'`, `'slc'`.
@freezed
sealed class LocationEntity with _$LocationEntity {
  const factory LocationEntity({
    required double latitude,
    required double longitude,
    required double accuracy,
    required DateTime timestamp,
    String? source,
  }) = _LocationEntity;
}
