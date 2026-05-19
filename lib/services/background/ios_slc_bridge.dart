import 'dart:async';

import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';

import '../../features/location/domain/entities/location_entities.dart';

/// Dart-side bridge to the Swift `SignificantLocationManager`.
///
/// We use SLC instead of "while in use" location on iOS for the
/// terminated-state requirement: when the user force-quits the app, iOS
/// will silently re-launch us into the background ~once per 500 m of
/// movement and deliver a single fix, even with no running Dart isolate.
/// The native side persists those fixes directly to SQLite via
/// `LocationStore.swift` so data survives even when Flutter never starts.
///
/// Channel names must match what `AppDelegate.swift` registers — they're
/// strings on both ends with no compile-time guarantee.
@lazySingleton
class IosSlcBridge {
  static const _commands =
      MethodChannel('com.adoralocationassignment.locationTracking/slc');
  static const _events =
      EventChannel('com.adoralocationassignment.locationTracking/slc/events');

  /// Asks iOS to start delivering SLC events. Triggers the "Always"
  /// permission prompt the first time it's called if the user has only
  /// granted "While Using".
  Future<void> start() => _commands.invokeMethod<void>('start');

  Future<void> stop() => _commands.invokeMethod<void>('stop');

  /// Live stream of fixes coming from the native SLC manager. The native
  /// side buffers events for late subscribers so we don't miss any that
  /// arrived between `start()` and the first listen.
  ///
  /// Defensive numeric casting because everything crosses the platform
  /// boundary as `Object?` and would otherwise blow up on integer/double
  /// mismatches.
  Stream<LocationEntity> updates() {
    return _events.receiveBroadcastStream().map((dynamic raw) {
      final m = (raw as Map).cast<String, dynamic>();
      return LocationEntity(
        latitude: (m['lat'] as num).toDouble(),
        longitude: (m['lon'] as num).toDouble(),
        accuracy: (m['acc'] as num?)?.toDouble() ?? 0,
        timestamp:
            DateTime.fromMillisecondsSinceEpoch((m['ts'] as num).toInt()),
        source: 'slc',
      );
    });
  }
}
