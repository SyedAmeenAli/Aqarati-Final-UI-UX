import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/backend_mode.dart';
import 'admin/admin_app.dart';
import 'admin/admin_repository.dart';

/// Entry point of the Admin Web Console. Build it on its own:
/// `flutter build web -t lib/admin_main.dart --output build/web_admin`.
/// The customer app (`lib/main.dart`) never imports anything under `lib/admin/`.
void main() {
  // QA bundles expose the semantics tree from the start so a browser (or a screen reader) can reach every control.
  if (kShowReviewTools) WidgetsFlutterBinding.ensureInitialized().ensureSemantics();
  runApp(
    ProviderScope(
      overrides: kUseDemoBackend ? adminOverrides(DemoAdminStore()) : const [],
      child: const AdminApp(),
    ),
  );
}
