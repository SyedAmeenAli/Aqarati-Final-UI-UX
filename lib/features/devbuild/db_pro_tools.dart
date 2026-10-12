import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/aq/aq_documents.dart';
import '../../core/aq/aq_forms.dart';
import '../../core/aq/aq_primitives.dart';
import '../../core/aq/aq_scene.dart';
import '../../core/aq/aq_tokens.dart';
import '../../core/aq/aq_typography.dart';
import '../../core/domain/account_models.dart';
import '../../core/localization/flow_strings.dart';
import '../../data/api/account_api.dart' show verificationProvider;
import '../viewing/widgets/viewing_format.dart';
import '../viewing/widgets/viewing_scaffold.dart';
import '../workspace/aq_home.dart' show aqImg;
import 'db_models.dart';
import 'db_profile.dart' show DbReviewCard;
import 'db_repository.dart';
import 'db_widgets.dart';
import 'db_workspace.dart';

const _wsBack = '/app/account/workspace';

/// Last save outcome for the company profile, as the service reported it. In memory only.
final dbProfileSaveProvider = StateProvider<ProfileSaveState?>((ref) => null);

bool dbValidOptionalPhone(String raw) {
  final d = raw
      .replaceAll(RegExp(r'[\s\-()]'), '')
      .replaceFirst(RegExp(r'^(\+|00)968'), '');
  return raw.trim().isEmpty || RegExp(r'^[0-9٠-٩]{8}$').hasMatch(d);
}

// ------------------------------------------------ #78 manage company profile

class DbProfileEditScreen extends ConsumerStatefulWidget {
  const DbProfileEditScreen({super.key});
  @override
  ConsumerState<DbProfileEditScreen> createState() =>
      _DbProfileEditScreenState();
}

class _DbProfileEditScreenState extends ConsumerState<DbProfileEditScreen> {
  final _bio = TextEditingController();
  final _phone = TextEditingController();
  final _wa = TextEditingController();
  String? _gov;
  InteriorExteriorServiceType? _service;
  bool _loaded = false;
  bool _busy = false;
  Object? _failure;
  String? _phoneErr, _waErr;

  @override
  void dispose() {
    _bio.dispose();
    _phone.dispose();
    _wa.dispose();
    super.dispose();
  }

  void _init(DbProfessional o) {
    if (_loaded) return;
    _loaded = true;
    _bio.text = o.bio;
    _phone.text = o.phone ?? '';
    _wa.text = o.whatsapp ?? '';
    _gov = o.governorate.isEmpty ? null : o.governorate;
    _service = o.serviceType;
  }

  Future<void> _save() async {
    final f = FlowStrings.of(context);
    setState(() {
      _phoneErr = dbValidOptionalPhone(_phone.text) ? null : f.t('err.phone');
      _waErr = dbValidOptionalPhone(_wa.text) ? null : f.t('err.phone');
      _failure = null;
    });
    if (_phoneErr != null || _waErr != null) return;
    setState(() => _busy = true);
    try {
      final r = await ref
          .read(devBuildRepositoryProvider)
          .updateMyProfile(
            ProfileEdit(
              bio: _bio.text.trim(),
              phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
              whatsapp: _wa.text.trim().isEmpty ? null : _wa.text.trim(),
              serviceType: _service,
              governorate: _gov ?? '',
            ),
          );
      ref.read(dbProfileSaveProvider.notifier).state = r;
      ref.invalidate(dbMyOrgProvider);
      if (mounted) context.push('/app/account/workspace/profile/status');
    } catch (e) {
      if (mounted) setState(() => _failure = e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final f = FlowStrings.of(context);
    final c = AQColors.of(context);
    final caps = ref.watch(devBuildRepositoryProvider).caps;
    return DbGuard(
      title: f.t('db.pe.title'),
      backFallback: _wsBack,
      builder: (context, a) {
        final org = ref.watch(dbMyOrgProvider);
        return org.when(
          loading: () => DbShellPage(
            title: f.t('db.pe.title'),
            onBack: () => aqBack(context, _wsBack),
            children: const [DbSkeletonList(count: 3, height: 90)],
          ),
          error: (e, _) => DbShellPage(
            title: f.t('db.pe.title'),
            onBack: () => aqBack(context, _wsBack),
            children: [
              DbErrorCard(
                error: e,
                onRetry: () => ref.invalidate(dbMyOrgProvider),
              ),
            ],
          ),
          data: (o) {
            if (o == null)
              return DbShellPage(
                title: f.t('db.pe.title'),
                onBack: () => aqBack(context, _wsBack),
                children: [DbNotice(f.t('db.denied.b'), icon: 'lock')],
              );
            _init(o);
            final type = a.type!;
            return DbShellPage(
              eyebrow: f.t('db.ws.eyebrow'),
              title: f.t('db.pe.title'),
              subtitle: f.t('db.pe.sub'),
              onBack: () => aqBack(context, _wsBack),
              children: [
                _section(context, f.t('db.pe.basic'), [
                  _readonly(context, f.t('field.businessName'), o.name),
                  _readonly(context, f.t('db.pe.type'), f.t(type.key)),
                  Text(
                    f.t('db.pe.locked'),
                    style: AQTypography.of(
                      context,
                      AQText.bodySmall,
                      soft: true,
                    ),
                  ),
                ]),
                if (type == ProType.interiorExterior)
                  _section(context, f.t('db.services'), [
                    DbPillRow(
                      pills: [
                        for (final s in InteriorExteriorServiceType.values)
                          (
                            f.t('service.${s.name}'),
                            _service == s,
                            () => setState(() => _service = s),
                          ),
                      ],
                    ),
                  ]),
                _section(context, f.t('db.pe.about'), [
                  AQTextField(
                    label: f.t('db.pe.bio'),
                    controller: _bio,
                    hint: f.t('db.pe.bio.hint'),
                    action: TextInputAction.newline,
                    keyboardType: TextInputType.multiline,
                  ),
                ]),
                _section(context, f.t('db.location'), [
                  DbSelectField<String>(
                    label: f.t('db.f.gov'),
                    valueLabel: _gov == null ? null : dbGovLabel(f, _gov!),
                    hint: f.t('db.f.select'),
                    onTap: () async {
                      final r = await showDbChoiceSheet<String>(
                        context,
                        title: f.t('db.f.gov'),
                        selected: _gov,
                        options: [
                          for (final g in omanGovernorates.keys)
                            (g, dbGovLabel(f, g)),
                        ],
                      );
                      if (r != null) setState(() => _gov = r);
                    },
                  ),
                ]),
                _section(context, f.t('db.pe.contact'), [
                  AQTextField(
                    label: f.t('db.pe.phone'),
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    error: _phoneErr,
                  ),
                  const SizedBox(height: AQSpacing.x3),
                  AQTextField(
                    label: f.t('db.pe.whatsapp'),
                    controller: _wa,
                    keyboardType: TextInputType.phone,
                    error: _waErr,
                    action: TextInputAction.done,
                  ),
                ]),
                _section(context, f.t('db.pe.media'), [
                  DbNotice(f.t('db.pe.media.off'), icon: 'lock'),
                ]),
                _section(context, f.t('db.pe.verif'), [
                  Text(
                    f.t('db.pe.verif.b'),
                    style: AQTypography.of(
                      context,
                      AQText.bodyMedium,
                      soft: true,
                    ),
                  ),
                  const SizedBox(height: AQSpacing.x2),
                  AQSecondaryButton(
                    label: f.t('home.viewStatus'),
                    trailingChevron: false,
                    onPressed: () => context.push('/verification'),
                  ),
                ]),
                if (!caps.profileEdit)
                  DbNotice(f.t('db.pe.unavailable'), icon: 'lock')
                else ...[
                  if (_failure != null) ...[
                    DbErrorCard(error: _failure, onRetry: _busy ? null : _save),
                    const SizedBox(height: AQSpacing.x3),
                  ],
                  AQPrimaryButton(
                    label: f.t('db.pe.save'),
                    trailingChevron: false,
                    loading: _busy,
                    onPressed: _busy ? null : _save,
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: AQSpacing.x2),
                    child: Text(
                      f.t('db.pe.reviewNote'),
                      style: AQTypography.of(
                        context,
                        AQText.bodySmall,
                        color: c.inkSoft,
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }

  Widget _section(BuildContext context, String title, List<Widget> children) =>
      Padding(
        padding: const EdgeInsets.only(bottom: AQSpacing.x5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: AQSpacing.x2),
              child: Semantics(
                header: true,
                child: Text(
                  title,
                  style: AQTypography.of(context, AQText.headlineSmall),
                ),
              ),
            ),
            ...children,
          ],
        ),
      );

  Widget _readonly(BuildContext context, String k, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            k,
            style: AQTypography.of(context, AQText.bodySmall, soft: true),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            VFmt.iso(v),
            style: AQTypography.of(context, AQText.bodyMedium),
          ),
        ),
      ],
    ),
  );
}

// -------------------------------------- #84 profile changes & review status

class DbProfileStatusScreen extends ConsumerWidget {
  const DbProfileStatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final f = FlowStrings.of(context);
    final saved = ref.watch(dbProfileSaveProvider);
    final v = ref.watch(verificationProvider);
    return DbGuard(
      inShell: false,
      title: f.t('db.ps2.title'),
      backFallback: '/app/account/workspace/profile',
      builder: (context, a) => AQViewingScaffold(
        title: f.t('db.ps2.title'),
        subtitle: f.t('db.ps2.sub'),
        backLabel: f.t('common.back'),
        onBack: () => aqBack(context, '/app/account/workspace/profile'),
        children: [
          Text(
            f.t('db.ps2.verif'),
            style: AQTypography.of(context, AQText.headlineSmall),
          ),
          const SizedBox(height: AQSpacing.x2),
          v.when(
            loading: () => const DbSkeleton(height: 60),
            error: (e, _) => DbErrorCard(
              error: e,
              onRetry: () => ref.invalidate(verificationProvider),
            ),
            data: (info) =>
                DbFit(AQStatusBadge(grant: info.grant, stage: info.stage)),
          ),
          const SizedBox(height: AQSpacing.x5),
          Text(
            f.t('db.ps2.edits'),
            style: AQTypography.of(context, AQText.headlineSmall),
          ),
          const SizedBox(height: AQSpacing.x2),
          if (saved == null)
            DbNotice(f.t('db.ps2.none'), icon: 'info')
          else
            DbNotice(
              f.t(
                saved == ProfileSaveState.live
                    ? 'db.ps2.live'
                    : 'db.ps2.pending',
              ),
              icon: saved == ProfileSaveState.live ? 'check' : 'clock',
            ),
          const SizedBox(height: AQSpacing.x3),
          Text(
            f.t('db.ps2.history'),
            style: AQTypography.of(context, AQText.bodySmall, soft: true),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------- #79 contact activity

class DbLeadsScreen extends ConsumerWidget {
  const DbLeadsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final f = FlowStrings.of(context);
    final repo = ref.watch(devBuildRepositoryProvider);
    return DbGuard(
      title: f.t('db.leads.title'),
      backFallback: _wsBack,
      builder: (context, a) => DbShellPage(
        eyebrow: f.t('db.ws.eyebrow'),
        title: f.t('db.leads.title'),
        subtitle: f.t('db.leads.sub'),
        onBack: () => aqBack(context, _wsBack),
        children: [
          if (!repo.caps.leadEvents)
            DbNotice(f.t('db.leads.unavailable'), icon: 'lock')
          else
            ref
                .watch(dbMyContactEventsProvider)
                .when(
                  loading: () => const DbSkeletonList(count: 3, height: 76),
                  error: (e, _) => DbErrorCard(
                    error: e,
                    onRetry: () => ref.invalidate(dbMyContactEventsProvider),
                  ),
                  data: (list) => list.isEmpty
                      ? DbNotice(f.t('db.leads.empty'), icon: 'phone')
                      : Column(
                          children: [
                            for (final e in list)
                              Padding(
                                padding: const EdgeInsets.only(
                                  bottom: AQSpacing.x3,
                                ),
                                child: _EventRow(event: e),
                              ),
                          ],
                        ),
                ),
        ],
      ),
    );
  }
}

class _EventRow extends StatelessWidget {
  final ContactEvent event;
  const _EventRow({required this.event});
  @override
  Widget build(BuildContext context) {
    final c = AQColors.of(context);
    final f = FlowStrings.of(context);
    final label = f.t(
      event.channel == ContactChannel.call
          ? 'db.contact.call'
          : 'db.contact.whatsapp',
    );
    return Semantics(
      button: true,
      label:
          '$label, ${event.targetLabel}, ${VFmt.fullDate(context, event.at)}',
      excludeSemantics: true,
      child: AQPressable(
        onTap: () => context.push('/workspace/leads/${event.id}'),
        child: Container(
          padding: const EdgeInsets.all(AQSpacing.x3),
          decoration: BoxDecoration(
            color: c.surfaceRaised,
            borderRadius: BorderRadius.circular(AQRadius.medium),
            border: Border.all(color: c.hairline),
          ),
          child: Row(
            children: [
              DbIcon(
                event.channel == ContactChannel.call ? 'phone' : 'whatsapp',
                size: 22,
                color: c.accent,
              ),
              const SizedBox(width: AQSpacing.x3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: AQTypography.of(context, AQText.titleSmall),
                    ),
                    Text(
                      VFmt.iso(event.targetLabel),
                      style: AQTypography.of(
                        context,
                        AQText.bodySmall,
                        soft: true,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                VFmt.shortDate(context, event.at),
                style: AQTypography.of(context, AQText.bodySmall, soft: true),
              ),
              const SizedBox(width: 4),
              AQIcon(
                'chevron-right',
                size: 18,
                color: c.inkSoft,
                directional: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------ #80 contact event detail

class DbLeadDetailScreen extends ConsumerWidget {
  final String id;
  const DbLeadDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final f = FlowStrings.of(context);
    return DbGuard(
      inShell: false,
      title: f.t('db.lead.title'),
      backFallback: '/app/account/workspace/leads',
      builder: (context, a) {
        void back() => aqBack(context, '/app/account/workspace/leads');
        final async = ref.watch(dbMyContactEventsProvider);
        return async.when(
          loading: () => AQViewingScaffold(
            backLabel: f.t('common.back'),
            onBack: back,
            children: const [DbSkeleton(height: 140)],
          ),
          error: (e, _) => AQViewingScaffold(
            title: f.t('db.lead.title'),
            backLabel: f.t('common.back'),
            onBack: back,
            children: [
              DbErrorCard(
                error: e,
                onRetry: () => ref.invalidate(dbMyContactEventsProvider),
              ),
            ],
          ),
          data: (list) {
            final e = list.where((x) => x.id == id).firstOrNull;
            if (e == null)
              return AQViewingScaffold(
                title: f.t('db.lead.title'),
                backLabel: f.t('common.back'),
                onBack: back,
                children: [DbNotice(f.t('db.lead.gone'), icon: 'info')],
              );
            final c = AQColors.of(context);
            Widget row(String k, String v) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      k,
                      style: AQTypography.of(
                        context,
                        AQText.bodySmall,
                        soft: true,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      VFmt.iso(v),
                      style: AQTypography.of(context, AQText.bodyMedium),
                    ),
                  ),
                ],
              ),
            );
            return AQViewingScaffold(
              title: f.t(
                e.channel == ContactChannel.call
                    ? 'db.lead.call'
                    : 'db.lead.wa',
              ),
              backLabel: f.t('common.back'),
              onBack: back,
              children: [
                Container(
                  padding: const EdgeInsets.all(AQSpacing.x4),
                  decoration: BoxDecoration(
                    color: c.surfaceRaised,
                    borderRadius: BorderRadius.circular(AQRadius.medium),
                    border: Border.all(color: c.hairline),
                  ),
                  child: Column(
                    children: [
                      row(
                        f.t('db.lead.channel'),
                        f.t(
                          e.channel == ContactChannel.call
                              ? 'db.contact.call'
                              : 'db.contact.whatsapp',
                        ),
                      ),
                      row(f.t('db.lead.target'), e.targetLabel),
                      row(
                        f.t('db.lead.when'),
                        '${VFmt.fullDate(context, e.at)} · ${VFmt.time(context, e.at)}',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AQSpacing.x3),
                DbNotice(f.t('db.lead.note'), icon: 'info'),
              ],
            );
          },
        );
      },
    );
  }
}

// -------------------------------------------------- #81 business reviews

class DbBizReviewsScreen extends ConsumerStatefulWidget {
  const DbBizReviewsScreen({super.key});
  @override
  ConsumerState<DbBizReviewsScreen> createState() => _DbBizReviewsScreenState();
}

class _DbBizReviewsScreenState extends ConsumerState<DbBizReviewsScreen> {
  int? _stars;

  @override
  Widget build(BuildContext context) {
    final f = FlowStrings.of(context);
    return DbGuard(
      title: f.t('db.bizrev.title'),
      backFallback: _wsBack,
      builder: (context, a) {
        final org = ref.watch(dbMyOrgProvider).valueOrNull;
        final revs = org == null ? null : ref.watch(dbReviewsProvider(org.id));
        return DbShellPage(
          eyebrow: f.t('db.ws.eyebrow'),
          title: f.t('db.bizrev.title'),
          subtitle: f.t('db.bizrev.sub'),
          onBack: () => aqBack(context, _wsBack),
          children: [
            if (revs == null)
              const DbSkeletonList(count: 2, height: 100)
            else
              revs.when(
                loading: () => const DbSkeletonList(count: 2, height: 100),
                error: (e, _) => DbErrorCard(
                  error: e,
                  onRetry: () => ref.invalidate(dbReviewsProvider(org!.id)),
                ),
                data: (list) {
                  if (list.isEmpty)
                    return DbNotice(f.t('db.bizrev.empty'), icon: 'star');
                  final shown = [
                    for (final r in list)
                      if (_stars == null || r.rating == _stars) r,
                  ];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DbPillRow(
                        pills: [
                          (
                            f.t('flt.all'),
                            _stars == null,
                            () => setState(() => _stars = null),
                          ),
                          for (final s in [5, 4, 3])
                            (
                              f.t('db.rev.stars', {'n': VFmt.n(context, s)}),
                              _stars == s,
                              () => setState(
                                () => _stars = _stars == s ? null : s,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: AQSpacing.x3),
                      if (shown.isEmpty)
                        DbNotice(f.t('db.rev.filterEmpty'))
                      else
                        for (final r in shown) DbReviewCard(r),
                      if (!ref
                          .read(devBuildRepositoryProvider)
                          .caps
                          .reviewReplies)
                        Text(
                          f.t('db.bizrev.noReply'),
                          style: AQTypography.of(
                            context,
                            AQText.bodySmall,
                            soft: true,
                          ),
                        ),
                    ],
                  );
                },
              ),
          ],
        );
      },
    );
  }
}

// ------------------------------------------------ #85 engagement confirmation

class DbEngagementsScreen extends ConsumerWidget {
  const DbEngagementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final f = FlowStrings.of(context);
    final repo = ref.watch(devBuildRepositoryProvider);
    return DbGuard(
      title: f.t('db.eng.title'),
      backFallback: _wsBack,
      builder: (context, a) => DbShellPage(
        eyebrow: f.t('db.ws.eyebrow'),
        title: f.t('db.eng.title'),
        subtitle: f.t('db.eng.sub'),
        onBack: () => aqBack(context, _wsBack),
        children: [
          if (!repo.caps.engagements)
            DbNotice(f.t('db.eng.unavailable'), icon: 'lock')
          else
            ref
                .watch(dbMyEngagementsProvider)
                .when(
                  loading: () => const DbSkeletonList(count: 2, height: 90),
                  error: (e, _) => DbErrorCard(
                    error: e,
                    onRetry: () => ref.invalidate(dbMyEngagementsProvider),
                  ),
                  data: (list) => list.isEmpty
                      ? DbNotice(f.t('db.eng.empty'), icon: 'handshake')
                      : Column(
                          children: [
                            for (final e in list)
                              Padding(
                                padding: const EdgeInsets.only(
                                  bottom: AQSpacing.x3,
                                ),
                                child: _EngagementRow(e: e),
                              ),
                          ],
                        ),
                ),
          const SizedBox(height: AQSpacing.x3),
          Text(
            f.t('db.eng.rules'),
            style: AQTypography.of(context, AQText.bodySmall, soft: true),
          ),
        ],
      ),
    );
  }
}

class _EngagementRow extends StatelessWidget {
  final Engagement e;
  const _EngagementRow({required this.e});
  @override
  Widget build(BuildContext context) {
    final c = AQColors.of(context);
    final f = FlowStrings.of(context);
    return Semantics(
      button: true,
      label: '${e.clientLabel}, ${f.t('db.eng.s.${e.state.name}')}',
      excludeSemantics: true,
      child: AQPressable(
        onTap: () => context.push('/workspace/engagements/${e.id}'),
        child: Container(
          padding: const EdgeInsets.all(AQSpacing.x3),
          decoration: BoxDecoration(
            color: c.surfaceRaised,
            borderRadius: BorderRadius.circular(AQRadius.medium),
            border: Border.all(color: c.hairline),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      VFmt.iso(e.clientLabel),
                      style: AQTypography.of(context, AQText.titleSmall),
                    ),
                    Text(
                      f.t('db.eng.s.${e.state.name}'),
                      style: AQTypography.of(
                        context,
                        AQText.bodySmall,
                        soft: true,
                      ),
                    ),
                  ],
                ),
              ),
              AQIcon(
                'chevron-right',
                size: 18,
                color: c.inkSoft,
                directional: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DbEngagementDetailScreen extends ConsumerStatefulWidget {
  final String id;
  const DbEngagementDetailScreen({super.key, required this.id});
  @override
  ConsumerState<DbEngagementDetailScreen> createState() =>
      _DbEngagementDetailScreenState();
}

class _DbEngagementDetailScreenState
    extends ConsumerState<DbEngagementDetailScreen> {
  bool _busy = false;
  Object? _failure;

  Future<void> _confirm() async {
    final f = FlowStrings.of(context);
    final ok = await showAQSheet<bool>(
      context,
      builder: (s) => Padding(
        padding: const EdgeInsets.fromLTRB(
          AQSpacing.gutter,
          AQSpacing.x3,
          AQSpacing.gutter,
          AQSpacing.x4,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              f.t('db.eng.confirm.t'),
              style: AQTypography.of(s, AQText.headlineSmall),
            ),
            const SizedBox(height: AQSpacing.x2),
            Text(
              f.t('db.eng.confirm.b'),
              style: AQTypography.of(s, AQText.bodyMedium, soft: true),
            ),
            const SizedBox(height: AQSpacing.x4),
            AQPrimaryButton(
              label: f.t('db.eng.confirm.cta'),
              trailingChevron: false,
              onPressed: () => Navigator.of(s).pop(true),
            ),
            const SizedBox(height: AQSpacing.x2),
            AQSecondaryButton(
              label: f.t('common.cancel'),
              trailingChevron: false,
              onPressed: () => Navigator.of(s).pop(false),
            ),
          ],
        ),
      ),
    );
    if (ok != true || !mounted) return;
    setState(() {
      _busy = true;
      _failure = null;
    });
    try {
      await ref.read(devBuildRepositoryProvider).confirmEngagement(widget.id);
      ref.invalidate(dbMyEngagementsProvider);
    } catch (e) {
      if (mounted) setState(() => _failure = e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final f = FlowStrings.of(context);
    final repo = ref.watch(devBuildRepositoryProvider);
    void back() => aqBack(context, '/app/account/workspace/engagements');
    return DbGuard(
      inShell: false,
      title: f.t('db.eng.title'),
      backFallback: '/app/account/workspace/engagements',
      builder: (context, a) {
        if (!repo.caps.engagements)
          return AQViewingScaffold(
            title: f.t('db.eng.title'),
            backLabel: f.t('common.back'),
            onBack: back,
            children: [DbNotice(f.t('db.eng.unavailable'), icon: 'lock')],
          );
        final async = ref.watch(dbMyEngagementsProvider);
        return async.when(
          loading: () => AQViewingScaffold(
            backLabel: f.t('common.back'),
            onBack: back,
            children: const [DbSkeleton(height: 140)],
          ),
          error: (e, _) => AQViewingScaffold(
            title: f.t('db.eng.title'),
            backLabel: f.t('common.back'),
            onBack: back,
            children: [
              DbErrorCard(
                error: e,
                onRetry: () => ref.invalidate(dbMyEngagementsProvider),
              ),
            ],
          ),
          data: (list) {
            final e = list.where((x) => x.id == widget.id).firstOrNull;
            if (e == null)
              return AQViewingScaffold(
                title: f.t('db.eng.title'),
                backLabel: f.t('common.back'),
                onBack: back,
                children: [DbNotice(f.t('db.eng.gone'), icon: 'info')],
              );
            final can = e.state == EngagementState.awaitingMyConfirmation;
            return AQViewingScaffold(
              title: f.t('db.eng.detail'),
              subtitle: VFmt.iso(e.clientLabel),
              backLabel: f.t('common.back'),
              onBack: back,
              bottom: can
                  ? AQBottomActionBar(
                      primary: AQPrimaryButton(
                        label: f.t('db.eng.confirm.cta'),
                        trailingChevron: false,
                        loading: _busy,
                        onPressed: _busy ? null : _confirm,
                      ),
                    )
                  : null,
              children: [
                _Timeline(state: e.state),
                const SizedBox(height: AQSpacing.x4),
                DbNotice(
                  f.t('db.eng.s.${e.state.name}.x'),
                  icon: e.state == EngagementState.confirmedByBoth
                      ? 'check'
                      : 'clock',
                ),
                if (e.confirmByDeadline != null)
                  Padding(
                    padding: const EdgeInsets.only(top: AQSpacing.x3),
                    child: Text(
                      f.t('db.eng.deadline', {
                        'd': VFmt.fullDate(context, e.confirmByDeadline!),
                      }),
                      style: AQTypography.of(context, AQText.bodyMedium),
                    ),
                  ),
                if (_failure != null)
                  Padding(
                    padding: const EdgeInsets.only(top: AQSpacing.x3),
                    child: DbErrorCard(
                      error: _failure,
                      onRetry: _busy ? null : _confirm,
                    ),
                  ),
                const SizedBox(height: AQSpacing.x3),
                Text(
                  f.t('db.eng.rules'),
                  style: AQTypography.of(context, AQText.bodySmall, soft: true),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

// ----------------------------------------------------- #86 portfolio

class DbPortfolioScreen extends ConsumerWidget {
  const DbPortfolioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final f = FlowStrings.of(context);
    final c = AQColors.of(context);
    final repo = ref.watch(devBuildRepositoryProvider);
    return DbGuard(
      title: f.t('db.pf.title'),
      backFallback: _wsBack,
      builder: (context, a) {
        if (a.type == ProType.developer) {
          return DbShellPage(
            title: f.t('db.pf.title'),
            onBack: () => aqBack(context, _wsBack),
            children: [DbNotice(f.t('db.pf.devNote'), icon: 'development')],
          );
        }
        final org = ref.watch(dbMyOrgProvider);
        return DbShellPage(
          eyebrow: f.t('db.ws.eyebrow'),
          title: f.t('db.pf.title'),
          subtitle: f.t('db.pf.sub'),
          onBack: () => aqBack(context, _wsBack),
          children: [
            org.when(
              loading: () => const DbSkeletonList(count: 1, height: 160),
              error: (e, _) => DbErrorCard(
                error: e,
                onRetry: () => ref.invalidate(dbMyOrgProvider),
              ),
              data: (o) {
                final media = o?.mediaUrls ?? const <String>[];
                if (media.isEmpty)
                  return DbNotice(f.t('db.pf.empty'), icon: 'work');
                return GridView.count(
                  crossAxisCount: aqLargeText(context) ? 1 : 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: AQSpacing.x2,
                  crossAxisSpacing: AQSpacing.x2,
                  children: [
                    for (final m in media)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AQRadius.medium),
                        child: aqImg(m, cacheWidth: 500),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: AQSpacing.x4),
            Semantics(
              button: true,
              enabled: false,
              label: '${f.t('db.pf.add')}. ${f.t('db.pf.off')}',
              excludeSemantics: true,
              child: Opacity(
                opacity: 0.55,
                child: Container(
                  padding: const EdgeInsets.all(AQSpacing.x4),
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: BorderRadius.circular(AQRadius.medium),
                    border: Border.all(color: c.hairline),
                  ),
                  child: Row(
                    children: [
                      DbIcon('plus', size: 22, color: c.inkSoft),
                      const SizedBox(width: AQSpacing.x3),
                      Expanded(
                        child: Text(
                          f.t('db.pf.add'),
                          style: AQTypography.of(context, AQText.titleSmall),
                        ),
                      ),
                      AQIcon('lock', size: 18, color: c.inkSoft),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: AQSpacing.x2),
            Text(
              f.t(repo.caps.portfolio ? 'db.pf.on' : 'db.pf.off'),
              style: AQTypography.of(context, AQText.bodySmall, soft: true),
            ),
            const SizedBox(height: AQSpacing.x1),
            Text(
              f.t('db.pf.proposed'),
              style: AQTypography.of(
                context,
                AQText.labelSmall,
                color: c.inkFaint,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Two-step progress for an engagement: your confirmation, then a review becoming possible.
class _Timeline extends StatelessWidget {
  final EngagementState state;
  const _Timeline({required this.state});

  @override
  Widget build(BuildContext context) {
    final c = AQColors.of(context);
    final f = FlowStrings.of(context);
    final youDone =
        state == EngagementState.awaitingClient ||
        state == EngagementState.confirmedByBoth;
    final bothDone = state == EngagementState.confirmedByBoth;
    Widget node(bool done, String label) => Expanded(
      child: Semantics(
        label: '$label: ${f.t(done ? 'db.eng.done' : 'db.eng.pending')}',
        excludeSemantics: true,
        child: Column(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done ? c.success : Colors.transparent,
                border: Border.all(
                  color: done ? c.success : c.hairline,
                  width: 1.5,
                ),
              ),
              child: done
                  ? Center(
                      child: AQIcon(
                        'check',
                        size: 16,
                        color: c.isDark ? c.background : Colors.white,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: AQSpacing.x2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: AQTypography.of(context, AQText.labelSmall, soft: !done),
            ),
          ],
        ),
      ),
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        node(youDone, f.t('db.eng.t.you')),
        Padding(
          padding: const EdgeInsets.only(top: 15),
          child: SizedBox(
            width: 40,
            child: Divider(
              color: youDone ? c.success : c.hairline,
              thickness: 2,
            ),
          ),
        ),
        node(bothDone, f.t('db.eng.t.review')),
      ],
    );
  }
}
