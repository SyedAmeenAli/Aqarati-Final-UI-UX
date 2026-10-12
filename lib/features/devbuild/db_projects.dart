import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/aq/aq_forms.dart';
import '../../core/aq/aq_primitives.dart';
import '../../core/aq/aq_scene.dart';
import '../../core/aq/aq_tokens.dart';
import '../../core/aq/aq_typography.dart';
import '../../core/config/backend_mode.dart';
import '../../core/localization/flow_strings.dart';
import '../search/aq_search.dart' show AQQueryField;
import '../viewing/widgets/viewing_format.dart';
import '../viewing/widgets/viewing_scaffold.dart';
import 'db_models.dart';
import 'db_repository.dart';
import 'db_widgets.dart';
import 'db_workspace.dart';

/// One idempotency key per submission attempt. Reused if the same attempt is retried.
String dbNewIdempotencyKey() =>
    'ik-${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(0x7fffffff)}';

// ----------------------------------------------------- #69 / #76 My Projects

class DbMyProjectsScreen extends ConsumerStatefulWidget {
  const DbMyProjectsScreen({super.key});
  @override
  ConsumerState<DbMyProjectsScreen> createState() => _DbMyProjectsScreenState();
}

class _DbMyProjectsScreenState extends ConsumerState<DbMyProjectsScreen> {
  final _ctl = TextEditingController();
  ProjectStatus? _status;

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  Future<void> _menu(DbProject p) async {
    final f = FlowStrings.of(context);
    await showAQSheet<void>(
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
              VFmt.iso(p.name),
              style: AQTypography.of(s, AQText.headlineSmall),
            ),
            const SizedBox(height: AQSpacing.x3),
            AQSecondaryButton(
              label: f.t('db.proj.view'),
              trailingChevron: false,
              onPressed: () {
                Navigator.of(s).pop();
                context.push('/workspace/projects/${p.id}');
              },
            ),
            if (p.status.canEdit) ...[
              const SizedBox(height: AQSpacing.x2),
              AQSecondaryButton(
                label: f.t('db.proj.edit'),
                trailingChevron: false,
                leadingIcon: 'edit',
                onPressed: () {
                  Navigator.of(s).pop();
                  context.push('/workspace/projects/${p.id}/edit');
                },
              ),
            ] else ...[
              const SizedBox(height: AQSpacing.x3),
              Text(
                f.t('db.proj.noEdit'),
                style: AQTypography.of(s, AQText.bodySmall, soft: true),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final f = FlowStrings.of(context);
    final c = AQColors.of(context);
    return DbGuard(
      developerOnly: true,
      title: f.t('db.proj.title'),
      eyebrow: f.t('db.proj.eyebrow'),
      backFallback: '/app/account/workspace',
      builder: (context, a) {
        final async = ref.watch(dbMyProjectsProvider);
        final q = _ctl.text.trim().toLowerCase();
        return DbShellPage(
          eyebrow: f.t('db.proj.eyebrow'),
          title: f.t('db.proj.title'),
          subtitle: f.t('db.proj.sub'),
          onBack: () => aqBack(context, '/app/account/workspace'),
          children: [
            AQPrimaryButton(
              label: f.t('db.ws.add'),
              leadingIcon: 'plus',
              trailingChevron: false,
              onPressed: () => context.push('/workspace/projects/new'),
            ),
            const SizedBox(height: AQSpacing.x4),
            AQQueryField(
              controller: _ctl,
              hint: f.t('db.proj.search'),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => setState(() {}),
            ),
            const SizedBox(height: AQSpacing.x3),
            DbPillRow(
              scroll: true,
              pills: [
                (
                  f.t('flt.all'),
                  _status == null,
                  () => setState(() => _status = null),
                ),
                for (final s in const [
                  ProjectStatus.approved,
                  ProjectStatus.underReview,
                  ProjectStatus.changesRequested,
                  ProjectStatus.rejected,
                  ProjectStatus.draft,
                ])
                  (
                    f.t(s.key),
                    _status == s,
                    () => setState(() => _status = _status == s ? null : s),
                  ),
              ],
            ),
            const SizedBox(height: AQSpacing.x4),
            async.when(
              loading: () => const DbSkeletonList(count: 3, height: 110),
              error: (e, _) => DbErrorCard(
                error: e,
                onRetry: () => ref.invalidate(dbMyProjectsProvider),
              ),
              data: (all) {
                if (all.isEmpty) {
                  return Column(
                    children: [
                      DbNotice(f.t('db.proj.empty'), icon: 'development'),
                      const SizedBox(height: AQSpacing.x3),
                      AQSecondaryButton(
                        label: f.t('db.ws.add'),
                        trailingChevron: false,
                        onPressed: () =>
                            context.push('/workspace/projects/new'),
                      ),
                    ],
                  );
                }
                final shown = [
                  for (final p in all)
                    if ((_status == null || p.status == _status) &&
                        (q.isEmpty ||
                            p.name.toLowerCase().contains(q) ||
                            p.locationLabel.toLowerCase().contains(q)))
                      p,
                ];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Semantics(
                      liveRegion: true,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: AQSpacing.x3),
                        child: Text(
                          dbProjectsCount(context, f, shown.length),
                          style: AQTypography.of(context, AQText.titleSmall),
                        ),
                      ),
                    ),
                    if (shown.isEmpty)
                      DbNotice(f.t('db.proj.noMatch'), icon: 'search')
                    else
                      for (final p in shown)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AQSpacing.x3),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              DbProjectCard(
                                project: p,
                                showStatus: true,
                                onTap: () =>
                                    context.push('/workspace/projects/${p.id}'),
                                trailing: AQIconButton(
                                  icon: 'more',
                                  semanticsLabel: f.t('db.proj.menu', {
                                    'n': p.name,
                                  }),
                                  directional: false,
                                  onPressed: () => _menu(p),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  AQSpacing.x3,
                                  AQSpacing.x1,
                                  AQSpacing.x3,
                                  0,
                                ),
                                child: Text(
                                  f.t(p.status.explainKey),
                                  style: AQTypography.of(
                                    context,
                                    AQText.bodySmall,
                                    color: c.inkSoft,
                                  ),
                                ),
                              ),
                            ],
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

// --------------------------------------------- #76 status, #82 feedback

class DbProjectStatusScreen extends ConsumerStatefulWidget {
  final String id;
  const DbProjectStatusScreen({super.key, required this.id});
  @override
  ConsumerState<DbProjectStatusScreen> createState() =>
      _DbProjectStatusScreenState();
}

class _DbProjectStatusScreenState extends ConsumerState<DbProjectStatusScreen> {
  bool _busy = false;
  String? _key;
  Object? _error;

  Future<void> _resubmit(DbProject p) async {
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
              f.t('db.resub.t'),
              style: AQTypography.of(s, AQText.headlineSmall),
            ),
            const SizedBox(height: AQSpacing.x2),
            Text(
              f.t('db.resub.b'),
              style: AQTypography.of(s, AQText.bodyMedium, soft: true),
            ),
            const SizedBox(height: AQSpacing.x4),
            AQPrimaryButton(
              label: f.t('db.resub.cta'),
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
      _error = null;
    });
    try {
      _key ??= dbNewIdempotencyKey();
      await ref
          .read(devBuildRepositoryProvider)
          .resubmitProject(p.id, idempotencyKey: _key!);
      ref.invalidate(dbMyProjectsProvider);
      ref.invalidate(dbMyProjectProvider(p.id));
      if (mounted)
        context.go('/workspace/projects/${p.id}/submitted?r=resubmitted');
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _row(BuildContext context, String k, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
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

  @override
  Widget build(BuildContext context) {
    final f = FlowStrings.of(context);
    final c = AQColors.of(context);
    void back() => aqBack(context, '/app/account/workspace/projects');
    return DbGuard(
      developerOnly: true,
      inShell: false,
      title: f.t('db.proj.title'),
      backFallback: '/app/account/workspace/projects',
      builder: (context, a) {
        final async = ref.watch(dbMyProjectProvider(widget.id));
        return async.when(
          loading: () => AQViewingScaffold(
            backLabel: f.t('common.back'),
            onBack: back,
            children: const [
              DbSkeleton(height: 100),
              SizedBox(height: AQSpacing.x3),
              DbSkeleton(height: 160),
            ],
          ),
          error: (e, _) => AQViewingScaffold(
            title: f.t(
              e is PermissionDeniedException ? 'db.denied.t' : 'db.proj.title',
            ),
            backLabel: f.t('common.back'),
            onBack: back,
            children: [
              DbErrorCard(
                error: e,
                onRetry: () => ref.invalidate(dbMyProjectProvider(widget.id)),
              ),
            ],
          ),
          data: (p) {
            final repo = ref.read(devBuildRepositoryProvider);
            final fb = p.reviewerFeedback;
            return AQViewingScaffold(
              title: VFmt.iso(p.name),
              subtitle: p.locationLabel.isEmpty ? null : p.locationLabel,
              backLabel: f.t('common.back'),
              onBack: back,
              bottom: p.status.canEdit || p.status.canResubmit
                  ? AQBottomActionBar(
                      stack: true,
                      primary: AQPrimaryButton(
                        label: f.t(
                          p.status == ProjectStatus.draft
                              ? 'db.proj.continue'
                              : 'db.proj.edit',
                        ),
                        trailingChevron: false,
                        leadingIcon: 'edit',
                        onPressed: _busy
                            ? null
                            : () => context.push(
                                '/workspace/projects/${p.id}/edit',
                              ),
                      ),
                      secondary: p.status == ProjectStatus.changesRequested
                          ? AQBarSecondaryButton(
                              label: f.t('db.resub.cta'),
                              onPressed: _busy ? null : () => _resubmit(p),
                            )
                          : null,
                      footnote: p.status == ProjectStatus.approved
                          ? f.t('db.proj.materialNote')
                          : null,
                    )
                  : null,
              children: [
                DbStatusBanner(status: p.status, rawStatus: p.rawStatus),
                if (_error != null) ...[
                  const SizedBox(height: AQSpacing.x3),
                  DbErrorCard(error: _error, onRetry: () => _resubmit(p)),
                ],
                if (p.status == ProjectStatus.changesRequested ||
                    p.status == ProjectStatus.rejected) ...[
                  const SizedBox(height: AQSpacing.x5),
                  Text(
                    f.t('db.fb.title'),
                    style: AQTypography.of(context, AQText.headlineSmall),
                  ),
                  const SizedBox(height: AQSpacing.x2),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AQSpacing.x4),
                    decoration: BoxDecoration(
                      color: c.surfaceRaised,
                      borderRadius: BorderRadius.circular(AQRadius.medium),
                      border: Border.all(color: c.hairline),
                    ),
                    child: Semantics(
                      label:
                          '${f.t('db.fb.title')}: ${fb ?? f.t('db.fb.none')}',
                      excludeSemantics: true,
                      child: Text(
                        fb ?? f.t('db.fb.none'),
                        style: AQTypography.of(context, AQText.bodyMedium),
                      ),
                    ),
                  ),
                  const SizedBox(height: AQSpacing.x2),
                  Text(
                    f.t('db.fb.note'),
                    style: AQTypography.of(
                      context,
                      AQText.bodySmall,
                      soft: true,
                    ),
                  ),
                ],
                const SizedBox(height: AQSpacing.x5),
                Text(
                  f.t('db.proj.details'),
                  style: AQTypography.of(context, AQText.headlineSmall),
                ),
                const SizedBox(height: AQSpacing.x2),
                _row(
                  context,
                  f.t('db.fact.type'),
                  dbTypeLabel(f, p.propertyType),
                ),
                if (p.bedrooms != null)
                  _row(context, f.t('db.f.beds'), VFmt.n(context, p.bedrooms!)),
                if (p.bathrooms != null)
                  _row(
                    context,
                    f.t('db.f.baths'),
                    VFmt.n(context, p.bathrooms!),
                  ),
                if (p.areaSqm != null)
                  _row(
                    context,
                    f.t('db.fact.built'),
                    '${VFmt.n(context, p.areaSqm!.round())} m²',
                  ),
                if (p.landSqm != null)
                  _row(
                    context,
                    f.t('db.fact.land'),
                    '${VFmt.n(context, p.landSqm!.round())} m²',
                  ),
                if (p.locationLabel.isNotEmpty)
                  _row(context, f.t('db.location'), p.locationLabel),
                if (p.status == ProjectStatus.changesRequested ||
                    p.status == ProjectStatus.underReview) ...[
                  const SizedBox(height: AQSpacing.x5),
                  DbNotice(
                    f.t(
                      p.status == ProjectStatus.changesRequested
                          ? 'db.next.changes'
                          : 'db.next.review',
                    ),
                    icon: 'info',
                  ),
                ],
                if (kShowReviewTools && repo is DemoDevBuildRepository) ...[
                  const SizedBox(height: AQSpacing.x6),
                  DbNotice(f.t('common.demo'), icon: 'info'),
                  const SizedBox(height: AQSpacing.x2),
                  Wrap(
                    spacing: AQSpacing.x2,
                    runSpacing: AQSpacing.x2,
                    children: [
                      for (final d in [
                        (ProjectStatus.approved, null),
                        (
                          ProjectStatus.changesRequested,
                          'Please add the land title reference and confirm the built-up area.',
                        ),
                        (
                          ProjectStatus.rejected,
                          'Not approved: the project could not be matched to a licensed development.',
                        ),
                      ])
                        AQSecondaryButton(
                          label: 'Simulate: ${d.$1.name}',
                          compact: true,
                          trailingChevron: false,
                          onPressed: () {
                            repo.debugDecide(p.id, d.$1, feedback: d.$2);
                            ref.invalidate(dbMyProjectProvider(p.id));
                            ref.invalidate(dbMyProjectsProvider);
                          },
                        ),
                    ],
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }
}

// ------------------------------------------------------- #75 confirmation

class DbSubmittedScreen extends ConsumerWidget {
  final String id;
  final String result;
  const DbSubmittedScreen({
    super.key,
    required this.id,
    this.result = 'submitted',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final f = FlowStrings.of(context);
    final c = AQColors.of(context);
    return DbGuard(
      developerOnly: true,
      inShell: false,
      title: f.t('db.proj.title'),
      backFallback: '/app/account/workspace/projects',
      builder: (context, a) {
        final async = ref.watch(dbMyProjectProvider(id));
        void toList() => context.go('/app/account/workspace/projects');
        return async.when(
          loading: () => AQViewingScaffold(
            showBack: false,
            backLabel: f.t('common.back'),
            children: const [DbSkeleton(height: 200)],
          ),
          error: (e, _) => AQViewingScaffold(
            backLabel: f.t('common.back'),
            onBack: toList,
            children: [
              DbErrorCard(
                error: e,
                onRetry: () => ref.invalidate(dbMyProjectProvider(id)),
              ),
            ],
          ),
          data: (p) {
            // The headline follows the status the server returned, never the button that was tapped.
            final key = switch (p.status) {
              ProjectStatus.underReview => 'db.done.review',
              ProjectStatus.draft => 'db.done.draft',
              _ => 'db.done.other',
            };
            return AQViewingScaffold(
              emotional: true,
              showBack: false,
              backLabel: f.t('common.back'),
              title: f.t('$key.t'),
              subtitle: f.t('$key.b', {'n': p.name, 's': f.t(p.status.key)}),
              bottom: AQBottomActionBar(
                stack: true,
                primary: AQPrimaryButton(
                  label: f.t('db.done.toList'),
                  trailingChevron: false,
                  onPressed: toList,
                ),
                secondary: AQBarSecondaryButton(
                  label: f.t('db.done.view'),
                  onPressed: () => context.go('/workspace/projects/${p.id}'),
                ),
              ),
              children: [
                Center(child: AQAnimatedCheck(size: 72)),
                const SizedBox(height: AQSpacing.x5),
                Container(
                  padding: const EdgeInsets.all(AQSpacing.x4),
                  decoration: BoxDecoration(
                    color: c.surfaceRaised,
                    borderRadius: BorderRadius.circular(AQRadius.medium),
                    border: Border.all(color: c.hairline),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        VFmt.iso(p.name),
                        style: AQTypography.of(context, AQText.headlineSmall),
                      ),
                      if (p.locationLabel.isNotEmpty)
                        Text(
                          p.locationLabel,
                          style: AQTypography.of(
                            context,
                            AQText.bodySmall,
                            soft: true,
                          ),
                        ),
                      const SizedBox(height: AQSpacing.x3),
                      DbStatusChip(status: p.status, rawStatus: p.rawStatus),
                    ],
                  ),
                ),
                const SizedBox(height: AQSpacing.x3),
                AQSecondaryButton(
                  label: f.t('db.done.another'),
                  trailingChevron: false,
                  leadingIcon: 'plus',
                  onPressed: () => context.go('/workspace/projects/new'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
