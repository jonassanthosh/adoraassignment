import 'dart:async';

import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';

import '../../features/location/domain/entities/location_entities.dart';

@lazySingleton
class IosSlcBridge {
  static const _commands = MethodChannel('com.adoralocationassignment.locationTracking/slc');
  static const _events = EventChannel('com.adoralocationassignment.locationTracking/slc/events');

  Future<void> start() => _commands.invokeMethod<void>('start');
  Future<void> stop() => _commands.invokeMethod<void>('stop');

  Stream<LocationEntity> updates() {
    return _events.receiveBroadcastStream().map((dynamic raw) {
      final m = (raw as Map).cast<String, dynamic>();
      return LocationEntity(
        latitude: (m['lat'] as num).toDouble(),
        longitude: (m['lon'] as num).toDouble(),
        accuracy: (m['acc'] as num?)?.toDouble() ?? 0,
        timestamp: DateTime.fromMillisecondsSinceEpoch((m['ts'] as num).toInt()),
        source: 'slc',
      );
    });
  }
}