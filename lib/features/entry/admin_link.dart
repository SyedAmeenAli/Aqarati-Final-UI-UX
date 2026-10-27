import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/aq/aq_primitives.dart';
import '../../core/aq/aq_scene.dart';
import '../../core/aq/aq_tokens.dart';
import '../../core/aq/aq_typography.dart';
import '../../core/config/demo_mode.dart';
import '../../core/localization/flow_strings.dart';

/// Small text link on the login screen that opens the separate Admin Web Console. It only
/// opens the console's own sign-in page; admin authentication and two-step checks happen there.
class AdminConsoleLink extends StatelessWidget {
  const AdminConsoleLink({super.key});

  Future<void> _open(BuildContext context) async {
    final f = FlowStrings.of(context);
    final url = adminConsoleUrl();
    if (url != null) {
      final ok = await launchUrl(
        Uri.parse(url),
        webOnlyWindowName: '_blank',
      ).catchError((_) => false);
      if (ok || !context.mounted) return;
    }
    if (!context.mounted) return;
    await showAQSheet<void>(
      context,
      useRootNavigator: true,
      builder: (s) => Padding(
        padding: const EdgeInsets.fromLTRB(
          AQSpacing.gutter,
          AQSpacing.x2,
          AQSpacing.gutter,
          AQSpacing.x4,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(
                f.t('admin.na.t'),
                style: AQTypography.of(s, AQText.headlineSmall),
              ),
            ),
            const SizedBox(height: AQSpacing.x2),
            Text(
              f.t('admin.na.b'),
              style: AQTypography.of(s, AQText.bodyMedium, soft: true),
            ),
            const SizedBox(height: AQSpacing.x4),
            AQPrimaryButton(
              label: f.t('admin.na.ok'),
              trailingChevron: false,
              onPressed: () => Navigator.of(s).pop(),
            ),
          ],
        ),
      ),
    );
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
