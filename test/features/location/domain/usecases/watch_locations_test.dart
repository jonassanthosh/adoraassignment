import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:location_tracking/features/location/domain/entities/location_entities.dart';
import 'package:location_tracking/features/location/domain/usecases/watch_locations.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/mocks.dart';

void main() {
  late MockLocationRepository repo;
  late WatchLocations usecase;
  late StreamController<LocationEntity> controller;

  setUp(() {
    repo = MockLocationRepository();
    controller = StreamController<LocationEntity>.broadcast();
    when(() => repo.watchLocations()).thenAnswer((_) => controller.stream);
    usecase = WatchLocations(repo);
  });

  tearDown(() => controller.close());

  test('emits entities forwarded by the repository', () async {
    final entity = LocationEntity(
      latitude: 1,
      longitude: 2,
      accuracy: 3,
      timestamp: DateTime.fromMillisecondsSinceEpoch(0),
    );

    final received = <LocationEntity>[];
    final sub = usecase().listen(received.add);

    controller.add(entity);
    await Future<void>.delayed(Duration.zero);

    expect(received, [entity]);
    await sub.cancel();
  });
}
