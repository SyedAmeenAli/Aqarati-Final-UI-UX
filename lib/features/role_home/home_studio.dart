import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/aq/aq_primitives.dart';
import '../../core/aq/aq_tokens.dart';
import '../../core/aq/aq_typography.dart';
import '../../core/domain/account_models.dart';
import '../../core/localization/flow_strings.dart';
import '../devbuild/db_models.dart';
import '../devbuild/db_repository.dart';
import '../devbuild/db_widgets.dart' show DbNotice, DbSkeleton, dbTypeImage;
import 'role_home_model.dart';
import 'role_home_widgets.dart';

/// Building Architecture: a quiet editorial studio page. Whitespace, fine rules, a numbered
/// index and the real bio set as a quotation. It is a profile home: the developer's project
/// manager does not exist for this role, and portfolio publishing is shown as proposed.
class ArchitectureHome extends ConsumerWidget {
  const ArchitectureHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final f = FlowStrings.of(context);
    final c = AQColors.of(context);
    final accent = roleAccent(context, HomeRole.architecture);
    final org = ref.watch(dbMyOrgProvider);
    final o = org.valueOrNull;
    void profile() => context.push('/app/account/workspace/profile');
    void reviews() => context.push('/app/account/workspace/reviews');
    void directory() => context.go('/app/explore/build/results?cat=architecture');

    Widget indexItem(String n, String label, VoidCallback onTap) => Expanded(
          child: Semantics(
            button: true,
            label: label,
            excludeSemantics: true,
            child: AQPressable(
              onTap: onTap,
              child: Container(
                constraints: const BoxConstraints(minHeight: AQControl.tap),
                padding: const EdgeInsets.symmetric(vertical: AQSpacing.x2),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(n, style: AQTypography.of(context, AQText.headlineSmall, color: accent)),
                  FittedBox(fit: BoxFit.scaleDown, alignment: AlignmentDirectional.centerStart, child: Text(label, style: AQTypography.of(context, AQText.labelSmall, color: c.inkSoft).copyWith(letterSpacing: 1.2))),
                ]),
              ),
            ),
          ),
        );

    return RoleHomePage(children: [
      const RoleReveal(child: RoleHeader()),
      RoleReveal(
        index: 1,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          RoleEyebrow(f.t('rh.arc.eyebrow'), color: accent),
          const SizedBox(height: AQSpacing.x2),
          Semantics(header: true, child: Text(f.t('rh.arc.title'), style: AQTypography.of(context, AQText.displayMedium))),
          const SizedBox(height: AQSpacing.x2),
          Text(f.t('rh.arc.sub'), style: AQTypography.of(context, AQText.bodyMedium, soft: true)),
        ]),
      ),
      const SizedBox(height: AQSpacing.x5),
      // Asymmetric frame: the picture is inset from the start edge and sharp at one corner.
      RoleReveal(
        index: 2,
        child: Padding(
          padding: const EdgeInsetsDirectional.only(start: AQSpacing.x6),
          child: RolePhotoPanel(
            image: dbTypeImage(ProType.architecture),
            title: f.t('rh.arc.hero'),
            aspect: 1.05,
            alignment: Alignment.center,
            radius: const BorderRadiusDirectional.only(
              topStart: Radius.circular(AQRadius.small),
              topEnd: Radius.circular(AQRadius.large),
              bottomStart: Radius.circular(AQRadius.large),
              bottomEnd: Radius.circular(AQRadius.large),
            ).resolve(Directionality.of(context)),
          ),
        ),
      ),
      const SizedBox(height: AQSpacing.x4),
      RoleReveal(
        index: 3,
        child: (MediaQuery.sizeOf(context).width < 380 || MediaQuery.textScalerOf(context).scale(1) > 1.3)
            ? Column(children: [
                Row(children: [indexItem('01', f.t('rh.arc.idx.profile'), profile), indexItem('02', f.t('rh.arc.idx.location'), profile)]),
                Row(children: [indexItem('03', f.t('rh.arc.idx.reviews'), reviews), indexItem('04', f.t('rh.arc.idx.contact'), () => context.push('/app/account/workspace/leads'))]),
              ])
            : Row(children: [
                indexItem('01', f.t('rh.arc.idx.profile'), profile),
                indexItem('02', f.t('rh.arc.idx.location'), profile),
                indexItem('03', f.t('rh.arc.idx.reviews'), reviews),
                indexItem('04', f.t('rh.arc.idx.contact'), () => context.push('/app/account/workspace/leads')),
              ]),
      ),
      Divider(color: c.hairline, height: AQSpacing.x6),
      RoleSection(f.t('rh.arc.practice'), action: f.t('rh.edit'), onAction: profile, accent: accent),
      org.when(
        loading: () => const DbSkeleton(height: 72),
        error: (_, _) => Text(f.t('common.networkError'), style: AQTypography.of(context, AQText.bodySmall, color: c.danger)),
        data: (x) {
          final bio = x?.bio.trim() ?? '';
          if (bio.isEmpty) return DbNotice(f.t('rh.bioEmpty'), icon: 'info', action: AQTextButton(label: f.t('rh.completeProfile'), color: c.accent, onPressed: profile));
          return Container(
            padding: const EdgeInsetsDirectional.only(start: AQSpacing.x4),
            decoration: BoxDecoration(border: BorderDirectional(start: BorderSide(color: accent, width: 2))),
            child: Text(bio, style: AQTypography.of(context, AQText.titleMedium, soft: true).copyWith(fontStyle: FontStyle.italic)),
          );
        },
      ),
      RoleSection(f.t('rh.arc.essentials'), action: f.t('rh.arc.preview'), onAction: directory, accent: accent),
      RoleRow(leadingNumber: '01', label: f.t('rh.arc.identity'), value: o != null && o.name.isNotEmpty ? o.name : null, onTap: profile),
      RoleRow(leadingNumber: '02', label: f.t('rh.arc.bio'), onTap: profile),
      RoleRow(leadingNumber: '03', label: f.t('rh.arc.location'), value: o != null && o.locationLabel.isNotEmpty ? o.locationLabel : f.t('rh.notAdded'), onTap: profile),
      RoleRow(leadingNumber: '04', label: f.t('rh.arc.verification'), onTap: () => context.go('/verification')),
      RoleRow(leadingNumber: '05', label: f.t('rh.arc.reviews'), onTap: reviews),
      RoleRow(leadingNumber: '06', label: f.t('rh.arc.contact'), value: f.t('rh.unavailable'), onTap: () => context.push('/app/account/workspace/leads')),
      const SizedBox(height: AQSpacing.x4),
      RoleReveal(
        index: 4,
        child: Semantics(
          button: true,
          label: '${f.t('rh.arc.preview')}. ${f.t('rh.arc.preview.b')}',
          excludeSemantics: true,
          child: AQPressable(
            onTap: directory,
            child: Container(
              padding: const EdgeInsets.all(AQSpacing.x4),
              decoration: BoxDecoration(color: c.surfaceRaised, borderRadius: BorderRadius.circular(AQRadius.medium), border: Border.all(color: c.hairline)),
              child: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(f.t('rh.arc.preview').toUpperCase(), style: AQTypography.of(context, AQText.labelSmall, color: accent).copyWith(letterSpacing: 1.3)),
                    const SizedBox(height: 2),
                    Text(f.t('rh.arc.preview.b'), style: AQTypography.of(context, AQText.bodySmall, soft: true)),
                  ]),
                ),
                AQIcon('chevron-right', size: 18, color: c.inkSoft, directional: true),
              ]),
            ),
          ),
        ),
      ),
      const SizedBox(height: AQSpacing.x3),
      DbNotice('${f.t('rh.arc.showcase')}: ${f.t('rh.arc.showcase.b')}', icon: 'lock'),
    ]);
  }
}

/// Interior & Exterior: a tactile, art-directed page. A room photograph, the real service type
/// (Interior / Exterior / Both) as a selector, a palette strip that is only a visual direction,
/// then profile essentials. No moodboard is saved and no showcase exists until the API does.
class InteriorHome extends ConsumerWidget {
  const InteriorHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final f = FlowStrings.of(context);
    final c = AQColors.of(context);
    final accent = roleAccent(context, HomeRole.interiorExterior);
    final org = ref.watch(dbMyOrgProvider);
    final o = org.valueOrNull;
    final service = o?.serviceType;
    void profile() => context.push('/app/account/workspace/profile');

    Widget segment(InteriorExteriorServiceType t) {
      final on = service == t;
      final label = f.t('service.${t.name}');
      return Expanded(
        child: Semantics(
          button: true,
          selected: on,
          label: label,
          hint: on ? null : f.t('rh.int.service.hint'),
          excludeSemantics: true,
          child: AQPressable(
            // The model is the source of truth: another option opens the profile editor where the
            // change is submitted for review. Nothing is switched locally.
            onTap: on
                ? null
                : () {
                    AQHaptics.selection();
                    profile();
                  },
            child: AnimatedContainer(
              duration: AQMotion.scaled(context, const Duration(milliseconds: 200)),
              height: AQControl.tap,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: on ? accent : Colors.transparent, borderRadius: BorderRadius.circular(AQRadius.medium - 4)),
              child: Text(label, style: AQTypography.of(context, AQText.labelLarge, color: on ? (c.isDark ? c.background : Colors.white) : c.inkSoft)),
            ),
          ),
        ),
      );
    }

    const palette = [Color(0xFFD7BFA3), Color(0xFFEFE6D8), Color(0xFF8A8C6A), Color(0xFF8C5A3E), Color(0xFF2B2A27), Color(0xFFB9A183)];

    return RoleHomePage(children: [
      const RoleReveal(child: RoleHeader()),
      RoleReveal(
        index: 1,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          RoleEyebrow(f.t('rh.int.eyebrow'), color: accent),
          const SizedBox(height: AQSpacing.x1),
          Semantics(header: true, child: Text(f.t('rh.int.title'), style: AQTypography.of(context, AQText.displaySmall))),
        ]),
      ),
      const SizedBox(height: AQSpacing.x4),
      RoleReveal(
        index: 2,
        child: RolePhotoPanel(
          image: dbTypeImage(ProType.interiorExterior),
          kicker: f.t('rh.int.hero.k'),
          title: f.t('rh.int.hero'),
          body: f.t('rh.int.hero.b'),
          aspect: 1.0,
          alignment: Alignment.center,
        ),
      ),
      const SizedBox(height: AQSpacing.x3),
      RoleReveal(
        index: 3,
        child: Semantics(
          container: true,
          label: f.t('rh.int.service'),
          child: Container(
            height: 56,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: c.surfaceSelected, borderRadius: BorderRadius.circular(AQRadius.medium), border: Border.all(color: c.hairline)),
            child: org.isLoading && o == null
                ? const DbSkeleton(height: 48)
                : Row(children: [for (final t in InteriorExteriorServiceType.values) segment(t)]),
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.only(top: AQSpacing.x2),
        child: Text(f.t('rh.int.service.hint'), style: AQTypography.of(context, AQText.bodySmall, color: c.inkFaint)),
      ),
      RoleSection(f.t('rh.int.language'), action: f.t('rh.edit'), onAction: profile, accent: accent),
      ExcludeSemantics(
        child: Row(children: [
          for (final p in palette)
            Expanded(
              child: Container(height: 44, margin: const EdgeInsetsDirectional.only(end: 4), decoration: BoxDecoration(color: p, borderRadius: BorderRadius.circular(6))),
            ),
        ]),
      ),
      const SizedBox(height: AQSpacing.x2),
      Text(f.t('rh.int.language.b'), style: AQTypography.of(context, AQText.bodySmall, color: c.inkFaint)),
      RoleSection(f.t('rh.int.essentials'), action: f.t('rh.manageProfile'), onAction: profile, accent: accent),
      RoleRow(label: f.t('rh.int.serviceType'), value: service == null ? f.t('rh.notAdded') : f.t('service.${service.name}'), onTap: profile),
      RoleRow(label: f.t('rh.int.bioLoc'), value: o != null && o.locationLabel.isNotEmpty ? o.locationLabel : f.t('rh.notAdded'), onTap: profile),
      RoleRow(label: f.t('rh.int.reviews'), onTap: () => context.push('/app/account/workspace/reviews')),
      RoleRow(label: f.t('rh.verification'), value: f.t('rh.verification.sub'), onTap: () => context.go('/verification')),
      const SizedBox(height: AQSpacing.x4),
      DbNotice('${f.t('rh.int.showcase')}: ${f.t('rh.int.showcase.b')}', icon: 'lock'),
    ]);
  }
}
