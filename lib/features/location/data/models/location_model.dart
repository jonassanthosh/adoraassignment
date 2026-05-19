import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:geolocator/geolocator.dart';

import '../../domain/entities/location_entities.dart';

part 'location_model.freezed.dart';
part 'location_model.g.dart';

/// Data-layer DTO. Mirrors the on-disk SQLite columns and the platform-
/// channel JSON payload, then maps to the platform-free [LocationEntity]
/// via [toEntity] so the domain never sees `Position` or
/// `Map<String, dynamic>` directly.
///
/// Kept separate from [LocationEntity] on purpose — when the storage
/// schema or the channel format changes, only this file needs touching.
@freezed
sealed class LocationModel with _$LocationModel {
  const LocationModel._();

  const factory LocationModel({
    required double lat,
    required double lon,
    required double accuracy,
    required int tsMillis,
    String? source,
  }) = _LocationModel;

  /// JSON path. Used when the BG isolate forwards a fix to the UI isolate.
  factory LocationModel.fromJson(Map<String, dynamic> json) =>
      _$LocationModelFromJson(json);

  /// Adapter for the live foreground stream.
  factory LocationModel.fromPosition(Position p, {String? source}) =>
      LocationModel(
        lat: p.latitude,
        lon: p.longitude,
        accuracy: p.accuracy,
        tsMillis: (p.timestamp).millisecondsSinceEpoch,
        source: source,
      );

  /// SQLite row adapter. `accuracy` is read through `num.toDouble()` because
  /// SQLite happily promotes/demotes between `INTEGER` and `REAL`, and we'd
  /// rather coerce than crash on a legacy row.
  factory LocationModel.fromRow(Map<String, Object?> row) => LocationModel(
        lat: row['lat']! as double,
        lon: row['lon']! as double,
        accuracy: (row['accuracy']! as num).toDouble(),
        tsMillis: row['ts']! as int,
        source: row['source'] as String?,
      );

  LocationEntity toEntity() => LocationEntity(
        latitude: lat,
        longitude: lon,
        accuracy: accuracy,
        timestamp: DateTime.fromMillisecondsSinceEpoch(tsMillis),
        source: source,
      );
}
