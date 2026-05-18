import 'dart:async';

import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:injectable/injectable.dart';
import 'package:location_tracking/permission_helper.dart';

import '../../features/location/domain/entities/location_entities.dart';

@lazySingleton
class BackgroundServiceController {
  final _service = FlutterBackgroundService();

  Future<bool> isRunning() => _service.isRunning();

  Future<void> start() async {
    final hasPerms = await ensureNotificationPermissions();
    if(!hasPerms) return;
    if (await _service.isRunning()) return;
    await _service.startService();
  }

  Future<void> stop() async {
    if (!await _service.isRunning()) return;
    _service.invoke('stop');
  }



  Stream<LocationEntity> updates() => _service.on('update').map((event) {
    final m = event ?? {};
    return LocationEntity(
      latitude: (m['lat'] as num).toDouble(),
      longitude: (m['lon'] as num).toDouble(),
      accuracy: (m['accuracy'] as num).toDouble(),
      timestamp: DateTime.fromMillisecondsSinceEpoch(m['ts'] as int),
      source: 'background',
    );
  });
}