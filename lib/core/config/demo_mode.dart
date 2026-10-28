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

/// Optional address of a separately hosted Admin Web Console, set at build time:
/// `--dart-define=AQARATI_ADMIN_URL=https://...`. When empty (the default) the console that ships
/// inside this app, at `#/admin`, is used.
const String kAdminUrl = String.fromEnvironment('AQARATI_ADMIN_URL');

/// The external address the "Admin Console" link opens, or null to use the in-app `/admin` route.
String? adminConsoleUrl() => kAdminUrl.isEmpty ? null : kAdminUrl;
