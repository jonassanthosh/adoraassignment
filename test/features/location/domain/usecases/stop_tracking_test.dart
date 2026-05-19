import 'package:flutter_test/flutter_test.dart';
import 'package:location_tracking/features/location/domain/usecases/stop_tracking.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/mocks.dart';

void main() {
  late MockLocationRepository repo;
  late StopTracking usecase;

  setUp(() {
    repo = MockLocationRepository();
    usecase = StopTracking(repo);
    when(() => repo.stopTracking()).thenAnswer((_) async {});
  });

  test('delegates to repository.stopTracking', () async {
    await usecase();
    verify(() => repo.stopTracking()).called(1);
  });
}
