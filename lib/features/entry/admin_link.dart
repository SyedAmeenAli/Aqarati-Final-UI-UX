import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/aq/aq_primitives.dart';
import '../../core/aq/aq_tokens.dart';
import '../../core/config/demo_mode.dart';
import '../../core/localization/flow_strings.dart';

/// Small text link on the login screen that opens the Admin Web Console. By default that is the
/// console hosted inside this same app at `/admin`; when `AQARATI_ADMIN_URL` is set at build time it
/// opens that address instead. Either way it only opens the console's own sign-in page. It is not a
/// signup role and it grants nothing.
class AdminConsoleLink extends StatelessWidget {
  const AdminConsoleLink({super.key});

  Future<void> _open(BuildContext context) async {
    final url = adminConsoleUrl();
    if (url != null) {
      final ok = await launchUrl(
        Uri.parse(url),
        webOnlyWindowName: '_blank',
      ).catchError((_) => false);
      if (ok || !context.mounted) return;
    }
    if (context.mounted) context.push('/admin');
  }

  @override
  Widget build(BuildContext context) {
    final c = AQColors.of(context);
    final f = FlowStrings.of(context);
    return AQTextButton(
      label: f.t('admin.link'),
      color: c.inkSoft,
      onPressed: () => _open(context),
    );
  }
}
