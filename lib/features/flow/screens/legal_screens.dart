import 'package:flutter/material.dart';
import '../../../core/aq/aq_auth_scaffold.dart';
import '../../../core/aq/aq_forms.dart';
import '../../../core/aq/aq_scene.dart';
import '../../../core/aq/aq_tokens.dart';
import '../../../core/aq/aq_typography.dart';
import '../../../core/localization/flow_strings.dart';

enum LegalKind { terms, privacy }

/// Terms of Use / Privacy Policy. Opened with `push` over the sign-up form so nothing entered is lost.
/// This is the frontend shell: the document body is supplied by AQARATI; no legal text is invented here.
class LegalScreen extends StatelessWidget {
  final LegalKind kind;
  const LegalScreen({super.key, required this.kind});

  @override
  Widget build(BuildContext context) {
    final f = FlowStrings.of(context);
    return AQAuthScaffold(
      showLogo: false,
      title: f.t(kind == LegalKind.terms ? 'legal.terms' : 'legal.privacy'),
      onBack: () => aqBack(context, '/entry'),
      backLabel: f.t('common.back'),
      children: [
        AQErrorBanner(tone: AQBannerTone.info, text: f.t('legal.shell')),
        Text(f.t('legal.keep'), style: AQTypography.of(context, AQText.bodySmall, color: AQColors.of(context).inkSoft)),
      ],
    );
  }
}
