import '../entities/location_entities.dart';

/// The only contract the presentation layer needs to know to drive
/// tracking. Living in `domain/`, this interface has no Flutter or
/// platform-channel imports, which keeps the BLoC and the use cases
/// trivially testable with `mocktail`.
///
/// The concrete implementation lives in `data/` and is wired up by
/// `injectable` (`@LazySingleton(as: LocationRepository)`).
abstract class LocationRepository {
  /// One-shot read. Useful for "where am I right now?" without starting
  /// a session.
  Future<LocationEntity> getCurrentLocation();

  /// Single broadcast stream that fans in fixes from every active source
  /// (foreground, background service, iOS SLC). The presentation layer
  /// subscribes once and lets the repository do the routing.
  Stream<LocationEntity> watchLocations();

  /// Starts a tracking session. `useBackground = true` arms the
  /// platform-specific background path on top of the foreground stream,
  /// so the app keeps producing fixes when minimized or terminated.
  Future<void> startTracking({bool useBackground = false});

  Future<void> stopTracking();

  /// Last persisted fix from SQLite, or `null` on a fresh install. Used to
  /// rehydrate the UI on cold start before the first new fix arrives.
  Future<LocationEntity?> getLastKnown();
}
