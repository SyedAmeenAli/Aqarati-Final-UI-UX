import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/aq/aq_forms.dart';
import '../../../core/aq/aq_primitives.dart';
import '../../../core/aq/aq_tokens.dart';
import '../../../core/aq/aq_typography.dart';
import '../../../core/localization/viewing_strings.dart';
import '../../../data/models/property.dart';
import '../data/viewing_repository.dart' show ViewingDraft;
import '../domain/viewing_models.dart';
import '../widgets/viewing_scaffold.dart';

/// Quiet placeholder block while one section loads (never a page-wide spinner).
class AQViewingSkeleton extends StatelessWidget {
  final double height;
  const AQViewingSkeleton({super.key, this.height = 96});

  @override
  Widget build(BuildContext context) {
    final c = AQColors.of(context);
    return ExcludeSemantics(
      child: Container(height: height, margin: const EdgeInsets.only(bottom: AQSpacing.x3), decoration: BoxDecoration(color: c.ink.withValues(alpha: c.isDark ? 0.08 : 0.05), borderRadius: BorderRadius.circular(AQRadius.medium))),
    );
  }
}

class AQViewingSectionTitle extends StatelessWidget {
  final String text;
  final String? icon;
  final String? trailing;
  final VoidCallback? onTrailing;
  const AQViewingSectionTitle(this.text, {super.key, this.icon, this.trailing, this.onTrailing});

  @override
  Widget build(BuildContext context) {
    final c = AQColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: AQSpacing.x5, bottom: AQSpacing.x3),
      child: Row(children: [
        if (icon != null) ...[AQIcon(icon!, size: AQIconSize.medium, color: c.accent), const SizedBox(width: AQSpacing.x2)],
        Expanded(child: Semantics(header: true, child: Text(text, style: AQTypography.of(context, AQText.headlineSmall)))),
        if (trailing != null) AQTextButton(label: trailing!, color: c.accent, onPressed: onTrailing),
      ]),
    );
  }
}

Widget viewingLoadingFrame(BuildContext context, {String? title, VoidCallback? onBack}) {
  final v = ViewingStrings.of(context);
  return AQViewingScaffold(
    title: title,
    backLabel: v.t('vw.back'),
    onBack: onBack,
    children: const [AQViewingSkeleton(height: 120), AQViewingSkeleton(height: 160), AQViewingSkeleton(height: 96)],
  );
}

Widget viewingErrorFrame(BuildContext context, {String? title, required VoidCallback onRetry, VoidCallback? onBack, bool notFound = false}) {
  final v = ViewingStrings.of(context);
  final c = AQColors.of(context);
  return AQViewingScaffold(
    title: title,
    backLabel: v.t('vw.back'),
    onBack: onBack,
    children: [
      AQErrorBanner(text: v.t(notFound ? 'vw.notFound' : 'vw.loadError'), action: notFound ? null : AQTextButton(label: v.t('vw.retry'), color: c.accent, onPressed: onRetry)),
    ],
  );
}

/// Where "browse" actions lead: the existing property search.
void aqBrowseSimilar(BuildContext context, Property? p) => context.go(p == null ? '/search' : '/search?q=${Uri.encodeQueryComponent(p.area)}');

/// If the chosen slot is no longer bookable in fresh availability, it is stale.
ViewingSlot? staleSlot(ViewingAvailability a, ViewingDraft d) {
  final s = d.slot;
  if (s == null) return null;
  final day = a.dayOf(s.day);
  if (day == null) return null;
  for (final i in day.slots) {
    if (i.slot == s) return i.bookable ? null : s;
  }
  return null;
}
