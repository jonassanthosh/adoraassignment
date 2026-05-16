import 'package:injectable/injectable.dart';
import '../entities/location_entities.dart';
import '../repositories/location_repository.dart';


@injectable
class WatchLocations {
  WatchLocations(this._repo);
  final LocationRepository _repo;
  Stream<LocationEntity> call() => _repo.watchLocations();
}