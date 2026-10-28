import 'package:flutter/material.dart';

import '../localization/flow_strings.dart';
import 'aq_primitives.dart';
import 'aq_scene.dart';
import 'aq_tokens.dart';
import 'aq_typography.dart';

/// A small "?" that opens the real-estate explainer in a bottom sheet. It never changes the screen
/// behind it: closing the sheet returns to exactly where the person was.
class AQHelpButton extends StatelessWidget {
  const AQHelpButton({super.key});

  @override
  Widget build(BuildContext context) {
    final f = FlowStrings.of(context);
    final c = AQColors.of(context);
    return Semantics(
      button: true,
      focusable: true,
      onFocus: () {},
      label: f.t('help.label'),
      excludeSemantics: true,
      onTap: () => showAQHelp(context),
      child: AQPressable(
        onTap: () => showAQHelp(context),
        child: SizedBox(
          width: AQControl.tap,
          height: AQControl.tap,
          child: Center(
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: c.accentDeep, width: 1.4),
              ),
              alignment: Alignment.center,
              child: Text(
                '?',
                style: AQTypography.of(
                  context,
                  AQText.labelMedium,
                  color: c.accentDeep,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> showAQHelp(BuildContext context) {
  // On the root navigator, so the sheet sits above the bottom navigation instead of under it.
  return showAQSheet<void>(
    context,
    useRootNavigator: true,
    builder: (s) {
      final f = FlowStrings.of(s);
      Widget item(String k) => Padding(
        padding: const EdgeInsets.only(top: AQSpacing.x3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              f.t('help.$k.t'),
              style: AQTypography.of(s, AQText.titleSmall),
            ),
            const SizedBox(height: 2),
            Text(
              f.t('help.$k.b'),
              style: AQTypography.of(s, AQText.bodyMedium, soft: true),
            ),
          ],
        ),
      );
      return ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(s).height * 0.85,
        ),
        child: Padding(
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
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(
                          f.t('help.title'),
                          style: AQTypography.of(s, AQText.headlineSmall),
                        ),
                      ),
                      const SizedBox(height: AQSpacing.x1),
                      Text(
                        f.t('help.intro'),
                        style: AQTypography.of(s, AQText.bodySmall, soft: true),
                      ),
                      item('buy'),
                      item('rent'),
                      item('sell'),
                      item('types'),
                      item('services'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AQSpacing.x4),
              AQPrimaryButton(
                label: f.t('help.close'),
                trailingChevron: false,
                onPressed: () => Navigator.of(s).pop(),
              ),
            ],
          ),
        ),
      );
    },
  );
}
