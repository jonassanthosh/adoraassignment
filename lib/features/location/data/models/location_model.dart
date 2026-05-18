import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:geolocator/geolocator.dart';

import '../../domain/entities/location_entities.dart';

part 'location_model.freezed.dart';
part 'location_model.g.dart';

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

  factory LocationModel.fromJson(Map<String, dynamic> json) =>
      _$LocationModelFromJson(json);

  factory LocationModel.fromPosition(Position p, {String? source}) =>
      LocationModel(
        lat: p.latitude,
        lon: p.longitude,
        accuracy: p.accuracy,
        tsMillis: (p.timestamp).millisecondsSinceEpoch,
        source: source,
      );

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
