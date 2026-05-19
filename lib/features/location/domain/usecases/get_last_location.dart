import 'package:injectable/injectable.dart';
import '../entities/location_entities.dart';
import '../repositories/location_repository.dart';

/// Use case: read the most recent persisted fix from local storage.
/// Returns `null` on a first-ever launch. Used by the BLoC on cold start
/// to show the last known position while the first live fix arrives.
@injectable
class GetLastLocation {
  GetLastLocation(this._repo);
  final LocationRepository _repo;
  Future<LocationEntity?> call() => _repo.getLastKnown();
}
