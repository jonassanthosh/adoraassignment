import 'package:injectable/injectable.dart';
import '../repositories/location_repository.dart';

/// Use case: stop the current tracking session and release all resources.
/// Safe to invoke even when no session is active.
@injectable
class StopTracking {
  StopTracking(this._repo);
  final LocationRepository _repo;
  Future<void> call() => _repo.stopTracking();
}
