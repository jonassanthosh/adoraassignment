import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import 'injector.config.dart';

final getIt = GetIt.instance;

@InjectableInit(
  initializerName: 'init',                  // default name
  preferRelativeImports: true,
  asExtension: true,                        // exposes getIt.init()
)
Future<void> configureDependencies() async => getIt.init();