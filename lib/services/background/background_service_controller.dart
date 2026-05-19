import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:injectable/injectable.dart';
import 'package:location_tracking/permission_helper.dart';

import '../../features/location/domain/entities/location_entities.dart';
import 'ios_slc_bridge.dart';

@lazySingleton
class BackgroundServiceController {
  BackgroundServiceController(this._slc);

  final IosSlcBridge _slc;
  final _service = FlutterBackgroundService();

  Future<bool> isRunning() => _service.isRunning();

  Future<void> start() async {
    final hasPerms = await ensureNotificationPermissions();
    if (!hasPerms) return;
    if (!await _service.isRunning()) {
      await _service.startService();
    }
    // On iOS, also arm Significant Location Changes so we keep getting
    // (low-frequency) updates even if the OS suspends or terminates the app.
    if (Platform.isIOS) {
      try {
        await _slc.start();
      } catch (e) {
        // Channel missing or native side not wired — log and continue.
        // The foreground/background stream still works without SLC.
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
    _service.invoke('stop');
  }



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