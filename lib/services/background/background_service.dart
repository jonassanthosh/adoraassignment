import 'dart:async';
import 'dart:ui';

import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';

@pragma('vm:entry-point')
Future<void> backgroundEntry(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  StreamSubscription<Position>? sub;

  Future<void> updateNotification(double lat, double lon) async {
    if (service is AndroidServiceInstance) {
      service.setForegroundNotificationInfo(
        title: 'Tracking your location',
        content: 'Latitude: $lat, Longitude: $lon',
      );
    }
  }

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
    // Forward to the main isolate; the main isolate is the single DB writer.
    service.invoke('update', {
      'lat': pos.latitude,
      'lon': pos.longitude,
      'accuracy': pos.accuracy,
      'ts': pos.timestamp.millisecondsSinceEpoch,
    });
  });
}
