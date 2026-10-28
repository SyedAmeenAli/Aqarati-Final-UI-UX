import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/aq/aq_forms.dart';
import '../core/aq/aq_primitives.dart';
import '../core/aq/aq_tokens.dart';
import '../core/aq/aq_typography.dart';
import '../features/ads/ad_models.dart';
import '../features/ads/ad_repository.dart';
import '../features/ads/sponsored_banner.dart';
import '../features/devbuild/db_widgets.dart' show DbFieldFrame, DbPillRow;
import '../features/flow/state/document_state.dart' show documentPickerProvider;
import '../features/viewing/domain/viewing_presentation.dart' show AQTone;
import '../features/viewing/widgets/viewing_format.dart';
import 'admin_auth.dart';
import 'admin_directory.dart' show adminLog, decisionVerb;
import 'admin_models.dart';
import 'admin_repository.dart';
import 'admin_widgets.dart';

String adStatusLabel(AdStatus s) => switch (s) {
  AdStatus.draft => 'Draft',
  AdStatus.pendingVerification => 'Waiting for review',
  AdStatus.approved => 'Live',
  AdStatus.resubmissionRequired => 'Changes requested',
  AdStatus.rejected => 'Rejected',
  AdStatus.paused => 'Paused',
  AdStatus.expired => 'Expired',
};

(AQTone, String) adStatusLook(AdStatus s) => switch (s) {
  AdStatus.draft => (AQTone.neutral, 'edit'),
  AdStatus.pendingVerification => (AQTone.pending, 'clock'),
  AdStatus.approved => (AQTone.success, 'check'),
  AdStatus.resubmissionRequired => (AQTone.warning, 'refresh'),
  AdStatus.rejected => (AQTone.danger, 'close'),
  AdStatus.paused => (AQTone.neutral, 'clock'),
  AdStatus.expired => (AQTone.warning, 'clock'),
};

String placementLabel(AdPlacement p) =>
    p == AdPlacement.homeTop ? 'Home, top' : 'Search results';

String audienceLabel(AdAudience a) => switch (a) {
  AdAudience.customer => 'User to Shop',
  AdAudience.agent => 'Real Estate Agent',
  AdAudience.developer => 'Development',
  AdAudience.construction => 'Construction',
  AdAudience.architecture => 'Architecture',
  AdAudience.interior => 'Interior & Exterior',
};

String audiencesText(Set<AdAudience> s) => AdAudience.values
    .where(s.contains)
    .map(audienceLabel)
    .join(', ');

/// What a tap on the banner would do, in words. Used by the preview so a bad destination is
/// visible before the banner is saved.
String destinationOutcome(String destination) {
  final d = destination.trim();
  if (d.isEmpty) return 'No destination yet.';
  if (!destinationValid(d)) {
    return 'This destination is not valid, so the banner could not be saved.';
  }
  final route = adInAppRoute(d);
  if (route == null) return 'Opens the external address $d in a new tab.';
  if (route != d) {
    return 'The app does not have a screen at $d. A tap would open $route instead.';
  }
  return 'Opens the app screen $d.';
}

/// Sample figures only, derived from the banner id so they stay the same between visits.
(int, int) sampleFigures(String id) {
  final n = id.codeUnits.fold<int>(11, (a, b) => (a * 31 + b) % 9000);
  final views = 1200 + n;
  return (views, (views * (0.02 + (n % 7) / 200)).round());
}

String _schedule(BuildContext context, SponsoredAd a) {
  if (a.startsAt == null && a.endsAt == null) return 'No schedule';
  String d(DateTime? x) => x == null ? 'open' : VFmt.shortDate(context, x);
  return '${d(a.startsAt)} to ${d(a.endsAt)}';
}

// ------------------------------------------------------------------ list

class AdsListScreen extends ConsumerStatefulWidget {
  const AdsListScreen({super.key});
  @override
  ConsumerState<AdsListScreen> createState() => _AdsListScreenState();
}

class _AdsListScreenState extends ConsumerState<AdsListScreen> {
  String? _busyId, _error, _done;
  AdStatus? _filter;
  AdAudience? _audience;
  final _q = TextEditingController();

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  Future<void> _run(
    String id,
    Future<Object?> Function(AdAdminRepository r) op,
    String done,
  ) async {
    if (_busyId != null) return;
    setState(() {
      _busyId = id;
      _error = null;
      _done = null;
    });
    try {
      await op(ref.read(adAdminRepositoryProvider));
      adminLog(ref, 'Banner: $done', id);
      ref.invalidate(adminAdsProvider);
      ref.invalidate(adminAdProvider(id));
      if (mounted) setState(() => _done = done);
    } catch (e) {
      if (!endSessionIfExpired(ref, e) && mounted) {
        setState(() => _error = adminErrorText(e));
      }
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _move(List<SponsoredAd> all, SponsoredAd ad, int delta) async {
    final same = all.where((a) => a.placement == ad.placement).toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    final i = same.indexWhere((a) => a.id == ad.id);
    final j = i + delta;
    if (i < 0 || j < 0 || j >= same.length) return;
    final ids = [for (final a in same) a.id];
    final t = ids.removeAt(i);
    ids.insert(j, t);
    await _run(ad.id, (r) => r.reorder(ids), 'Order updated.');
  }

  @override
  Widget build(BuildContext context) {
    final c = AQColors.of(context);
    final role =
        ref.watch(adminAuthProvider).session?.role ?? AdminRole.auditor;
    final async = ref.watch(adminAdsProvider);
    return AdminFrame(
      section: '/ads',
      title: 'Ads & Sponsors',
      subtitle: 'Banners shown to signed-in customers. A banner is shown only after it is approved and while its schedule is open.',
      actions: [
        if (role.canManageAds)
          AQPrimaryButton(
            label: 'New banner',
            leadingIcon: 'plus',
            trailingChevron: false,
            compact: true,
            onPressed: () => context.go('/ads/new'),
          ),
      ],
      children: [
        if (_done != null)
          Padding(
            padding: const EdgeInsets.only(bottom: AQSpacing.x4),
            child: AQErrorBanner(tone: AQBannerTone.success, text: _done!),
          ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: AQSpacing.x4),
            child: AQErrorBanner(text: _error!),
          ),
        AdminAsyncView<List<SponsoredAd>>(
          value: async,
          onRetry: () => ref.invalidate(adminAdsProvider),
          builder: (all) {
            if (all.isEmpty) {
              return AdminNotice(
                icon: 'star',
                title: 'No banners yet',
                body: role.canManageAds
                    ? 'Create the first banner. It is reviewed before customers see it.'
                    : 'No banners have been created.',
                action: role.canManageAds
                    ? AQPrimaryButton(
                        label: 'New banner',
                        trailingChevron: false,
                        onPressed: () => context.go('/ads/new'),
                      )
                    : null,
              );
            }
            final needle = _q.text.trim().toLowerCase();
            final shown = all
                .where((a) => _filter == null || a.status == _filter)
                .where((a) => _audience == null || a.audiences.contains(_audience))
                .where(
                  (a) =>
                      needle.isEmpty ||
                      '${a.sponsor} ${a.headline} ${a.body} ${a.destination}'
                          .toLowerCase()
                          .contains(needle),
                )
                .toList();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AdminSearchField(
                  controller: _q,
                  hint: 'Search sponsor, headline or destination',
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: AQSpacing.x3),
                adminFilterRow(context, 'Audience', [
                  ('All', _audience == null, () => setState(() => _audience = null)),
                  for (final a in AdAudience.values)
                    (
                      audienceLabel(a),
                      _audience == a,
                      () => setState(() => _audience = _audience == a ? null : a),
                    ),
                ]),
                adminFilterRow(context, 'Status', [
                  (
                    'All',
                    _filter == null,
                    () => setState(() => _filter = null),
                  ),
                  for (final s in AdStatus.values)
                    (
                      adStatusLabel(s),
                      _filter == s,
                      () => setState(() => _filter = s),
                    ),
                ]),
                if (shown.isEmpty)
                  const AdminNotice(
                    icon: 'search',
                    title: 'No banner matches',
                    body: 'Change the search or the filters to see the rest.',
                  )
                else
                  AdminTable(
                    headers: const [
                      'Banner',
                      'Placement',
                      'Schedule',
                      'Status',
                      'Actions',
                    ],
                    flex: const [4, 2, 3, 3, 4],
                    rows: [
                      for (final a in shown)
                        AdminTableRow(
                          key: a.id,
                          semantics:
                              '${a.sponsor}, ${a.headline}, ${adStatusLabel(a.status)}',
                          onTap: () => context.go('/ads/${a.id}/edit'),
                          actionCells: const {4},
                          cells: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  VFmt.iso(a.headline),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AQTypography.of(
                                    context,
                                    AQText.titleSmall,
                                  ),
                                ),
                                Text(
                                  '${VFmt.iso(a.sponsor)} · ${a.cta} to ${a.destination}',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AQTypography.of(
                                    context,
                                    AQText.bodySmall,
                                    color: c.inkSoft,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  placementLabel(a.placement),
                                  style: AQTypography.of(
                                    context,
                                    AQText.bodyMedium,
                                  ),
                                ),
                                Text(
                                  audiencesText(a.audiences),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AQTypography.of(
                                    context,
                                    AQText.bodySmall,
                                    color: c.inkSoft,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              _schedule(context, a),
                              style: AQTypography.of(context, AQText.bodySmall),
                            ),
                            adminStatusPill(
                              adStatusLabel(a.status),
                              adStatusLook(a.status),
                            ),
                            Semantics(
                              container: true,
                              explicitChildNodes: true,
                              child: Wrap(
                                spacing: 0,
                                children: [
                                  if (role.canManageAds && a.canSubmit)
                                    AQTextButton(
                                      key: ValueKey('ad-${a.id}-submit'),
                                      label: 'Submit',
                                      color: c.accent,
                                      onPressed: _busyId != null
                                          ? null
                                          : () => _run(
                                              a.id,
                                              (r) => r.submitForReview(a.id),
                                              'Sent for review. It is not live yet.',
                                            ),
                                    ),
                                  if (role.canManageAds && a.canPause)
                                    AQTextButton(
                                      key: ValueKey('ad-${a.id}-pause'),
                                      label: 'Pause',
                                      color: c.inkSoft,
                                      onPressed: _busyId != null
                                          ? null
                                          : () => _run(
                                              a.id,
                                              (r) => r.pause(a.id),
                                              'Banner paused.',
                                            ),
                                    ),
                                  if (role.canManageAds && a.canResume)
                                    AQTextButton(
                                      key: ValueKey('ad-${a.id}-resume'),
                                      label: 'Resume',
                                      color: c.accent,
                                      onPressed: _busyId != null
                                          ? null
                                          : () => _run(
                                              a.id,
                                              (r) => r.resume(a.id),
                                              'Banner resumed.',
                                            ),
                                    ),
                                  if (role.canManageAds &&
                                      a.status == AdStatus.approved) ...[
                                    AQTextButton(
                                      key: ValueKey('ad-${a.id}-up'),
                                      label: 'Move up',
                                      color: c.inkSoft,
                                      onPressed: _busyId != null
                                          ? null
                                          : () => _move(all, a, -1),
                                    ),
                                    AQTextButton(
                                      key: ValueKey('ad-${a.id}-down'),
                                      label: 'Move down',
                                      color: c.inkSoft,
                                      onPressed: _busyId != null
                                          ? null
                                          : () => _move(all, a, 1),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
              ],
            );
          },
        ),
        adminDemoNotice(),
      ],
    );
  }
}

// ------------------------------------------------------------------ create / edit

class AdFormScreen extends ConsumerStatefulWidget {
  final String? editId;
  const AdFormScreen({super.key, this.editId});
  @override
  ConsumerState<AdFormScreen> createState() => _AdFormScreenState();
}

class _AdFormScreenState extends ConsumerState<AdFormScreen> {
  final _sponsor = TextEditingController();
  final _headline = TextEditingController();
  final _body = TextEditingController();
  final _cta = TextEditingController();
  final _destination = TextEditingController();
  AdPlacement _placement = AdPlacement.homeTop;
  Set<AdAudience> _audiences = {AdAudience.customer};
  DateTime? _start, _end;
  Uint8List? _bytes;
  String? _imageName, _imageRef;
  bool _loaded = false, _tried = false, _saving = false, _picking = false;
  String? _error, _done, _imageError;
  SponsoredAd? _existing;
  String? _tapNote;

  bool get _editing => widget.editId != null;

  @override
  void initState() {
    super.initState();
    if (!_editing) _loaded = true;
  }

  @override
  void dispose() {
    for (final c in [_sponsor, _headline, _body, _cta, _destination]) {
      c.dispose();
    }
    super.dispose();
  }

  void _prefill(SponsoredAd a) {
    _existing = a;
    _sponsor.text = a.sponsor;
    _headline.text = a.headline;
    _body.text = a.body;
    _cta.text = a.cta;
    _destination.text = a.destination;
    _placement = a.placement;
    _audiences = {...a.audiences};
    _start = a.startsAt;
    _end = a.endsAt;
    _bytes = a.imageBytes;
    _imageName = a.imageName;
    _imageRef = a.imageRef;
    _loaded = true;
  }

  AdDraft _draft() => AdDraft(
    sponsor: _sponsor.text,
    headline: _headline.text,
    body: _body.text,
    cta: _cta.text,
    destination: _destination.text,
    imageRef: _bytes == null ? _imageRef : null,
    imageBytes: _bytes,
    imageName: _imageName,
    placement: _placement,
    audiences: _audiences,
    startsAt: _start,
    endsAt: _end,
  );

  Map<String, String> get _errors => _tried ? validateAd(_draft()) : const {};

  Future<void> _pickImage() async {
    if (_picking) return;
    setState(() {
      _picking = true;
      _imageError = null;
    });
    try {
      final f = await ref.read(documentPickerProvider).pick();
      if (f == null) return;
      final draft = AdDraft(
        sponsor: 'x',
        headline: 'x',
        cta: 'x',
        destination: '/x',
        imageBytes: f.sizeBytes > kAdMaxImageBytes ? Uint8List(0) : f.bytes,
      );
      final e = validateAd(draft)['image'];
      if (f.sizeBytes > kAdMaxImageBytes) {
        setState(() => _imageError = adminMsg('adm.err.imageSize'));
      } else if (e != null) {
        setState(() => _imageError = adminMsg(e));
      } else {
        setState(() {
          _bytes = f.bytes;
          _imageName = f.name;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _imageError = 'We could not open that file. Try another.',
        );
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _pickDate(bool start) async {
    final now = DateTime.now();
    final r = await showDatePicker(
      context: context,
      initialDate: (start ? _start : _end) ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
    );
    if (r != null) setState(() => start ? _start = r : _end = r);
  }

  Future<void> _save({required bool submit}) async {
    setState(() => _tried = true);
    if (validateAd(_draft()).isNotEmpty || _saving) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _saving = true;
      _error = null;
      _done = null;
    });
    try {
      final repo = ref.read(adAdminRepositoryProvider);
      var ad = _editing
          ? await repo.update(widget.editId!, _draft())
          : await repo.create(_draft());
      if (submit) ad = await repo.submitForReview(ad.id);
      adminLog(ref, _editing ? 'Edited banner' : 'Created banner', ad.headline);
      ref.invalidate(adminAdsProvider);
      ref.invalidate(adminAdProvider(ad.id));
      if (!mounted) return;
      if (_editing) {
        _existing = ad;
        setState(
          () => _done = submit
              ? 'Sent for review. It is not live yet.'
              : 'Saved as a draft. It is not live.',
        );
      } else {
        context.go('/ads/${ad.id}/edit');
      }
    } catch (e) {
      if (!endSessionIfExpired(ref, e) && mounted) {
        setState(
          () => _error = e is AdminForbiddenException ? adminErrorText(e) : 'We could not save this banner. Your entries are kept. Try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AQColors.of(context);
    final role =
        ref.watch(adminAuthProvider).session?.role ?? AdminRole.auditor;
    final title = _editing ? 'Edit banner' : 'New banner';
    if (!role.canManageAds) {
      return AdminFrame(
        section: '/ads',
        title: title,
        onBack: () => context.go('/ads'),
        backLabel: 'Back to banners',
        children: const [
          AdminNotice(
            icon: 'lock',
            title: 'Not allowed',
            body: 'Your role cannot create or edit banners.',
          ),
        ],
      );
    }
    if (_editing && !_loaded) {
      final async = ref.watch(adminAdProvider(widget.editId!));
      return AdminFrame(
        section: '/ads',
        title: title,
        onBack: () => context.go('/ads'),
        backLabel: 'Back to banners',
        children: [
          AdminAsyncView<SponsoredAd?>(
            value: async,
            onRetry: () => ref.invalidate(adminAdProvider(widget.editId!)),
            builder: (a) {
              if (a == null) {
                return const AdminNotice(
                  icon: 'info',
                  title: 'We could not find this banner',
                );
              }
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && !_loaded) setState(() => _prefill(a));
              });
              return const SizedBox(height: 120);
            },
          ),
        ],
      );
    }
    final errs = _errors;
    String? e(String k) => errs[k] == null ? null : adminMsg(errs[k]!);
    final preview = SponsoredAd(
      id: 'preview',
      sponsor: _sponsor.text.trim().isEmpty
          ? 'Sponsor name'
          : _sponsor.text.trim(),
      headline: _headline.text.trim().isEmpty
          ? 'Headline'
          : _headline.text.trim(),
      body: _body.text.trim(),
      cta: _cta.text.trim().isEmpty ? 'Button' : _cta.text.trim(),
      destination: _destination.text.trim().isEmpty
          ? '/'
          : _destination.text.trim(),
      imageRef: _bytes == null ? (_imageRef ?? '') : null,
      imageBytes: _bytes,
      audiences: _audiences,
      status: AdStatus.draft,
      updatedAt: DateTime.now(),
    );
    final ex = _existing;

    final form = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (ex != null && ex.status == AdStatus.approved)
          Padding(
            padding: const EdgeInsets.only(bottom: AQSpacing.x4),
            child: AQErrorBanner(
              tone: AQBannerTone.info,
              text: 'This banner is live. Saving changes sends it back to draft and it stops being shown until it is reviewed again.',
            ),
          ),
        if (ex != null && ex.feedback != null && ex.feedback!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: AQSpacing.x4),
            child: AQErrorBanner(
              tone: AQBannerTone.info,
              text: 'Reviewer feedback: ${ex.feedback}',
            ),
          ),
        AQTextField(
          label: 'Sponsor name',
          controller: _sponsor,
          error: e('sponsor'),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: AQSpacing.x4),
        AQTextField(
          label: 'Headline',
          controller: _headline,
          error: e('headline'),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: AQSpacing.x4),
        AQTextField(
          label: 'Short text (optional)',
          controller: _body,
          minLines: 2,
          maxLines: 3,
          keyboardType: TextInputType.multiline,
          action: TextInputAction.newline,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: AQSpacing.x4),
        AQTextField(
          label: 'Button label',
          controller: _cta,
          error: e('cta'),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: AQSpacing.x4),
        AQTextField(
          label: 'Destination',
          controller: _destination,
          hint: 'https://… or /app/explore',
          helper: 'A secure https address, or a path inside the app.',
          keyboardType: TextInputType.url,
          error: e('destination'),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: AQSpacing.x4),
        DbFieldFrame(
          label: 'Placement',
          required: true,
          child: DbPillRow(
            pills: [
              for (final p in AdPlacement.values)
                (
                  placementLabel(p),
                  _placement == p,
                  () => setState(() => _placement = p),
                ),
            ],
          ),
        ),
        const SizedBox(height: AQSpacing.x4),
        DbFieldFrame(
          label: 'Shown on the Home of',
          required: true,
          error: e('audience'),
          child: DbPillRow(
            pills: [
              for (final a in AdAudience.values)
                (
                  audienceLabel(a),
                  _audiences.contains(a),
                  () => setState(() {
                    final next = {..._audiences};
                    next.contains(a) ? next.remove(a) : next.add(a);
                    _audiences = next;
                  }),
                ),
            ],
          ),
        ),
        const SizedBox(height: AQSpacing.x4),
        DbFieldFrame(
          label: 'Banner image',
          required: true,
          child: Row(
            children: [
              SizedBox(
                width: 190,
                child: AQSecondaryButton(
                  label: _bytes == null && _imageRef == null
                      ? 'Choose image'
                      : 'Replace image',
                  trailingChevron: false,
                  compact: true,
                  loading: _picking,
                  onPressed: _picking ? null : _pickImage,
                ),
              ),
              const SizedBox(width: AQSpacing.x3),
              Expanded(
                child: Text(
                  _imageName ??
                      (_imageRef == null
                          ? 'JPG or PNG, up to 5 MB.'
                          : 'Using the current image.'),
                  style: AQTypography.of(context, AQText.bodySmall, soft: true),
                ),
              ),
            ],
          ),
        ),
        if (_imageError != null || e('image') != null)
          Padding(
            padding: const EdgeInsets.only(top: AQSpacing.x1),
            child: Text(
              _imageError ?? e('image')!,
              style: AQTypography.of(
                context,
                AQText.bodySmall,
                color: c.danger,
              ),
            ),
          ),
        const SizedBox(height: AQSpacing.x4),
        DbFieldFrame(
          label: 'Schedule (optional)',
          child: Wrap(
            spacing: AQSpacing.x2,
            runSpacing: AQSpacing.x2,
            children: [
              SizedBox(
                width: 210,
                child: AQSecondaryButton(
                  label: _start == null
                      ? 'Start date'
                      : 'Starts ${VFmt.shortDate(context, _start!)}',
                  trailingChevron: false,
                  compact: true,
                  onPressed: () => _pickDate(true),
                ),
              ),
              SizedBox(
                width: 210,
                child: AQSecondaryButton(
                  label: _end == null
                      ? 'End date'
                      : 'Ends ${VFmt.shortDate(context, _end!)}',
                  trailingChevron: false,
                  compact: true,
                  onPressed: () => _pickDate(false),
                ),
              ),
              if (_start != null || _end != null)
                AQTextButton(
                  label: 'Clear',
                  color: c.inkSoft,
                  onPressed: () => setState(() => _start = _end = null),
                ),
            ],
          ),
        ),
        if (e('schedule') != null)
          Padding(
            padding: const EdgeInsets.only(top: AQSpacing.x1),
            child: Text(
              e('schedule')!,
              style: AQTypography.of(
                context,
                AQText.bodySmall,
                color: c.danger,
              ),
            ),
          ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: AQSpacing.x4),
            child: AQErrorBanner(text: _error!),
          ),
        if (_done != null)
          Padding(
            padding: const EdgeInsets.only(top: AQSpacing.x4),
            child: AQErrorBanner(tone: AQBannerTone.success, text: _done!),
          ),
        const SizedBox(height: AQSpacing.x5),
        Wrap(
          spacing: AQSpacing.x3,
          runSpacing: AQSpacing.x3,
          children: [
            SizedBox(
              width: 220,
              child: AQSecondaryButton(
                label: 'Save draft',
                trailingChevron: false,
                loading: _saving,
                onPressed: _saving ? null : () => _save(submit: false),
              ),
            ),
            SizedBox(
              width: 260,
              child: AQPrimaryButton(
                label: 'Save and send for review',
                trailingChevron: false,
                loading: _saving,
                onPressed: _saving ? null : () => _save(submit: true),
              ),
            ),
          ],
        ),
      ],
    );

    final previewCard = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        adminSection(context, 'Preview'),
        Text(
          'This is the banner customers see, drawn by the same component.',
          style: AQTypography.of(context, AQText.bodySmall, soft: true),
        ),
        const SizedBox(height: AQSpacing.x3),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SponsoredBannerView(
            ads: [preview],
            onTap: (_) => setState(
              () => _tapNote = destinationOutcome(_destination.text),
            ),
          ),
        ),
        const SizedBox(height: AQSpacing.x2),
        Text(
          _tapNote ?? 'Tap the preview to see where the button goes.',
          style: AQTypography.of(
            context,
            AQText.bodySmall,
            color: AQColors.of(context).inkSoft,
          ),
        ),
        if (ex != null) ...[
          const SizedBox(height: AQSpacing.x3),
          Builder(
            builder: (context) {
              final (views, taps) = sampleFigures(ex.id);
              return Text(
                'Sample figures, not real measurements: $views views, $taps taps. Shown on: ${audiencesText(ex.audiences)}.',
                style: AQTypography.of(
                  context,
                  AQText.bodySmall,
                  color: AQColors.of(context).inkSoft,
                ),
              );
            },
          ),
        ],
        if (ex != null &&
            ex.status == AdStatus.pendingVerification &&
            role.canReviewAds) ...[
          adminSection(context, 'Review'),
          _AdReview(ad: ex),
        ],
      ],
    );

    return AdminFrame(
      section: '/ads',
      title: title,
      subtitle: ex == null
          ? 'A new banner starts as a draft. Customers see it only after it is approved.'
          : '${adStatusLabel(ex.status)} · ${placementLabel(ex.placement)}',
      onBack: () => context.go('/ads'),
      backLabel: 'Back to banners',
      children: [
        LayoutBuilder(
          builder: (context, box) {
            if (box.maxWidth < 860) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [form, previewCard],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 6, child: form),
                const SizedBox(width: AQSpacing.x6),
                Expanded(flex: 5, child: previewCard),
              ],
            );
          },
        ),
        adminDemoNotice(),
      ],
    );
  }
}

/// The review of a banner that was sent for review: approve, ask for changes, or reject.
class _AdReview extends ConsumerWidget {
  final SponsoredAd ad;
  const _AdReview({required this.ad});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DecisionPanel(
      reasons: const [
        ReasonCode.docWrongType,
        ReasonCode.incompleteSubmission,
        ReasonCode.other,
      ],
      canDecide: true,
      open: ad.status == AdStatus.pendingVerification,
      onDecide: (d, reason, note) async {
        final outcome = switch (d) {
          Decision.approve => AdStatus.approved,
          Decision.requestResubmission => AdStatus.resubmissionRequired,
          Decision.reject => AdStatus.rejected,
        };
        await ref
            .read(adAdminRepositoryProvider)
            .decide(
              ad.id,
              outcome: outcome,
              reasonCode: reason == null ? null : reasonWire(reason),
              note: note,
            );
        adminLog(ref, '${decisionVerb(d)} banner', ad.headline);
        ref.invalidate(adminAdsProvider);
        ref.invalidate(adminAdProvider(ad.id));
      },
    );
  }
}
