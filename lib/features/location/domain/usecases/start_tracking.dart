import 'package:injectable/injectable.dart';

import '../repositories/location_repository.dart';

@injectable
class StartTracking {
  StartTracking(this._repo);
  final LocationRepository _repo;
  Future<void> call({bool useBackground = false}) =>
      _repo.startTracking(useBackground: useBackground);
}