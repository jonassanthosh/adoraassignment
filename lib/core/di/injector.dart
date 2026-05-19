import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import 'injector.config.dart';

/// Global service locator. Anything annotated with `@injectable`,
/// `@lazySingleton`, or `@factoryMethod` in this package is registered
/// against this instance during [configureDependencies].
final getIt = GetIt.instance;

/// Wires the whole graph in one call. The body is empty because the work
/// is done by the generated `init()` extension; the annotation below
/// drives the build_runner.
///
/// `preferRelativeImports` keeps the generated file diff-friendly when
/// folders are renamed; `asExtension` exposes the registration helper as
/// `getIt.init()` rather than a free function.
@InjectableInit(
  initializerName: 'init',
  preferRelativeImports: true,
  asExtension: true,
)
Future<void> configureDependencies() async => getIt.init();
