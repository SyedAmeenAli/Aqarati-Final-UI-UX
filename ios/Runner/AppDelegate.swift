import Flutter
import UIKit
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Google Maps SDK for iOS. Replace YOUR_IOS_MAPS_API_KEY with a real,
    // iOS-restricted key from the Google Cloud Console, then flip
    // kGoogleMapsConfigured in lib/core/config/maps_config.dart to true.
    // See AQARATI_GOOGLE_MAPS_IMPLEMENTATION.md.
    GMSServices.provideAPIKey("YOUR_IOS_MAPS_API_KEY")
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
