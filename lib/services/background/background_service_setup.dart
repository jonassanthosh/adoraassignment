import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'background_service.dart';

const _channelId = 'location_tracker_channel';
const _channelName = 'Location Tracking';
const _notificationId = 1001;

/// Runs once during app bootstrap. Creates the Android notification
/// channel and registers the background-isolate entry point with
/// `flutter_background_service`. Idempotent — safe to call on every
/// cold start.
Future<void> initializeBackgroundService() async {
  final notif = FlutterLocalNotificationsPlugin();

  // Android 8+ requires every notification to belong to a channel. We use
  // `Importance.low` so the system shows the icon silently and never
  // surfaces a heads-up banner while tracking.
  const androidChannel = AndroidNotificationChannel(
    _channelId,
    _channelName,
    description: 'Persistent notification while we record your location.',
    importance: Importance.low,
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

  // Tells the plugin which top-level function to launch in the background
  // isolate (`backgroundEntry`) and what notification to show on Android
  // while the service is alive.
  final service = FlutterBackgroundService();
  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: backgroundEntry,
      autoStart: false, // We start it explicitly from BackgroundServiceController.
      isForegroundMode: true,
      notificationChannelId: _channelId,
      initialNotificationTitle: 'Location Tracker',
      initialNotificationContent: 'Starting...',
      foregroundServiceNotificationId: _notificationId,
      // Must match android:foregroundServiceType in the manifest, otherwise
      // Android 14+ will throw SecurityException on startForeground().
      foregroundServiceTypes: [AndroidForegroundType.location],
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: backgroundEntry,
      onBackground: _iosOnBackground,
    ),
  );
}

/// iOS background-fetch hook required by `flutter_background_service`.
/// We don't do any periodic work here — heavy lifting on iOS goes through
/// Significant Location Changes (see `IosSlcBridge`) — but the plugin
/// requires *some* function to register, so we return `true` to signal
/// success.
@pragma('vm:entry-point')
Future<bool> _iosOnBackground(ServiceInstance service) async {
  return true;
}
