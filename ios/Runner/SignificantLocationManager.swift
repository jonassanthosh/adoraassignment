import Foundation
import CoreLocation
import Flutter

class SignificantLocationManager: NSObject {
  static let shared = SignificantLocationManager()
  private let manager = CLLocationManager()
  private var sink: FlutterEventSink?
  private var isMonitoring = false
  private var pendingEvents: [[String: Any]] = []

  override init() {
    super.init()
    manager.delegate = self
    manager.allowsBackgroundLocationUpdates = true
    manager.pausesLocationUpdatesAutomatically = false
    manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    manager.activityType = .other
  }

  func start() {
    // Mark intent first so the auth-change delegate knows to re-arm
    // after the user grants permission asynchronously.
    isMonitoring = true
    requestAuthIfNeeded()
    manager.startMonitoringSignificantLocationChanges()
  }

  func stop() {
    manager.stopMonitoringSignificantLocationChanges()
    isMonitoring = false
  }

  /// Called by AppDelegate when iOS launched us due to a location event.
  /// We must re-arm the manager so it processes the queued event.
  func handleHeadlessLaunch() {
    manager.startMonitoringSignificantLocationChanges()
  }

  private func requestAuthIfNeeded() {
    let status: CLAuthorizationStatus
    if #available(iOS 14, *) {
      status = manager.authorizationStatus
    } else {
      status = CLLocationManager.authorizationStatus()
    }

    switch status {
    case .notDetermined:
      manager.requestWhenInUseAuthorization()
    case .authorizedWhenInUse:
      manager.requestAlwaysAuthorization()
    case .authorizedAlways, .denied, .restricted:
      break
    @unknown default:
      break
    }
  }
}

extension SignificantLocationManager: FlutterStreamHandler {
  func onListen(
    withArguments _: Any?,
    eventSink events: @escaping FlutterEventSink
  ) -> FlutterError? {
    sink = events
    // Drain any events we received before the Dart side subscribed.
    for ev in pendingEvents { events(ev) }
    pendingEvents.removeAll()
    return nil
  }

  func onCancel(withArguments _: Any?) -> FlutterError? {
    sink = nil
    return nil
  }
}

extension SignificantLocationManager: CLLocationManagerDelegate {
  func locationManager(
    _ manager: CLLocationManager,
    didUpdateLocations locations: [CLLocation]
  ) {
    guard let last = locations.last else { return }
    let payload: [String: Any] = [
      "lat": last.coordinate.latitude,
      "lon": last.coordinate.longitude,
      "acc": last.horizontalAccuracy,
      "ts": Int(last.timestamp.timeIntervalSince1970 * 1000),
    ]

    // 1) Persist directly to the SQLite file (works in headless launches).
    LocationStore.shared.append(
      lat: last.coordinate.latitude,
      lon: last.coordinate.longitude,
      acc: last.horizontalAccuracy,
      ts: payload["ts"] as! Int
    )

    // 2) Also forward to Dart if we have an active sink.
    if let sink = sink {
      sink(payload)
    } else {
      pendingEvents.append(payload)
    }
  }

  func locationManager(
    _ manager: CLLocationManager,
    didFailWithError error: Error
  ) {
    NSLog("[SLC] error: \(error.localizedDescription)")
  }

  @available(iOS 14, *)
  func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    NSLog("[SLC] auth status changed: \(manager.authorizationStatus.rawValue)")
    switch manager.authorizationStatus {
    case .authorizedAlways:
      // Now we have what SLC actually needs; (re-)arm the manager if the
      // app intended to be monitoring.
      if isMonitoring {
        manager.startMonitoringSignificantLocationChanges()
      }
    case .authorizedWhenInUse:
      // SLC technically works with whileInUse, but updates stop being
      // delivered once the app suspends. Prompt for the Always upgrade.
      manager.requestAlwaysAuthorization()
    default:
      break
    }
  }
}