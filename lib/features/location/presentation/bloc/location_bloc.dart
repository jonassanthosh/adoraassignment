import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../data/datasources/permission_datasource.dart' as uc;
import '../../domain/entities/location_entities.dart';
import '../../domain/entities/permission_status.dart';
import '../../domain/usecases/get_last_location.dart' as uc;
import '../../domain/usecases/start_tracking.dart' as uc;
import '../../domain/usecases/stop_tracking.dart' as uc;
import '../../domain/usecases/watch_locations.dart' as uc;
import 'location_event.dart';
import 'location_state.dart';

@injectable
class LocationBloc extends Bloc<LocationEvent, LocationState> {
  LocationBloc({
    required this.permissions,
    required this.startTracking,
    required this.stopTracking,
    required this.watchLocations,
    required this.getLastLocation,
  }) : super(const LocationState.idle()) {
    on<StartTracking>(_onStart);
    on<StopTracking>(_onStop);
    on<ToggleBackground>(_onToggleBackground);
    on<OpenSettingsRequested>((_, __) => openAppSettings());
    _bootstrap();
  }

  final uc.PermissionDataSource permissions;
  final uc.StartTracking startTracking;
  final uc.StopTracking stopTracking;
  final uc.WatchLocations watchLocations;
  final uc.GetLastLocation getLastLocation;

  StreamSubscription<LocationEntity>? _sub;

  Future<void> _bootstrap() async {
    final last = await getLastLocation();
    if (last != null && state is LocationIdle) {
      emit(LocationState.tracking(last));
    }
  }

  Future<void> _onStart(StartTracking _, Emitter<LocationState> emit) async {
    emit(const LocationState.loading());
    final auth = await permissions.current();
    switch (auth) {
      case LocationAuth.serviceDisabled:
        emit(const LocationState.failure('Location services are off. Enable in Settings.', openSettings: true));
        return;
      case LocationAuth.deniedForever:
        emit(const LocationState.failure('Permission permanently denied. Open Settings.', openSettings: true));
        return;
      case LocationAuth.denied:
      case LocationAuth.notDetermined:
        final next = await permissions.requestWhileInUse();
        if (next != LocationAuth.whileInUse && next != LocationAuth.always) {
          emit(LocationState.failure(
            next == LocationAuth.deniedForever
                ? 'Permission permanently denied. Open Settings.'
                : 'Permission denied.',
            openSettings: next == LocationAuth.deniedForever,
          ));
          return;
        }
      case LocationAuth.whileInUse:
      case LocationAuth.always:
        break;
    }
    try {
      await startTracking();
      await emit.forEach<LocationEntity>(
        watchLocations(),
        onData: (loc) => LocationState.tracking(loc),
        onError: (e, _) => LocationState.failure('$e'),
      );
    } on Object catch (e) {
      emit(LocationState.failure('Could not start tracking: $e'));
    }
  }

  Future<void> _onStop(StopTracking _, Emitter<LocationState> emit) async {
    await _sub?.cancel();
    _sub = null;
    await stopTracking();
    emit(const LocationState.idle());
  }

  Future<void> _onToggleBackground(
  ToggleBackground event,
  Emitter<LocationState> emit,
) async {
  if (!event.enabled) {
    // turn off; nothing to ask
    return;
  }
  final cur = await permissions.current();
  if (cur != LocationAuth.always) {
    final upgraded = await permissions.requestAlways();
    if (upgraded != LocationAuth.always) {
      emit(LocationState.failure(
        'Background tracking needs "Always" permission. Adjust in Settings.',
        openSettings: true,
      ));
    }
  }
}

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }
}