import 'package:freezed_annotation/freezed_annotation.dart';

part 'location_entities.freezed.dart'; 

@freezed
sealed class LocationEntity with _$LocationEntity {
  const factory LocationEntity({
    required double latitude,
    required double longitude,
    required double accuracy,
    required DateTime timestamp,
    String? source,                      // 'foreground' | 'background' | 'slc'
  }) = _LocationEntity;
}