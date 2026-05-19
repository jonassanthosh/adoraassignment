import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/di/injector.dart';
import 'core/theme/app_theme.dart';
import 'features/location/presentation/bloc/location_bloc.dart';
import 'features/location/presentation/bloc/settings_cubit.dart';
import 'features/location/presentation/pages/home_page.dart';

class LocationTrackingApp extends StatelessWidget {
  const LocationTrackingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Trail',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      home: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => getIt<LocationBloc>()),
          BlocProvider(create: (_) => getIt<SettingsCubit>()),
        ],
        child: const HomePage(),
      ),
    );
  }
}
