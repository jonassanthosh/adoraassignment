import 'package:flutter_test/flutter_test.dart';
import 'package:location_tracking/features/location/domain/usecases/start_tracking.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/mocks.dart';

void main() {
  late MockLocationRepository repo;
  late StartTracking usecase;

  setUp(() {
    repo = MockLocationRepository();
    usecase = StartTracking(repo);
    when(() => repo.startTracking(useBackground: any(named: 'useBackground')))
        .thenAnswer((_) async {});
  });

  test('forwards useBackground=false by default', () async {
    await usecase();
    verify(() => repo.startTracking(useBackground: false)).called(1);
  });

  test('forwards useBackground=true when requested', () async {
    await usecase(useBackground: true);
    verify(() => repo.startTracking(useBackground: true)).called(1);
  });
}
