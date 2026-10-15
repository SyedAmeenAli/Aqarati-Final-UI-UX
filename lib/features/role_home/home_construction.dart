import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/aq/aq_primitives.dart';
import '../../core/aq/aq_tokens.dart';
import '../../core/aq/aq_typography.dart';
import '../../core/localization/flow_strings.dart';
import '../devbuild/db_models.dart';
import '../devbuild/db_repository.dart';
import '../devbuild/db_widgets.dart' show DbNotice, DbSkeleton, dbTypeImage;
import 'role_home_model.dart';
import 'role_home_widgets.dart';

/// Construction: industrial and trust-first. A site photograph leads, then the company
/// profile and four "essentials". It is a company-profile home, not a project dashboard:
/// no tenders, bids, job pipeline or project tools exist for this role.
class ConstructionHome extends ConsumerWidget {
  const ConstructionHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final f = FlowStrings.of(context);
    final c = AQColors.of(context);
    final accent = roleAccent(context, HomeRole.construction);
    final org = ref.watch(dbMyOrgProvider);
    final profileGap = org.valueOrNull != null && (org.valueOrNull!.locationLabel.isEmpty || org.valueOrNull!.bio.isEmpty);
    void profile() => context.push('/app/account/workspace/profile');

    return RoleHomePage(children: [
      const RoleReveal(child: RoleHeader()),
      RoleReveal(
        index: 1,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          RoleEyebrow(f.t('rh.con.eyebrow'), color: accent),
          const SizedBox(height: AQSpacing.x1),
          Semantics(header: true, child: Text(f.t('rh.con.title'), style: AQTypography.of(context, AQText.displaySmall))),
        ]),
      ),
      const SizedBox(height: AQSpacing.x4),
      RoleReveal(
        index: 2,
        child: RolePhotoPanel(
          image: dbTypeImage(ProType.construction),
          kicker: f.t(ProType.construction.key).toUpperCase(),
          title: f.t('rh.con.hero'),
          body: f.t('rh.con.hero.b'),
          aspect: 1.15,
          alignment: Alignment.topCenter,
        ),
      ),
      const SizedBox(height: AQSpacing.x3),
      RoleReveal(
        index: 3,
        child: Semantics(
          button: true,
          label: '${f.t('rh.con.profile')}. ${f.t('rh.con.profile.sub')}',
          excludeSemantics: true,
          child: AQPressable(
            onTap: profile,
            child: Container(
              decoration: BoxDecoration(color: c.surfaceRaised, borderRadius: BorderRadius.circular(AQRadius.medium), border: Border.all(color: c.hairline)),
              clipBehavior: Clip.antiAlias,
              child: IntrinsicHeight(
                child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Container(width: 5, color: accent),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(AQSpacing.x3),
                      child: Row(children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(color: accent.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(AQRadius.small)),
                          child: Center(child: AQIcon('construction', size: 24, color: accent)),
                        ),
                        const SizedBox(width: AQSpacing.x3),
                        Expanded(
                          child: org.when(
                            loading: () => const DbSkeleton(height: 44),
                            error: (_, _) => Text(f.t('common.networkError'), style: AQTypography.of(context, AQText.bodySmall, color: c.danger)),
                            data: (o) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(o != null && o.name.isNotEmpty ? o.name : f.t('rh.con.profile'), style: AQTypography.of(context, AQText.titleMedium)),
                              Text(f.t('rh.con.profile.sub'), style: AQTypography.of(context, AQText.bodySmall, soft: true)),
                            ]),
                          ),
                        ),
                        RoleChip(f.t('rh.view'), color: accent),
                      ]),
                    ),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
      if (profileGap) ...[
        const SizedBox(height: AQSpacing.x3),
        DbNotice(f.t('rh.profileGap'), icon: 'info', action: AQTextButton(label: f.t('rh.completeProfile'), color: c.accent, onPressed: profile)),
      ],
      RoleSection(f.t('rh.con.essentials'), action: f.t('rh.manageProfile'), onAction: profile, accent: accent),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: RoleNumberCell(number: '01', label: f.t('rh.con.identity'), sub: f.t('rh.con.identity.s'), accent: accent, onTap: profile)),
        const SizedBox(width: AQSpacing.x3),
        Expanded(child: RoleNumberCell(number: '02', label: f.t('rh.con.presence'), sub: f.t('rh.con.presence.s'), accent: accent, onTap: profile)),
      ]),
      const SizedBox(height: AQSpacing.x3),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: RoleNumberCell(number: '03', label: f.t('rh.con.directory'), sub: f.t('rh.con.directory.s'), accent: accent, onTap: () => context.go('/app/explore/build/results?cat=construction'))),
        const SizedBox(width: AQSpacing.x3),
        Expanded(child: RoleNumberCell(number: '04', label: f.t('rh.con.reputation'), sub: f.t('rh.con.reputation.s'), accent: accent, onTap: () => context.push('/app/account/workspace/reviews'))),
      ]),
      RoleSection(f.t('rh.con.info'), action: f.t('rh.edit'), onAction: profile, accent: accent),
      RoleRow(label: f.t('rh.con.cr'), value: f.t('rh.con.cr.s'), onTap: () => context.push('/verification/details')),
      RoleRow(label: f.t('rh.con.office'), value: f.t('rh.view'), onTap: profile),
      RoleRow(label: f.t('rh.contact'), value: f.t('rh.unavailable'), onTap: () => context.push('/app/account/workspace/leads')),
    ]);
  }
}
