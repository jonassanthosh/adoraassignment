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
import '../../../../services/background/background_service_controller.dart';
import 'location_event.dart';
import 'location_state.dart';

/// The brain of the home screen. Owns the permission decision tree, the
/// live subscription to the repository's unified location stream, and
/// the cold-start "show last known fix" behaviour.
///
/// The bloc is intentionally the only place that knows about the
/// [LocationAuth] enum — widgets only see `LocationState.failure(...)`
/// with a human-readable message and an `openSettings` hint.
@injectable
class LocationBloc extends Bloc<LocationEvent, LocationState> {
  LocationBloc({
    required this.permissions,
    required this.startTracking,
    required this.stopTracking,
    required this.watchLocations,
    required this.getLastLocation,
    required this._bg,
  }) : super(const LocationState.idle()) {
    on<StartTracking>(_onStart);
    on<StopTracking>(_onStop);
    on<ToggleBackground>(_onToggleBackground);
    on<OpenSettingsRequested>((_, _) => openAppSettings());

    _bootstrap();
  }

  final uc.PermissionDataSource permissions;
  final uc.StartTracking startTracking;
  final uc.StopTracking stopTracking;
  final uc.WatchLocations watchLocations;
  final uc.GetLastLocation getLastLocation;
  final BackgroundServiceController _bg;

  StreamSubscription<LocationEntity>? _sub;

  /// Runs once on construction. Two scenarios to cover:
  ///   1. The background service is already alive (the user backgrounded
  ///      the app while tracking, then came back). Resume the live
  ///      subscription so the UI catches up.
  ///   2. The service isn't running but we have a persisted last fix.
  ///      Show it immediately so the screen isn't empty while the user
  ///      decides whether to start a new session.
  Future<void> _bootstrap() async {
    final last = await getLastLocation();
    if (await _bg.isRunning()) {
      _sub = watchLocations().listen(
        (loc) => emit(LocationState.tracking(loc)),
        onError: (e) => emit(LocationState.failure('$e')),
      );
    } else if (last != null) {
      emit(LocationState.tracking(last));
    }
  }

  /// Handles the StartTracking event. The permission decision tree is
  /// expressed as an explicit switch so adding a new [LocationAuth]
  /// variant produces a compiler error here.
  Future<void> _onStart(StartTracking event, Emitter<LocationState> emit) async {
    emit(const LocationState.loading());
    final auth = await permissions.current();
    switch (auth) {
      case LocationAuth.serviceDisabled:
        emit(const LocationState.failure(
          'Location services are off. Enable in Settings.',
          openSettings: true,
        ));
        return;
      case LocationAuth.deniedForever:
        emit(const LocationState.failure(
          'Permission permanently denied. Open Settings.',
          openSettings: true,
        ));
        return;
      case LocationAuth.denied:
      case LocationAuth.notDetermined:
        // First time we've asked — show the system prompt. Anything other
        // than a grant is a terminal failure for this attempt.
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
      await startTracking(useBackground: event.useBackground);
      // `emit.forEach` keeps the handler "open" so subsequent fixes from
      // the repository stream update state without manual subscription
      // management.
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

  /// Background toggle handler. Turning the toggle on requires the
  /// "Always" permission upgrade; if we can't get it we surface a
  /// failure with the Open-Settings affordance. If the user toggles
  /// while a session is already active we restart it with the new
  /// preference by re-dispatching StartTracking, which keeps the
  /// reconfigure logic in one place.
  Future<void> _onToggleBackground(
    ToggleBackground event,
    Emitter<LocationState> emit,
  ) async {
    if (event.enabled) {
      final cur = await permissions.current();
      if (cur != LocationAuth.always) {
        final upgraded = await permissions.requestAlways();
        if (upgraded != LocationAuth.always) {
          emit(LocationState.failure(
            'Background tracking needs "Always" permission. Adjust in Settings.',
            openSettings: true,
          ));
          return;
        }
      }
    }
    if (state is LocationTracking || state is LocationLoading) {
      add(LocationEvent.startTracking(useBackground: event.enabled));
    }
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }
}
