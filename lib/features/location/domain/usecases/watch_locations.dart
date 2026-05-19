import 'package:injectable/injectable.dart';
import '../entities/location_entities.dart';
import '../repositories/location_repository.dart';

/// Use case: subscribe to the unified location stream. The repository
/// fans in foreground / background / SLC fixes behind a single broadcast
/// stream, so the BLoC only needs one subscription.
@injectable
class WatchLocations {
  WatchLocations(this._repo);
  final LocationRepository _repo;
  Stream<LocationEntity> call() => _repo.watchLocations();
}
