import 'package:flutter_test/flutter_test.dart';
import 'package:location_tracking/features/location/data/models/location_model.dart';

void main() {
  group('LocationModel', () {
    test('round-trips through JSON', () {
      const original = LocationModel(
        lat: 12.9716,
        lon: 77.5946,
        accuracy: 5.5,
        tsMillis: 1716120000000,
        source: 'foreground',
      );

      final encoded = original.toJson();
      final decoded = LocationModel.fromJson(encoded);

      expect(decoded, equals(original));
    });

    test('fromRow parses a sqflite row', () {
      final row = <String, Object?>{
        'lat': 12.9716,
        'lon': 77.5946,
        'accuracy': 8,
        'ts': 1716120000000,
        'source': 'slc',
      };

      final model = LocationModel.fromRow(row);

      expect(model.lat, 12.9716);
      expect(model.lon, 77.5946);
      expect(model.accuracy, 8.0);
      expect(model.tsMillis, 1716120000000);
      expect(model.source, 'slc');
    });

    test('fromRow tolerates int accuracy by coercing to double', () {
      final row = <String, Object?>{
        'lat': 1.0,
        'lon': 2.0,
        'accuracy': 12,
        'ts': 1716120000000,
        'source': 'background',
      };

      final model = LocationModel.fromRow(row);

      expect(model.accuracy, isA<double>());
      expect(model.accuracy, 12.0);
    });

    test('toEntity preserves all values and converts timestamp', () {
      const tsMillis = 1716120000000;
      const model = LocationModel(
        lat: 1.1,
        lon: 2.2,
        accuracy: 3.3,
        tsMillis: tsMillis,
        source: 'background',
      );

      final entity = model.toEntity();

      expect(entity.latitude, 1.1);
      expect(entity.longitude, 2.2);
      expect(entity.accuracy, 3.3);
      expect(entity.timestamp.millisecondsSinceEpoch, tsMillis);
      expect(entity.source, 'background');
    });
  });
}
