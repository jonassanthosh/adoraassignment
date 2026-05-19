import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../data/datasources/settings_datasource.dart';

/// Holds user preferences that need to survive across launches. Right now
/// the only preference is "track in background"; the cubit pattern is
/// overkill for a single bool but it makes the contract explicit and
/// lets us add more preferences without restructuring.
@injectable
class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit(this._ds) : super(const SettingsState()) {
    // Fire-and-forget. We start in the default state and the value pops
    // in once SharedPreferences resolves; the toggle widget rebuilds.
    _load();
  }

  final SettingsDataSource _ds;

  Future<void> _load() async {
    final v = await _ds.isBackgroundEnabled();
    emit(SettingsState(backgroundEnabled: v));
  }

  /// Optimistic update: emit the new state first so the UI feels instant,
  /// then persist. If persistence fails the next launch will rehydrate
  /// from disk; we don't roll back.
  Future<void> setBackgroundEnabled(bool v) async {
    emit(state.copyWith(backgroundEnabled: v));
    await _ds.setBackgroundEnabled(v);
  }
}

/// Hand-rolled equatable state. Kept simple — when the cubit grows
/// another field we'll likely move this to freezed.
class SettingsState {
  const SettingsState({this.backgroundEnabled = false});
  final bool backgroundEnabled;

  SettingsState copyWith({bool? backgroundEnabled}) => SettingsState(
        backgroundEnabled: backgroundEnabled ?? this.backgroundEnabled,
      );

  @override
  bool operator ==(Object other) =>
      other is SettingsState && other.backgroundEnabled == backgroundEnabled;
  @override
  int get hashCode => backgroundEnabled.hashCode;
}
