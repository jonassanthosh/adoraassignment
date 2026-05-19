import UIKit
import Flutter
import CoreLocation

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // After Flutter's UISceneDelegate migration, `window` is nil here.
    // Use FlutterPluginRegistry (FlutterAppDelegate conforms to it) to get
    // a binaryMessenger instead of reaching through `rootViewController`.
    guard let registrar = self.registrar(forPlugin: "SignificantLocationPlugin") else {
      return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    let messenger = registrar.messenger()

    let methodChannel = FlutterMethodChannel(
      name: "com.adoralocationassignment.locationTracking/slc",
      binaryMessenger: messenger
    )
    methodChannel.setMethodCallHandler { call, result in
      switch call.method {
      case "start":
        SignificantLocationManager.shared.start()
        result(nil)
      case "stop":
        SignificantLocationManager.shared.stop()
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    let eventChannel = FlutterEventChannel(
      name: "com.adoralocationassignment.locationTracking/slc/events",
      binaryMessenger: messenger
    )
    eventChannel.setStreamHandler(SignificantLocationManager.shared)

    if let opts = launchOptions, opts[.location] != nil {
      SignificantLocationManager.shared.handleHeadlessLaunch()
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
