import 'package:flutter/material.dart';

import '../config/backend_mode.dart';
import '../localization/flow_strings.dart';
import 'aq_primitives.dart';
import 'aq_tokens.dart';
import 'aq_typography.dart';

/// The visible DEMO marker promised by `backend_mode.dart`: shown wherever simulated data stands in
/// for a service that is not connected. It disappears when [kUseDemoBackend] is false.
class AQDemoNotice extends StatelessWidget {
  const AQDemoNotice({super.key});

  @override
  Widget build(BuildContext context) {
    if (!kUseDemoBackend) return const SizedBox.shrink();
    final c = AQColors.of(context);
    final f = FlowStrings.of(context);
    return Semantics(
      container: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AQSpacing.x3),
        decoration: BoxDecoration(
          color: c.surfaceSelected,
          borderRadius: BorderRadius.circular(AQRadius.medium),
          border: Border.all(color: c.hairline),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: AQIcon(
                'info',
                size: AQIconSize.small,
                color: c.accentDeep,
              ),
            ),
            const SizedBox(width: AQSpacing.x2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    f.t('common.demo'),
                    style: AQTypography.of(
                      context,
                      AQText.labelSmall,
                      color: c.accentDeep,
                    ).copyWith(letterSpacing: 1.2),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    f.t('demo.notice'),
                    style: AQTypography.of(
                      context,
                      AQText.bodySmall,
                      soft: true,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
