import 'package:injectable/injectable.dart';

import '../repositories/location_repository.dart';

/// Use case: begin a tracking session. Thin pass-through to the
/// repository, but kept as a class so the BLoC depends on a small
/// single-purpose surface rather than the whole repository.
@injectable
class StartTracking {
  StartTracking(this._repo);
  final LocationRepository _repo;
  Future<void> call({bool useBackground = false}) =>
      _repo.startTracking(useBackground: useBackground);
}
