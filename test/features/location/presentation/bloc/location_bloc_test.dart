import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:location_tracking/features/location/domain/entities/location_entities.dart';
import 'package:location_tracking/features/location/domain/entities/permission_status.dart';
import 'package:location_tracking/features/location/presentation/bloc/location_bloc.dart';
import 'package:location_tracking/features/location/presentation/bloc/location_event.dart';
import 'package:location_tracking/features/location/presentation/bloc/location_state.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/mocks.dart';

void main() {
  late MockPermissionDataSource permissions;
  late MockStartTracking startTracking;
  late MockStopTracking stopTracking;
  late MockWatchLocations watchLocations;
  late MockGetLastLocation getLastLocation;
  late MockBackgroundServiceController bg;
  late StreamController<LocationEntity> updates;

  final fix1 = LocationEntity(
    latitude: 12.97,
    longitude: 77.59,
    accuracy: 4,
    timestamp: DateTime.fromMillisecondsSinceEpoch(1000),
  );
  final fix2 = LocationEntity(
    latitude: 12.98,
    longitude: 77.60,
    accuracy: 4,
    timestamp: DateTime.fromMillisecondsSinceEpoch(2000),
  );

  /// Builds a fresh bloc with sensible default stubs. Override before
  /// `build:` in individual bloc_tests when you need different behavior.
  LocationBloc buildBloc() {
    return LocationBloc(
      permissions: permissions,
      startTracking: startTracking,
      stopTracking: stopTracking,
      watchLocations: watchLocations,
      getLastLocation: getLastLocation,
      bg: bg,
    );
  }

  setUp(() {
    permissions = MockPermissionDataSource();
    startTracking = MockStartTracking();
    stopTracking = MockStopTracking();
    watchLocations = MockWatchLocations();
    getLastLocation = MockGetLastLocation();
    bg = MockBackgroundServiceController();
    updates = StreamController<LocationEntity>.broadcast();

    // Defaults that keep _bootstrap quiet.
    when(() => getLastLocation()).thenAnswer((_) async => null);
    when(() => bg.isRunning()).thenAnswer((_) async => false);
    when(() => watchLocations()).thenAnswer((_) => updates.stream);
    when(() => startTracking(useBackground: any(named: 'useBackground')))
        .thenAnswer((_) async {});
    when(() => stopTracking()).thenAnswer((_) async {});
  });

  tearDown(() => updates.close());

  group('_bootstrap', () {
    blocTest<LocationBloc, LocationState>(
      'restores last known fix when not currently tracking',
      setUp: () {
        when(() => getLastLocation()).thenAnswer((_) async => fix1);
        when(() => bg.isRunning()).thenAnswer((_) async => false);
      },
      build: buildBloc,
      wait: const Duration(milliseconds: 20),
      expect: () => [isA<LocationTracking>()],
    );

    blocTest<LocationBloc, LocationState>(
      'stays idle when no last fix and not tracking',
      build: buildBloc,
      wait: const Duration(milliseconds: 20),
      expect: () => const <LocationState>[],
    );

    blocTest<LocationBloc, LocationState>(
      'subscribes to live updates when the bg service is already running',
      setUp: () {
        when(() => bg.isRunning()).thenAnswer((_) async => true);
      },
      build: buildBloc,
      act: (_) async {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        updates.add(fix2);
      },
      wait: const Duration(milliseconds: 20),
      expect: () => [isA<LocationTracking>()],
    );
  });

  group('startTracking event — permission flow', () {
    blocTest<LocationBloc, LocationState>(
      'emits loading then failure(openSettings) when services disabled',
      setUp: () {
        when(() => permissions.current())
            .thenAnswer((_) async => LocationAuth.serviceDisabled);
      },
      build: buildBloc,
      wait: const Duration(milliseconds: 10),
      act: (bloc) => bloc.add(const LocationEvent.startTracking()),
      expect: () => [
        const LocationState.loading(),
        isA<LocationFailure>().having((f) => f.openSettings, 'openSettings', true),
      ],
    );

    blocTest<LocationBloc, LocationState>(
      'emits failure(openSettings) when permission permanently denied',
      setUp: () {
        when(() => permissions.current())
            .thenAnswer((_) async => LocationAuth.deniedForever);
      },
      build: buildBloc,
      wait: const Duration(milliseconds: 10),
      act: (bloc) => bloc.add(const LocationEvent.startTracking()),
      expect: () => [
        const LocationState.loading(),
        isA<LocationFailure>().having((f) => f.openSettings, 'openSettings', true),
      ],
    );

    blocTest<LocationBloc, LocationState>(
      'requests whileInUse when denied and succeeds when granted',
      setUp: () {
        when(() => permissions.current())
            .thenAnswer((_) async => LocationAuth.denied);
        when(() => permissions.requestWhileInUse())
            .thenAnswer((_) async => LocationAuth.whileInUse);
      },
      build: buildBloc,
      wait: const Duration(milliseconds: 20),
      act: (bloc) async {
        bloc.add(const LocationEvent.startTracking());
        await Future<void>.delayed(const Duration(milliseconds: 10));
        updates.add(fix1);
      },
      expect: () => [
        const LocationState.loading(),
        isA<LocationTracking>(),
      ],
      verify: (_) {
        verify(() => permissions.requestWhileInUse()).called(1);
        verify(() => startTracking(useBackground: false)).called(1);
      },
    );

    blocTest<LocationBloc, LocationState>(
      'forwards useBackground=true to the use case',
      setUp: () {
        when(() => permissions.current())
            .thenAnswer((_) async => LocationAuth.always);
      },
      build: buildBloc,
      wait: const Duration(milliseconds: 20),
      act: (bloc) async {
        bloc.add(const LocationEvent.startTracking(useBackground: true));
        await Future<void>.delayed(const Duration(milliseconds: 10));
        updates.add(fix1);
      },
      verify: (_) {
        verify(() => startTracking(useBackground: true)).called(1);
      },
    );
  });

  group('stopTracking event', () {
    blocTest<LocationBloc, LocationState>(
      'calls the use case and emits idle',
      setUp: () {
        when(() => permissions.current())
            .thenAnswer((_) async => LocationAuth.whileInUse);
      },
      build: buildBloc,
      wait: const Duration(milliseconds: 20),
      act: (bloc) async {
        bloc.add(const LocationEvent.startTracking());
        await Future<void>.delayed(const Duration(milliseconds: 10));
        bloc.add(const LocationEvent.stopTracking());
      },
      verify: (_) {
        verify(() => stopTracking()).called(1);
      },
      expect: () => [
        const LocationState.loading(),
        const LocationState.idle(),
      ],
    );
  });

  group('toggleBackground event', () {
    blocTest<LocationBloc, LocationState>(
      'emits failure(openSettings) if Always cannot be granted',
      setUp: () {
        when(() => permissions.current())
            .thenAnswer((_) async => LocationAuth.whileInUse);
        when(() => permissions.requestAlways())
            .thenAnswer((_) async => LocationAuth.whileInUse);
      },
      build: buildBloc,
      wait: const Duration(milliseconds: 20),
      act: (bloc) => bloc.add(const LocationEvent.toggleBackground(true)),
      expect: () => [
        isA<LocationFailure>()
            .having((f) => f.openSettings, 'openSettings', true)
            .having((f) => f.message, 'message',
                contains('Always')),
      ],
    );

    blocTest<LocationBloc, LocationState>(
      'no-ops when toggling off and not tracking',
      build: buildBloc,
      wait: const Duration(milliseconds: 20),
      act: (bloc) => bloc.add(const LocationEvent.toggleBackground(false)),
      expect: () => const <LocationState>[],
    );
  });
}
