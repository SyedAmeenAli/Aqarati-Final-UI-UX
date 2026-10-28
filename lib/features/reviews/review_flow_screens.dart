import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show LengthLimitingTextInputFormatter;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/aq/aq_forms.dart';
import '../../core/aq/aq_primitives.dart';
import '../../core/aq/aq_scene.dart';
import '../../core/aq/aq_status.dart';
import '../../core/aq/aq_tokens.dart';
import '../../core/aq/aq_typography.dart';
import '../../core/config/backend_mode.dart';
import '../../core/localization/flow_strings.dart';
import '../devbuild/db_widgets.dart' show DbErrorCard, DbNotice;
import '../viewing/domain/viewing_presentation.dart' show AQTone;
import '../viewing/screens/viewing_kit.dart'
    show AQViewingSectionTitle, AQViewingSkeleton;
import '../viewing/widgets/viewing_components.dart';
import '../viewing/widgets/viewing_format.dart';
import '../viewing/widgets/viewing_scaffold.dart';
import 'review_models.dart';
import 'review_repository.dart';

(AQTone, String) _look(ReviewStatus s) => switch (s) {
  ReviewStatus.pendingModeration => (AQTone.pending, 'clock'),
  ReviewStatus.published => (AQTone.success, 'check'),
  ReviewStatus.underReview => (AQTone.warning, 'alert'),
  ReviewStatus.removed => (AQTone.danger, 'close'),
  ReviewStatus.rejected => (AQTone.danger, 'close'),
};

Widget reviewStatusPill(FlowStrings f, ReviewStatus s) {
  final (tone, icon) = _look(s);
  return AQStatusPill(
    label: f.t('rv.st.${s.name}'),
    tone: tone,
    icon: icon,
    dense: true,
  );
}

class StarsInput extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  const StarsInput({super.key, required this.value, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    final f = FlowStrings.of(context);
    final c = AQColors.of(context);
    return Row(
      children: [
        for (var i = 1; i <= 5; i++)
          Semantics(
            button: true,
            focusable: true,
            onFocus: () {},
            selected: value == i,
            label: f.t('rv.star', {'n': '$i'}),
            excludeSemantics: true,
      onTap: () => onChanged(i),
            child: AQPressable(
              onTap: () => onChanged(i),
              child: SizedBox(
                width: AQControl.tap,
                height: AQControl.tap,
                child: Center(
                  child: AQIcon(
                    i <= value ? 'star-fill' : 'star',
                    size: 28,
                    color: i <= value ? c.warning : c.inkFaint,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ------------------------------------------------------------------ write / edit

class WriteReviewScreen extends ConsumerStatefulWidget {
  final ReviewTargetKind kind;
  final String id, name;
  const WriteReviewScreen({
    super.key,
    required this.kind,
    required this.id,
    required this.name,
  });
  @override
  ConsumerState<WriteReviewScreen> createState() => _WriteState();
}

class _WriteState extends ConsumerState<WriteReviewScreen> {
  final _comment = TextEditingController();
  int _rating = 0;
  bool _preview = false, _tried = false, _saving = false, _editing = false;
  bool _filled = false;
  String? _failKey, _doneKey;

  ReviewTarget get _target =>
      ReviewTarget(kind: widget.kind, id: widget.id, name: widget.name);

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  String? get _eRating => _rating == 0 ? 'rv.err.rating' : null;
  String? get _eComment => reviewCommentError(_comment.text);

  void _goPreview() {
    setState(() => _tried = true);
    if (_eRating != null || _eComment != null) return;
    FocusScope.of(context).unfocus();
    setState(() => _preview = true);
  }

  Future<void> _submit(MyReview? existing) async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _failKey = null;
    });
    try {
      final repo = ref.read(reviewRepositoryProvider);
      if (existing != null && _editing) {
        await repo.edit(
          id: existing.id,
          rating: _rating,
          comment: _comment.text,
        );
      } else {
        await repo.submit(
          target: _target,
          rating: _rating,
          comment: _comment.text,
        );
      }
      final wasEdit = existing != null && _editing;
      ref.invalidate(reviewEligibilityProvider(_target));
      ref.invalidate(myReviewsProvider);
      if (mounted) {
        setState(() {
          _preview = false;
          _editing = false;
          _filled = false;
          _doneKey = wasEdit ? 'rv.edit.sent' : 'rv.sent.t';
        });
      }
    } on ReviewNotEligibleException {
      if (mounted) setState(() => _failKey = 'rv.notEligible.fail');
    } catch (_) {
      if (mounted) setState(() => _failKey = 'rv.fail');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final f = FlowStrings.of(context);
    final c = AQColors.of(context);
    void back() => aqBack(context, '/business/${widget.id}');
    Widget shell(List<Widget> children, {Widget? bottom}) => AQViewingScaffold(
      title: f.t('rv.write.title'),
      subtitle: f.t('rv.write.sub', {'name': VFmt.iso(widget.name)}),
      backLabel: f.t('common.back'),
      onBack: back,
      bottom: bottom,
      children: children,
    );
    return ref
        .watch(reviewEligibilityProvider(_target))
        .when(
          loading: () => shell(const [AQViewingSkeleton(height: 120)]),
          error: (e, _) => shell([
            DbErrorCard(
              error: e,
              onRetry: () => ref.invalidate(reviewEligibilityProvider(_target)),
            ),
          ]),
          data: (el) {
            final backBar = AQBottomActionBar(
              primary: AQPrimaryButton(
                label: f.t('rv.back'),
                trailingChevron: false,
                onPressed: back,
              ),
            );
            switch (el.kind) {
              case ReviewEligibilityKind.signedOut:
                return shell(
                  [
                    AQNoticeCard(
                      icon: 'lock',
                      title: f.t('rv.signin.t'),
                      body: '',
                    ),
                  ],
                  bottom: AQBottomActionBar(
                    primary: AQPrimaryButton(
                      label: f.t('ce.req.login'),
                      trailingChevron: false,
                      onPressed: () => context.push('/login'),
                    ),
                  ),
                );
              case ReviewEligibilityKind.notYetEligible:
                return shell([
                  AQNoticeCard(
                    icon: 'clock',
                    title: f.t('rv.notYet.t'),
                    body: f.t('rv.notYet.b'),
                    tone: AQTone.pending,
                  ),
                ], bottom: backBar);
              case ReviewEligibilityKind.notEligible:
                return shell(
                  [
                    AQNoticeCard(
                      icon: 'info',
                      title: f.t('rv.notEligible.t'),
                      body: f.t('rv.notEligible.b'),
                    ),
                  ],
                  bottom: widget.kind == ReviewTargetKind.professional
                      ? AQBottomActionBar(
                          primary: AQPrimaryButton(
                            label: f.t('rv.cta.engage'),
                            trailingChevron: false,
                            onPressed: () =>
                                context.push('/business/${widget.id}/engage'),
                          ),
                        )
                      : backBar,
                );
              case ReviewEligibilityKind.windowExpired:
                return shell([
                  AQNoticeCard(
                    icon: 'clock',
                    title: f.t('rv.expired.t'),
                    body: f.t('rv.expired.b'),
                  ),
                ], bottom: backBar);
              case ReviewEligibilityKind.alreadyReviewed:
              case ReviewEligibilityKind.eligible:
                break;
            }
            final existing = el.existing;
            // The review as it stands (or just sent): status, and an edit only if the service allows it.
            if (existing != null && !_editing) {
              return shell(
                [
                  if (_doneKey != null)
                    AQErrorBanner(
                      tone: AQBannerTone.success,
                      text: '${f.t(_doneKey!)}. ${f.t('rv.sent.b')}',
                    ),
                  AQNoticeCard(
                    icon: _look(existing.status).$2,
                    title: f.t('rv.st.${existing.status.name}'),
                    body: f.t('rv.ex.${existing.status.name}'),
                    tone: _look(existing.status).$1,
                  ),
                  AQViewingSectionTitle(f.t('rv.existing.t')),
                  AQSurface(
                    padding: const EdgeInsets.all(AQSpacing.x4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            for (var i = 1; i <= 5; i++)
                              AQIcon(
                                i <= existing.rating ? 'star-fill' : 'star',
                                size: 18,
                                color: i <= existing.rating
                                    ? c.warning
                                    : c.inkFaint,
                              ),
                          ],
                        ),
                        const SizedBox(height: AQSpacing.x2),
                        Text(
                          existing.comment,
                          style: AQTypography.of(context, AQText.bodyMedium),
                        ),
                      ],
                    ),
                  ),
                  if (!existing.canEdit)
                    Padding(
                      padding: const EdgeInsets.only(top: AQSpacing.x3),
                      child: DbNotice(f.t('rv.edit.locked'), icon: 'lock'),
                    ),
                  const SizedBox(height: AQSpacing.x4),
                  if (kUseDemoBackend) DbNotice(f.t('rv.demo'), icon: 'info'),
                  if (kShowReviewTools) _QaModeration(existing, _target),
                ],
                bottom: existing.canEdit
                    ? AQBottomActionBar(
                        primary: AQPrimaryButton(
                          label: f.t('rv.edit'),
                          trailingChevron: false,
                          onPressed: () => setState(() {
                            _editing = true;
                            _rating = existing.rating;
                            _comment.text = existing.comment;
                            _filled = true;
                            _doneKey = null;
                          }),
                        ),
                      )
                    : backBar,
              );
            }
            if (!_filled && existing != null) _filled = true;
            if (_preview) {
              return shell(
                [
                  if (_failKey != null) AQErrorBanner(text: f.t(_failKey!)),
                  AQViewingSectionTitle(f.t('rv.preview.title')),
                  AQSurface(
                    padding: const EdgeInsets.all(AQSpacing.x4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            for (var i = 1; i <= 5; i++)
                              AQIcon(
                                i <= _rating ? 'star-fill' : 'star',
                                size: 20,
                                color: i <= _rating ? c.warning : c.inkFaint,
                              ),
                          ],
                        ),
                        const SizedBox(height: AQSpacing.x2),
                        Text(
                          _comment.text.trim(),
                          style: AQTypography.of(context, AQText.bodyMedium),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AQSpacing.x3),
                  DbNotice(f.t('rv.preview.note'), icon: 'info'),
                  const SizedBox(height: AQSpacing.x4),
                  if (kUseDemoBackend) DbNotice(f.t('rv.demo'), icon: 'info'),
                ],
                bottom: AQBottomActionBar(
                  primary: AQPrimaryButton(
                    label: f.t('rv.submit'),
                    trailingChevron: false,
                    loading: _saving,
                    onPressed: _saving ? null : () => _submit(existing),
                  ),
                  secondary: AQBarSecondaryButton(
                    label: f.t('rv.preview.edit'),
                    onPressed: _saving
                        ? null
                        : () => setState(() => _preview = false),
                  ),
                ),
              );
            }
            String? txt(String? k) => _tried && k != null ? f.t(k) : null;
            return shell(
              [
                if (_failKey != null) AQErrorBanner(text: f.t(_failKey!)),
                if (el.windowEndsAt != null)
                  DbNotice(
                    f.t('rv.window', {
                      'd': VFmt.fullDate(context, el.windowEndsAt!),
                    }),
                    icon: 'clock',
                  ),
                AQViewingSectionTitle(f.t('rv.stars')),
                StarsInput(
                  value: _rating,
                  onChanged: (v) => setState(() => _rating = v),
                ),
                if (txt(_eRating) != null)
                  Text(
                    txt(_eRating)!,
                    style: AQTypography.of(
                      context,
                      AQText.bodySmall,
                      color: c.danger,
                    ),
                  ),
                const SizedBox(height: AQSpacing.x3),
                AQTextField(
                  label: f.t('rv.comment'),
                  hint: f.t('rv.comment.hint'),
                  controller: _comment,
                  minLines: 4,
                  maxLines: 8,
                  keyboardType: TextInputType.multiline,
                  action: TextInputAction.newline,
                  formatters: [
                    LengthLimitingTextInputFormatter(kReviewMaxChars + 50),
                  ],
                  error: txt(_eComment),
                  onChanged: (_) => setState(() {}),
                ),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: Text(
                    f.t('rv.count', {'n': '${_comment.text.trim().length}'}),
                    style: AQTypography.of(
                      context,
                      AQText.bodySmall,
                      soft: true,
                    ),
                  ),
                ),
                const SizedBox(height: AQSpacing.x4),
                if (kUseDemoBackend) DbNotice(f.t('rv.demo'), icon: 'info'),
              ],
              bottom: AQBottomActionBar(
                primary: AQPrimaryButton(
                  label: f.t('rv.preview'),
                  trailingChevron: false,
                  onPressed: _goPreview,
                ),
              ),
            );
          },
        );
  }
}

/// QA only (`REVIEW_TOOLS`): stands in for moderation. Never in a production build.
class _QaModeration extends ConsumerWidget {
  final MyReview r;
  final ReviewTarget target;
  const _QaModeration(this.r, this.target);
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(reviewRepositoryProvider);
    if (repo is! DemoReviewRepository) return const SizedBox.shrink();
    void set({ReviewStatus? status, bool? canEdit}) {
      repo.debugSet(r.id, status: status, canEdit: canEdit);
      ref.invalidate(reviewEligibilityProvider(target));
      ref.invalidate(myReviewsProvider);
    }

    return Padding(
      padding: const EdgeInsets.only(top: AQSpacing.x4),
      child: AQSurface(
        padding: const EdgeInsets.all(AQSpacing.x3),
        child: Wrap(
          spacing: AQSpacing.x2,
          children: [
            Text(
              'QA only: simulate moderation',
              style: AQTypography.of(context, AQText.labelMedium, soft: true),
            ),
            AQTextButton(
              label: 'Reviewer publishes',
              onPressed: () => set(status: ReviewStatus.published),
            ),
            AQTextButton(
              label: 'Reviewer rejects',
              onPressed: () => set(status: ReviewStatus.rejected),
            ),
            AQTextButton(
              label: 'Reviewer removes',
              onPressed: () => set(status: ReviewStatus.removed),
            ),
            AQTextButton(
              label: 'Allow editing',
              onPressed: () => set(canEdit: true),
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------ my reviews

class MyReviewsScreen extends ConsumerWidget {
  const MyReviewsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final f = FlowStrings.of(context);
    void back() => aqBack(context, '/app/account');
    return AQViewingScaffold(
      title: f.t('rv.mine.title'),
      backLabel: f.t('common.back'),
      onBack: back,
      children: [
        ref
            .watch(myReviewsProvider)
            .when(
              loading: () => const AQViewingSkeleton(height: 96),
              error: (e, _) => DbErrorCard(
                error: e,
                onRetry: () => ref.invalidate(myReviewsProvider),
              ),
              data: (list) => list.isEmpty
                  ? AQEmptyViewingState(
                      title: f.t('rv.mine.empty.t'),
                      body: f.t('rv.mine.empty.b'),
                    )
                  : Column(
                      children: [
                        for (final r in list)
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: AQSpacing.x3,
                            ),
                            child: Semantics(
                              button: true,
                              focusable: true,
                              onFocus: () {},
                              label:
                                  '${r.target.name}, ${f.t('rv.st.${r.status.name}')}',
                              excludeSemantics: true,
      onTap: () => context.push(
                                  '/review/${r.target.kind.name}/${r.target.id}?name=${Uri.encodeComponent(r.target.name)}',
                                ),
                              child: AQPressable(
                                onTap: () => context.push(
                                  '/review/${r.target.kind.name}/${r.target.id}?name=${Uri.encodeComponent(r.target.name)}',
                                ),
                                child: AQSurface(
                                  padding: const EdgeInsets.all(AQSpacing.x4),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        VFmt.iso(r.target.name),
                                        style: AQTypography.of(
                                          context,
                                          AQText.titleSmall,
                                        ),
                                      ),
                                      Text(
                                        '${r.rating}/5',
                                        style: AQTypography.of(
                                          context,
                                          AQText.bodySmall,
                                          soft: true,
                                        ),
                                      ),
                                      const SizedBox(height: AQSpacing.x2),
                                      reviewStatusPill(f, r.status),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
        const SizedBox(height: AQSpacing.x4),
        if (kUseDemoBackend) DbNotice(f.t('rv.demo'), icon: 'info'),
      ],
    );
  }
}

// ------------------------------------------------------------------ report

/// Opens the "report this review" sheet. Nothing about the review changes until a reviewer decides.
Future<void> showReportReviewSheet(
  BuildContext context,
  WidgetRef ref,
  String reviewId,
) {
  return showAQSheet<void>(
    context,
    useRootNavigator: true,
    builder: (s) => _ReportSheet(reviewId: reviewId, ref: ref),
  );
}

class _ReportSheet extends StatefulWidget {
  final String reviewId;
  final WidgetRef ref;
  const _ReportSheet({required this.reviewId, required this.ref});
  @override
  State<_ReportSheet> createState() => _ReportState();
}

class _ReportState extends State<_ReportSheet> {
  ReportReason? _reason;
  final _note = TextEditingController();
  bool _busy = false, _tried = false, _sent = false;
  String? _errKey;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() => _tried = true);
    if (_reason == null || _busy) return;
    setState(() {
      _busy = true;
      _errKey = null;
    });
    try {
      await widget.ref
          .read(reviewRepositoryProvider)
          .report(
            reviewId: widget.reviewId,
            reason: _reason!,
            note: _note.text,
          );
      if (mounted) setState(() => _sent = true);
    } on ReviewAlreadyReportedException {
      if (mounted) setState(() => _errKey = 'rp.already');
    } catch (_) {
      if (mounted) setState(() => _errKey = 'rp.fail');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final f = FlowStrings.of(context);
    final c = AQColors.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AQSpacing.gutter,
        AQSpacing.x2,
        AQSpacing.gutter,
        AQSpacing.x4 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: _sent
            ? Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      f.t('rp.sent.t'),
                      style: AQTypography.of(context, AQText.headlineSmall),
                    ),
                  ),
                  const SizedBox(height: AQSpacing.x2),
                  Text(
                    f.t('rp.sent.b'),
                    style: AQTypography.of(
                      context,
                      AQText.bodyMedium,
                      soft: true,
                    ),
                  ),
                  const SizedBox(height: AQSpacing.x4),
                  AQPrimaryButton(
                    label: f.t('rp.close'),
                    trailingChevron: false,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      f.t('rp.title'),
                      style: AQTypography.of(context, AQText.headlineSmall),
                    ),
                  ),
                  const SizedBox(height: AQSpacing.x1),
                  Text(
                    f.t('rp.sub'),
                    style: AQTypography.of(
                      context,
                      AQText.bodySmall,
                      soft: true,
                    ),
                  ),
                  const SizedBox(height: AQSpacing.x3),
                  if (_errKey != null) AQErrorBanner(text: f.t(_errKey!)),
                  for (final r in ReportReason.values)
                    Semantics(
                      button: true,
                      focusable: true,
                      onFocus: () {},
                      selected: _reason == r,
                      label: f.t('rp.r.${r.name}'),
                      excludeSemantics: true,
      onTap: () => setState(() => _reason = r),
                      child: AQPressable(
                        onTap: () => setState(() => _reason = r),
                        child: Container(
                          constraints: const BoxConstraints(
                            minHeight: AQControl.tap,
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: AQSpacing.x2,
                          ),
                          child: Row(
                            children: [
                              AQIcon(
                                _reason == r ? 'check' : 'chevron-right',
                                size: 18,
                                color: _reason == r ? c.accent : c.inkFaint,
                              ),
                              const SizedBox(width: AQSpacing.x2),
                              Expanded(
                                child: Text(
                                  f.t('rp.r.${r.name}'),
                                  style: AQTypography.of(
                                    context,
                                    AQText.bodyMedium,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  if (_tried && _reason == null)
                    Text(
                      f.t('rp.err.reason'),
                      style: AQTypography.of(
                        context,
                        AQText.bodySmall,
                        color: c.danger,
                      ),
                    ),
                  const SizedBox(height: AQSpacing.x2),
                  AQTextField(
                    label: f.t('rp.note'),
                    controller: _note,
                    minLines: 2,
                    maxLines: 4,
                    keyboardType: TextInputType.multiline,
                    action: TextInputAction.newline,
                  ),
                  const SizedBox(height: AQSpacing.x3),
                  AQPrimaryButton(
                    label: f.t('rp.send'),
                    trailingChevron: false,
                    loading: _busy,
                    onPressed: _busy ? null : _send,
                  ),
                ],
              ),
      ),
    );
  }
}
