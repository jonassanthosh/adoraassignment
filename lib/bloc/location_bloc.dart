// BLoC that mediates between the UI ([HomePage]) and the [LocationService].
//
// The bloc is intentionally thin: it converts each incoming [LocationEvent]
// into the appropriate [LocationState] transitions and delegates the actual
// work (talking to the OS, opening settings) to collaborators. Keeping it
// thin makes it easy to test by injecting a fake [LocationService].

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';

import '../location_service.dart';
import 'location_event.dart';
import 'location_state.dart';

/// BLoC responsible for orchestrating location-fetching for the home screen.
///
/// State machine:
///   Idle -> Loading -> Success(position)
///                  \-> Failure(message, openSettings?)
///
/// The bloc starts in [Idle] so the first build of the UI can show the
/// "Tap below to fetch your location" prompt.
class LocationBloc extends Bloc<LocationEvent, LocationState>{
  LocationBloc(this._service) : super(const Idle()) {
    // Register one handler per event subtype. `on<T>` ensures handlers are
    // invoked sequentially per-type, avoiding race conditions when multiple
    // [FetchOnce] events arrive in quick succession.
    on<FetchOnce>(_onFetchOnce);
    on<OpenSettingsRequested>(_onOpenSettingsRequested);
  }

  /// Collaborator that does the actual GPS work. Injected via the constructor
  /// so tests can supply a fake/mock and exercise the bloc in isolation.
  final LocationService _service;

  /// Handles a single "fetch the current location" request from the UI.
  ///
  /// Emits [Loading] immediately so the UI can show a spinner, then either
  /// [Success] with the resolved [Position] or [Failure] with a user-facing
  /// message extracted from the [LocationFetchException].
  Future<void> _onFetchOnce(FetchOnce event, Emitter<LocationState> emit) async {
    emit(const Loading());
    try{
      final position = await _service.getCurrentPosition();
      emit(Success(position));
    } on LocationFetchException catch (e){
      // Forward both the message and the `openSettings` hint so the UI can
      // decide whether to render the "Open Settings" recovery button.
      emit(Failure(e.message, openSettings: e.openSettings));
    }
  }

  /// Opens the OS app settings page so the user can grant a permission that
  /// was permanently denied. This is a fire-and-forget side effect — there
  /// is nothing meaningful to emit afterwards, since whether the user
  /// actually changes the setting is observed lazily on the next [FetchOnce].
  Future<void> _onOpenSettingsRequested(OpenSettingsRequested event, Emitter<LocationState> emit) async {
    await openAppSettings();
  }
}
