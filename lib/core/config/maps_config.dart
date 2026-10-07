/// Central switch for whether a real Google Maps API key is configured for
/// **native** (Android/iOS) builds. Web no longer needs this — it renders a
/// real map unconditionally via a keyless iframe embed (see
/// `aqarati_map_view_web.dart`), which needs no API key or billing account.
///
/// Flip to true for a native build only after a real key has been placed in:
/// - android/app/src/main/AndroidManifest.xml (com.google.android.geo.API_KEY)
/// - ios/Runner/AppDelegate.swift (GMSServices.provideAPIKey)
///
/// See AQARATI_GOOGLE_MAPS_IMPLEMENTATION.md for the exact steps.
const bool kGoogleMapsConfigured = bool.fromEnvironment(
  'GOOGLE_MAPS_CONFIGURED',
  defaultValue: false,
);
