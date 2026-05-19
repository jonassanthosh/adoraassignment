import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:injectable/injectable.dart';
import 'package:location_tracking/permission_helper.dart';

import '../../features/location/domain/entities/location_entities.dart';
import 'ios_slc_bridge.dart';

/// Main-isolate facade over `flutter_background_service`. Hides the
/// platform-channel plumbing and the iOS-only Significant Location
/// Changes upgrade behind a simple start / stop / updates contract.
@lazySingleton
class BackgroundServiceController {
  BackgroundServiceController(this._slc);

  final IosSlcBridge _slc;
  final _service = FlutterBackgroundService();

  Future<bool> isRunning() => _service.isRunning();

  /// Brings the service up. On iOS we also arm SLC so the OS can re-launch
  /// us into the background after a terminate; on Android the foreground
  /// service alone is enough because the OS keeps the process alive as
  /// long as the notification is showing.
  Future<void> start() async {
    // POST_NOTIFICATIONS is required on Android 13+ to show the foreground
    // service notification; without it `startService()` succeeds but the
    // notification never appears.
    final hasPerms = await ensureNotificationPermissions();
    if (!hasPerms) return;
    if (!await _service.isRunning()) {
      await _service.startService();
    }
    if (Platform.isIOS) {
      try {
        await _slc.start();
      } catch (_) {
        // Channel missing or native side not wired — swallow so the
        // foreground/suspended path still works without SLC.
      }
    }
  }

  Future<void> stop() async {
    if (Platform.isIOS) {
      try {
        await _slc.stop();
      } catch (_) {/* best-effort */}
    }
    if (!await _service.isRunning()) return;
    // The background isolate listens for this event and tears down its
    // GPS subscription before calling `stopSelf()`.
    _service.invoke('stop');
  }

  /// Stream of fixes coming back from the background isolate. We defensively
  /// `cast` and `toInt()` because values cross an isolate boundary as
  /// JSON-decoded `Map<Object?, Object?>` / `num`, which would blow up a
  /// naive `as Map<String, int>` cast.
  Stream<LocationEntity> updates() =>
      _service.on('update').where((e) => e is Map).map((event) {
        final m = (event! as Map).cast<String, dynamic>();
        return LocationEntity(
          latitude: (m['lat'] as num).toDouble(),
          longitude: (m['lon'] as num).toDouble(),
          accuracy: (m['accuracy'] as num).toDouble(),
          timestamp: DateTime.fromMillisecondsSinceEpoch(
            (m['ts'] as num).toInt(),
          ),
          source: 'background',
        );
      });
}
