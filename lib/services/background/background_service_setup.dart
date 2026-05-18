import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'background_service.dart';

const _channelId = 'location_tracker_channel';
const _channelName = 'Location Tracking';
const _notificationId = 1001;

Future<void> initializeBackgroundService() async {
  final notif = FlutterLocalNotificationsPlugin();

  // 1) Make sure the Android notification channel exists.
  const androidChannel = AndroidNotificationChannel(
    _channelId,
    _channelName,
    description: 'Persistent notification while we record your location.',
    importance: Importance.low,                    // low = silent, no heads-up
  );

  await notif
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(androidChannel);

  await notif.initialize(
    settings: const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    ),
  );

  // 2) Configure the background service.
  final service = FlutterBackgroundService();
  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: backgroundEntry,
      autoStart: false,                            // we start it manually
      isForegroundMode: true,
      notificationChannelId: _channelId,
      initialNotificationTitle: 'Location Tracker',
      initialNotificationContent: 'Starting...',
      foregroundServiceNotificationId: _notificationId,
      foregroundServiceTypes: [AndroidForegroundType.location],
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: backgroundEntry,
      onBackground: _iosOnBackground,              // we'll define on Day 4
    ),
  );
}

@pragma('vm:entry-point')
Future<bool> _iosOnBackground(ServiceInstance service) async {
  return true;
}