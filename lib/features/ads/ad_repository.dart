import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/backend_mode.dart';
import '../../core/config/qa_faults.dart';
import '../../data/api/account_api.dart' show ApiErrorCode, ApiException;
import 'ad_models.dart';

enum AdEventKind { impression, tap }

/// What the customer app needs: only approved, in-schedule banners for a placement (`GET /ads`),
/// and best-effort impression / tap events (`POST /ads/:id/events`). A failure here must never be
/// visible to the customer: no banner is shown instead of a broken one.
abstract class AdRepository {
  Future<List<SponsoredAd>> served(AdPlacement placement);
  Future<void> recordEvent(String adId, AdEventKind kind);
}

class UnavailableAdRepository implements AdRepository {
  const UnavailableAdRepository();
  @override
  Future<List<SponsoredAd>> served(AdPlacement placement) async =>
      throw const ApiException(ApiErrorCode.network);
  @override
  Future<void> recordEvent(String adId, AdEventKind kind) async =>
      throw const ApiException(ApiErrorCode.network);
}

/// What the admin console needs (`GET / POST / PATCH /admin/ads`). The service enforces roles,
/// review and scheduling; the console only reflects what it answers.
abstract class AdAdminRepository {
  Future<List<SponsoredAd>> list();
  Future<SponsoredAd?> get(String id);
  Future<SponsoredAd> create(AdDraft draft);
  Future<SponsoredAd> update(String id, AdDraft draft);
  Future<SponsoredAd> submitForReview(String id);
  Future<SponsoredAd> pause(String id);
  Future<SponsoredAd> resume(String id);

  /// Sets the display order of the given ads (first is shown first).
  Future<List<SponsoredAd>> reorder(List<String> idsInOrder);

  /// A reviewer's decision on a banner that waits for review: approved, resubmissionRequired or
  /// rejected. The two negative outcomes carry a reason code and a note.
  Future<SponsoredAd> decide(
    String id, {
    required AdStatus outcome,
    String? reasonCode,
    String note = '',
  });
}

/// DEMO ONLY: one in-memory store used by both the customer reads and the admin writes, so the
/// console and the preview agree. Starts empty; nothing is invented.
class DemoAdRepository implements AdRepository, AdAdminRepository {
  DemoAdRepository({
    this.latency = const Duration(milliseconds: 250),
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;
  final Duration latency;
  final DateTime Function() _clock;
  final List<SponsoredAd> _items = [];
  int _seq = 0;

  /// Test and QA hook: the next call fails with this error.
  Object? debugNextError;

  Future<void> _lag() async {
    if (latency > Duration.zero) await Future<void>.delayed(latency);
    if (qaCallsFail()) throw const ApiException(ApiErrorCode.network);
    final err = debugNextError;
    if (err != null) {
      debugNextError = null;
      throw err;
    }
  }

  SponsoredAd _find(String id) {
    final i = _items.indexWhere((a) => a.id == id);
    if (i < 0) throw const ApiException(ApiErrorCode.server);
    return _items[i];
  }

  void _put(SponsoredAd a) =>
      _items[_items.indexWhere((x) => x.id == a.id)] = a;

  @override
  Future<List<SponsoredAd>> served(AdPlacement placement) async {
    await _lag();
    final now = _clock();
    final list =
        _items
            .where((a) => a.placement == placement && a.servableAt(now))
            .toList()
          ..sort((a, b) => a.order.compareTo(b.order));
    return List.unmodifiable(list);
  }

  @override
  Future<void> recordEvent(String adId, AdEventKind kind) async {}

  @override
  Future<List<SponsoredAd>> list() async {
    await _lag();
    final list = [..._items]
      ..sort(
        (a, b) => a.placement == b.placement
            ? a.order.compareTo(b.order)
            : a.placement.index.compareTo(b.placement.index),
      );
    return List.unmodifiable(list);
  }

  @override
  Future<SponsoredAd?> get(String id) async {
    await _lag();
    return _items.where((a) => a.id == id).firstOrNull;
  }

  @override
  Future<SponsoredAd> create(AdDraft d) async {
    await _lag();
    if (validateAd(d).isNotEmpty) {
      throw const ApiException(ApiErrorCode.validationFailed);
    }
    final a = SponsoredAd(
      id: 'ad${++_seq}',
      sponsor: d.sponsor.trim(),
      headline: d.headline.trim(),
      body: d.body.trim(),
      cta: d.cta.trim(),
      destination: d.destination.trim(),
      imageRef: d.imageRef,
      imageBytes: d.imageBytes,
      imageName: d.imageName,
      placement: d.placement,
      status: AdStatus.draft,
      startsAt: d.startsAt,
      endsAt: d.endsAt,
      order: _items.where((x) => x.placement == d.placement).length,
      updatedAt: _clock(),
    );
    _items.add(a);
    return a;
  }

  @override
  Future<SponsoredAd> update(String id, AdDraft d) async {
    await _lag();
    final old = _find(id);
    if (!old.canEdit) throw const ApiException(ApiErrorCode.conflict);
    if (validateAd(d).isNotEmpty) {
      throw const ApiException(ApiErrorCode.validationFailed);
    }
    // A material edit to an approved banner goes back to review: it is not served meanwhile.
    final next = SponsoredAd(
      id: old.id,
      sponsor: d.sponsor.trim(),
      headline: d.headline.trim(),
      body: d.body.trim(),
      cta: d.cta.trim(),
      destination: d.destination.trim(),
      imageRef: d.imageRef ?? (d.imageBytes == null ? old.imageRef : null),
      imageBytes: d.imageBytes ?? (d.imageRef == null ? old.imageBytes : null),
      imageName: d.imageName ?? old.imageName,
      placement: d.placement,
      status:
          old.status == AdStatus.approved ||
              old.status == AdStatus.paused ||
              old.status == AdStatus.rejected
          ? AdStatus.draft
          : old.status,
      startsAt: d.startsAt,
      endsAt: d.endsAt,
      order: old.order,
      updatedAt: _clock(),
    );
    _put(next);
    return next;
  }

  @override
  Future<SponsoredAd> submitForReview(String id) async {
    await _lag();
    final a = _find(id);
    if (!a.canSubmit) throw const ApiException(ApiErrorCode.conflict);
    final n = a.copyWith(
      status: AdStatus.pendingVerification,
      updatedAt: _clock(),
    );
    _put(n);
    return n;
  }

  @override
  Future<SponsoredAd> pause(String id) async {
    await _lag();
    final a = _find(id);
    if (!a.canPause) throw const ApiException(ApiErrorCode.conflict);
    final n = a.copyWith(status: AdStatus.paused, updatedAt: _clock());
    _put(n);
    return n;
  }

  @override
  Future<SponsoredAd> resume(String id) async {
    await _lag();
    final a = _find(id);
    if (!a.canResume) throw const ApiException(ApiErrorCode.conflict);
    final n = a.copyWith(status: AdStatus.approved, updatedAt: _clock());
    _put(n);
    return n;
  }

  @override
  Future<List<SponsoredAd>> reorder(List<String> idsInOrder) async {
    await _lag();
    for (var i = 0; i < idsInOrder.length; i++) {
      _put(_find(idsInOrder[i]).copyWith(order: i));
    }
    return list();
  }

  @override
  Future<SponsoredAd> decide(
    String id, {
    required AdStatus outcome,
    String? reasonCode,
    String note = '',
  }) async {
    await _lag();
    final a = _find(id);
    if (a.status != AdStatus.pendingVerification) {
      throw const ApiException(ApiErrorCode.conflict);
    }
    if (outcome != AdStatus.approved &&
        outcome != AdStatus.resubmissionRequired &&
        outcome != AdStatus.rejected) {
      throw const ApiException(ApiErrorCode.validationFailed);
    }
    final n = a.copyWith(
      status: outcome,
      feedback: outcome == AdStatus.approved
          ? null
          : (note.isNotEmpty ? note : reasonCode),
      updatedAt: _clock(),
    );
    _put(n);
    return n;
  }

  /// QA / review only: a reviewer's decision on a banner (banners are approved in the review queue,
  /// never by the person who edits them in this screen).
  void debugDecide(String id, AdStatus status, {String? feedback}) => _put(
    _find(id).copyWith(status: status, feedback: feedback, updatedAt: _clock()),
  );

  /// QA / tests: adds a banner directly in any state.
  SponsoredAd debugAdd(AdDraft d, {AdStatus status = AdStatus.approved}) {
    final a = SponsoredAd(
      id: 'ad${++_seq}',
      sponsor: d.sponsor,
      headline: d.headline,
      body: d.body,
      cta: d.cta,
      destination: d.destination,
      imageRef: d.imageRef,
      imageBytes: d.imageBytes,
      imageName: d.imageName,
      placement: d.placement,
      status: status,
      startsAt: d.startsAt,
      endsAt: d.endsAt,
      order: _items.where((x) => x.placement == d.placement).length,
      updatedAt: _clock(),
    );
    _items.add(a);
    return a;
  }
}

final adRepositoryProvider = Provider<AdRepository>((ref) {
  if (!kUseDemoBackend) return const UnavailableAdRepository();
  final repo = DemoAdRepository();
  // QA bundles only (`REVIEW_TOOLS`): two clearly named sample banners so the pinned placement can
  // be looked at. The public demo starts with none; real ads come from the admin console.
  if (kShowReviewTools) {
    for (final (name, line) in [
      ('QA sample sponsor A', 'Sample banner one'),
      ('QA sample sponsor B', 'Sample banner two'),
    ]) {
      repo.debugAdd(
        AdDraft(
          sponsor: name,
          headline: line,
          body: 'Review-build sample. Not a real advertiser.',
          cta: 'Learn more',
          destination: '/app/explore',
          imageRef: 'assets/location/11_Muscat_skyline_and_mountains.jpg',
        ),
      );
    }
  }
  return repo;
});
final servedAdsProvider = FutureProvider.autoDispose
    .family<List<SponsoredAd>, AdPlacement>(
      (ref, placement) => ref.watch(adRepositoryProvider).served(placement),
    );
