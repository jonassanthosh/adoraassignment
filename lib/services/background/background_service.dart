import 'dart:async';
import 'dart:developer';
import 'dart:ui';

import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';

import '../../notifications/notification_service.dart';
import '../../storage/location_database.dart';

const _channelId = 'location_tracking';
const _channelName = 'Location Tracking';
const _notificationId = 1001;

@pragma('vm:entry-point')
Future<void> backGroundEntry(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  final notifications = FlutterLocalNotificationsPlugin();
  final db = await LocationDatabase.instance;

  StreamSubscription<Position>? sub;

  Future<void> updateNotification(double lat, double lon) async {
    if (service is AndroidServiceInstance) {
      service.setForegroundNotificationInfo(
        title: 'Tracking your location', 
        content: 'Latitude: $lat, Longitude: $lon');
    }
  }

  service.on('stop').listen((_) async {
    await sub?.cancel();
    await db.close();
    await service.stopSelf();
  });

  sub = Geolocator.getPositionStream(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    ),
  ).listen((pos) async {
    await db.insert(
      lat: pos.latitude,
      lon: pos.longitude,
      accuracy: pos.accuracy,
      tsMillis: (pos.timestamp).millisecondsSinceEpoch,
      source: 'background',
    );
    await updateNotification(pos.latitude, pos.longitude);
    service.invoke(
      'update_notification', {
        'lat': pos.latitude,
        'lon': pos.longitude,
        'accuracy': pos.accuracy,
        'tsMillis': (pos.timestamp).millisecondsSinceEpoch,
      });
  });
}