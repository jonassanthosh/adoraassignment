import 'package:injectable/injectable.dart';
import '../repositories/location_repository.dart';

@injectable
class StopTracking {
  StopTracking(this._repo);
  final LocationRepository _repo;
  Future<void> call() => _repo.stopTracking();
}