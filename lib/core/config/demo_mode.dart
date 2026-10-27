import 'package:flutter/foundation.dart' show kIsWeb;

import 'backend_mode.dart';

/// Presentation shortcuts ("Skip for Demo" and the role skips on the purpose screen).
///
/// OFF unless a dedicated demo or QA build asks for it explicitly:
/// `flutter run -d chrome --dart-define=AQARATI_DEMO_MODE=true`
/// A normal or production build leaves it off, so no signup bypass exists there.
/// The shortcuts only replace the simulated session; they never touch a real account or service,
/// real authentication, verification, role permissions or the Admin Console sign-in.
const bool kDemoMode =
    kUseDemoBackend &&
    bool.fromEnvironment('AQARATI_DEMO_MODE', defaultValue: false);

/// Address of the separately hosted Admin Web Console (`lib/admin_main.dart`).
/// Set it when building the customer app: `--dart-define=AQARATI_ADMIN_URL=https://...`.
const String kAdminUrl = String.fromEnvironment('AQARATI_ADMIN_URL');

/// Port the admin entry point is run on during local prototype work
/// (`flutter run -d chrome -t lib/admin_main.dart --web-port 8081`).
const int kLocalAdminPort = 8081;

/// The address the "Admin Console" link opens, or null when none is configured and the customer
/// app is not running on this machine (then the link explains how to reach the console).
String? adminConsoleUrl() {
  if (kAdminUrl.isNotEmpty) return kAdminUrl;
  if (kIsWeb) {
    final host = Uri.base.host;
    if (host == 'localhost' || host == '127.0.0.1') {
      return 'http://$host:$kLocalAdminPort/';
    }
  }
  return null;
}
