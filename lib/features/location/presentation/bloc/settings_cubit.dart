import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../data/datasources/settings_datasource.dart';

@injectable
class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit(this._ds) : super(const SettingsState()) {
    _load();
  }

  final SettingsDataSource _ds;

  Future<void> _load() async {
    final v = await _ds.isBackgroundEnabled();
    emit(SettingsState(backgroundEnabled: v));
  }

  Future<void> setBackgroundEnabled(bool v) async {
    emit(state.copyWith(backgroundEnabled: v));
    await _ds.setBackgroundEnabled(v);
  }
}

class SettingsState {
  const SettingsState({this.backgroundEnabled = false});
  final bool backgroundEnabled;

  SettingsState copyWith({bool? backgroundEnabled}) =>
      SettingsState(backgroundEnabled: backgroundEnabled ?? this.backgroundEnabled);

  @override
  bool operator ==(Object other) =>
      other is SettingsState && other.backgroundEnabled == backgroundEnabled;
  @override
  int get hashCode => backgroundEnabled.hashCode;
}