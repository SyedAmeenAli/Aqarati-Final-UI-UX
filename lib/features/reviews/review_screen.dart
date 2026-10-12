import 'package:flutter/material.dart';

import '../../core/aq/aq_primitives.dart';
import '../../core/aq/aq_tokens.dart';
import '../../core/aq/aq_typography.dart';
import '../../core/localization/flow_strings.dart';
import '../viewing/widgets/viewing_components.dart';
import '../viewing/widgets/viewing_format.dart';
import '../viewing/widgets/viewing_scaffold.dart';

/// "Write a review" from a business profile. Reviews only open after an engagement is confirmed by
/// both sides, so this page explains that rule instead of offering a form that would publish
/// something nobody verified.
class ReviewScreen extends StatelessWidget {
  final String listingLabel;
  final String listingTitle;
  final String priceLabel;
  const ReviewScreen({
    super.key,
    required this.listingLabel,
    required this.listingTitle,
    this.priceLabel = '',
  });

  @override
  Widget build(BuildContext context) {
    final f = FlowStrings.of(context);
    final c = AQColors.of(context);
    final name = VFmt.iso(listingTitle);
    return AQViewingScaffold(
      title: f.t('rev.title'),
      subtitle: f.t('rev.about', {'name': name}),
      backLabel: f.t('common.back'),
      onBack: () => Navigator.of(context).maybePop(),
      bottom: AQBottomActionBar(
        primary: AQPrimaryButton(
          label: f.t('common.back'),
          trailingChevron: false,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      children: [
        AQSurface(
          padding: const EdgeInsets.all(AQSpacing.x4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AQIcon('star', size: AQIconSize.large, color: c.accent),
              const SizedBox(height: AQSpacing.x3),
              Text(
                f.t('rev.t'),
                style: AQTypography.of(context, AQText.titleMedium),
              ),
              const SizedBox(height: AQSpacing.x2),
              Text(
                f.t('rev.b', {'name': name}),
                style: AQTypography.of(context, AQText.bodyMedium, soft: true),
              ),
            ],
          ),
        ),
        const SizedBox(height: AQSpacing.x3),
        AQNoticeCard(icon: 'info', title: f.t('rev.b2'), body: ''),
      ],
    );
  }
}
