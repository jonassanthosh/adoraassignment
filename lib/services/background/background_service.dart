import 'dart:async';
import 'dart:ui';

import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';

/// Entry point for the **background isolate** spawned by
/// `flutter_background_service`. This function runs in its own Dart isolate
/// with no shared memory with the UI isolate — any state has to travel as
/// JSON-serializable values across `service.invoke` / `service.on`.
///
/// `@pragma('vm:entry-point')` keeps the symbol from being tree-shaken in
/// release builds; without it, AOT compilation drops the function and the
/// service can't start.
@pragma('vm:entry-point')
Future<void> backgroundEntry(ServiceInstance service) async {
  // The background isolate gets a fresh `PluginRegistry`; this call wires up
  // the platform-channel plugins (geolocator, etc.) so we can use them here.
  DartPluginRegistrant.ensureInitialized();

  StreamSubscription<Position>? sub;

  Future<void> updateNotification(double lat, double lon) async {
    // The cast is a runtime check, not a type assertion — on iOS this
    // service is a `IosServiceInstance` and the call is a no-op.
    if (service is AndroidServiceInstance) {
      service.setForegroundNotificationInfo(
        title: 'Tracking your location',
        content: 'Latitude: $lat, Longitude: $lon',
      );
    }
  }

  // Main isolate triggers shutdown by invoking 'stop'. We tear down the
  // GPS subscription *before* `stopSelf()` because everything after it is
  // unreachable — the isolate dies on that call.
  service.on('stop').listen((_) async {
    await sub?.cancel();
    await service.stopSelf();
  });

  sub = Geolocator.getPositionStream(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    ),
  ).listen((pos) async {
    await updateNotification(pos.latitude, pos.longitude);
    // Forward to the main isolate via a JSON-serializable map. The main
    // isolate is the *single SQLite writer*, which lets us avoid two
    // concurrent connections fighting over WAL.
    service.invoke('update', {
      'lat': pos.latitude,
      'lon': pos.longitude,
      'accuracy': pos.accuracy,
      'ts': pos.timestamp.millisecondsSinceEpoch,
    });
  });
}
