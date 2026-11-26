import Flutter
import UIKit
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if let apiKey = Bundle.main.object(forInfoDictionaryKey: "GoogleMapsApiKey") as? String {
        GMSServices.provideAPIKey(apiKey)
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // Phones stay portrait only. A large screen (e.g. the iPhone Duo inner
  // screen) may rotate. The decision comes from the screen of the window's own
  // scene, so it follows the lit screen when a foldable opens or closes.
  override func application(
    _ application: UIApplication,
    supportedInterfaceOrientationsFor window: UIWindow?
  ) -> UIInterfaceOrientationMask {
    guard let bounds = window?.windowScene?.screen.bounds else { return .portrait }
    return min(bounds.width, bounds.height) >= 600 ? .all : .portrait
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
