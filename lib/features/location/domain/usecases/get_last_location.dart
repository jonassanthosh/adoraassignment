import 'package:injectable/injectable.dart';
import '../entities/location_entities.dart';
import '../repositories/location_repository.dart';

@injectable
class GetLastLocation {
  GetLastLocation(this._repo);
  final LocationRepository _repo;
  Future<LocationEntity?> call() => _repo.getLastKnown();
}