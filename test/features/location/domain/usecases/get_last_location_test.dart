import 'package:flutter_test/flutter_test.dart';
import 'package:location_tracking/features/location/domain/entities/location_entities.dart';
import 'package:location_tracking/features/location/domain/usecases/get_last_location.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/mocks.dart';

void main() {
  late MockLocationRepository repo;
  late GetLastLocation usecase;

  setUp(() {
    repo = MockLocationRepository();
    usecase = GetLastLocation(repo);
  });

  test('returns the entity provided by the repository', () async {
    final entity = LocationEntity(
      latitude: 10,
      longitude: 20,
      accuracy: 5,
      timestamp: DateTime.fromMillisecondsSinceEpoch(123),
    );
    when(() => repo.getLastKnown()).thenAnswer((_) async => entity);

    final result = await usecase();

    expect(result, entity);
  });

  test('returns null when no fix has been recorded', () async {
    when(() => repo.getLastKnown()).thenAnswer((_) async => null);

    expect(await usecase(), isNull);
  });
}
