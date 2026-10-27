import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/backend_mode.dart';
import '../../core/config/qa_faults.dart';
import '../../data/api/account_api.dart' show ApiErrorCode, ApiException;
import '../../data/models/enums.dart';
import '../devbuild/db_models.dart' show PermissionDeniedException;
import 'listing_models.dart';

/// Frontend contract for an agent's own listings. The service enforces ownership, the item state
/// machine and moderation; the app only reflects what it answers. Nothing here ever makes a listing
/// public: approval is a reviewer's decision.
abstract class ListingRepository {
  Future<List<AgentListing>> mine();

  /// Null when the listing does not exist; throws [PermissionDeniedException] when it belongs to
  /// someone else.
  Future<AgentListing?> get(String id);
  Future<AgentListing> create(ListingInput input);
  Future<AgentListing> update(String id, ListingInput input);

  /// Whether the connected service has a pause / resume operation at all. The documented listing
  /// lifecycle (sold, rented, withdrawn, renew, expiry) has none, so a real service must add one
  /// before this answers true. While it is false the app does not call pause or resume and says so.
  bool get supportsPause;
  Future<AgentListing> pause(String id);
  Future<AgentListing> resume(String id);
  Future<AgentListing> renew(String id);
}

/// Used when no real service is wired: every call fails like an offline request.
class UnavailableListingRepository implements ListingRepository {
  const UnavailableListingRepository();
  Never _no() => throw const ApiException(ApiErrorCode.network);
  @override
  bool get supportsPause => false;
  @override
  Future<List<AgentListing>> mine() async => _no();
  @override
  Future<AgentListing?> get(String id) async => _no();
  @override
  Future<AgentListing> create(ListingInput input) async => _no();
  @override
  Future<AgentListing> update(String id, ListingInput input) async => _no();
  @override
  Future<AgentListing> pause(String id) async => _no();
  @override
  Future<AgentListing> resume(String id) async => _no();
  @override
  Future<AgentListing> renew(String id) async => _no();
}

/// DEMO ONLY: in memory, scoped to one owner. Reviewer decisions are simulated through [debugSet]
/// (QA tools only). New listings always start in review; nothing here approves anything by itself.
class DemoListingRepository implements ListingRepository {
  DemoListingRepository({
    this.ownerId = 'me',
    this.latency = const Duration(milliseconds: 350),
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;
  final String ownerId;
  final Duration latency;
  final DateTime Function() _clock;
  final List<AgentListing> _items = [];
  int _seq = 0, _photoSeq = 0;

  /// DEMO ONLY: the demo simulates pause / resume so the screens can be reviewed.
  @override
  bool get supportsPause => true;

  /// Test and QA hooks: the next write fails with this error.
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

  AgentListing _own(String id) {
    final i = _items.indexWhere((l) => l.id == id);
    if (i < 0) throw const ApiException(ApiErrorCode.server);
    if (_items[i].ownerId != ownerId) throw const PermissionDeniedException();
    return _items[i];
  }

  void _put(AgentListing l) {
    final i = _items.indexWhere((x) => x.id == l.id);
    if (i >= 0) _items[i] = l;
  }

  List<ListingPhoto> _photos(AgentListing? old, ListingInput input) {
    final keep = old == null
        ? <ListingPhoto>[]
        : old.photos.where((p) => input.keepPhotoIds.contains(p.id)).toList();
    return [
      ...keep,
      for (final p in input.newPhotos)
        ListingPhoto(id: 'ph${++_photoSeq}', name: p.name, bytes: p.bytes),
    ];
  }

  @override
  Future<List<AgentListing>> mine() async {
    if (latency > Duration.zero) await Future<void>.delayed(latency);
    return List.unmodifiable(
      _items.where((l) => l.ownerId == ownerId).toList().reversed,
    );
  }

  @override
  Future<AgentListing?> get(String id) async {
    if (latency > Duration.zero) await Future<void>.delayed(latency);
    final l = _items.where((x) => x.id == id).firstOrNull;
    if (l == null) return null;
    if (l.ownerId != ownerId) throw const PermissionDeniedException();
    return l;
  }

  @override
  Future<AgentListing> create(ListingInput input) async {
    await _lag();
    final dup = _items.any(
      (l) =>
          normaliseDeed(l.titleDeed) == normaliseDeed(input.titleDeed) &&
          l.transaction == input.transaction &&
          l.status != ListingStatus.withdrawn &&
          l.status != ListingStatus.rejected,
    );
    if (dup) throw const DuplicateListingException();
    final now = _clock();
    final l = AgentListing(
      id: 'l${++_seq}',
      ownerId: ownerId,
      title: input.title.trim(),
      description: input.description.trim(),
      type: input.type,
      transaction: input.transaction,
      priceOmr: input.priceOmr,
      governorate: input.governorate,
      wilayat: input.wilayat,
      area: input.area.trim(),
      sizeSqm: input.sizeSqm,
      bedrooms: input.bedrooms,
      bathrooms: input.bathrooms,
      parking: input.parking,
      titleDeed: normaliseDeed(input.titleDeed),
      photos: _photos(null, input),
      status: ListingStatus.pendingVerification,
      createdAt: now,
      updatedAt: now,
    );
    _items.add(l);
    return l;
  }

  @override
  Future<AgentListing> update(String id, ListingInput input) async {
    await _lag();
    final old = _own(id);
    if (!old.canEdit) throw const ListingStatusConflictException();
    final dup = _items.any(
      (l) =>
          l.id != id &&
          normaliseDeed(l.titleDeed) == normaliseDeed(input.titleDeed) &&
          l.transaction == input.transaction &&
          l.status != ListingStatus.withdrawn &&
          l.status != ListingStatus.rejected,
    );
    if (dup) throw const DuplicateListingException();
    final live =
        old.status == ListingStatus.approved ||
        old.status == ListingStatus.paused;
    final next = AgentListing(
      id: old.id,
      ownerId: old.ownerId,
      agencyId: old.agencyId,
      title: input.title.trim(),
      description: input.description.trim(),
      type: input.type,
      transaction: input.transaction,
      priceOmr: input.priceOmr,
      governorate: input.governorate,
      wilayat: input.wilayat,
      area: input.area.trim(),
      sizeSqm: input.sizeSqm,
      bedrooms: input.bedrooms,
      bathrooms: input.bathrooms,
      parking: input.parking,
      titleDeed: normaliseDeed(input.titleDeed),
      photos: _photos(old, input),
      // A live listing keeps its status while the edit is reviewed as a change set; a draft or a
      // returned listing goes (back) to review.
      status: live ? old.status : ListingStatus.pendingVerification,
      createdAt: old.createdAt,
      updatedAt: _clock(),
      pendingChanges: live,
    );
    _put(next);
    return next;
  }

  @override
  Future<AgentListing> pause(String id) async {
    await _lag();
    final l = _own(id);
    if (!l.canPause) throw const ListingStatusConflictException();
    final n = l.copyWith(status: ListingStatus.paused, updatedAt: _clock());
    _put(n);
    return n;
  }

  @override
  Future<AgentListing> resume(String id) async {
    await _lag();
    final l = _own(id);
    if (!l.canResume) throw const ListingStatusConflictException();
    final n = l.copyWith(status: ListingStatus.approved, updatedAt: _clock());
    _put(n);
    return n;
  }

  @override
  Future<AgentListing> renew(String id) async {
    await _lag();
    final l = _own(id);
    if (!l.canRenew) throw const ListingStatusConflictException();
    // Renewal is reviewed again; it does not republish by itself.
    final n = l.copyWith(
      status: ListingStatus.pendingVerification,
      updatedAt: _clock(),
    );
    _put(n);
    return n;
  }

  /// QA only: simulates a reviewer's decision.
  void debugSet(
    String id,
    ListingStatus status, {
    String? feedback,
    bool pendingChanges = false,
  }) {
    final i = _items.indexWhere((l) => l.id == id);
    if (i >= 0) {
      _items[i] = _items[i].copyWith(
        status: status,
        feedback: feedback,
        pendingChanges: pendingChanges,
      );
    }
  }

  /// QA only: a listing that belongs to another agent, to prove it cannot be opened.
  String debugAddForeign() {
    final now = _clock();
    final l = AgentListing(
      id: 'x${++_seq}',
      ownerId: 'someone-else',
      title: 'Not yours',
      description: '',
      type: PropertyType.apartment,
      transaction: TransactionType.buy,
      priceOmr: 1,
      governorate: 'Muscat',
      wilayat: 'Muscat',
      sizeSqm: 1,
      titleDeed: 'FOREIGN001',
      status: ListingStatus.approved,
      createdAt: now,
      updatedAt: now,
    );
    _items.add(l);
    return l.id;
  }
}

final listingRepositoryProvider = Provider<ListingRepository>(
  (ref) => kUseDemoBackend
      ? DemoListingRepository()
      : const UnavailableListingRepository(),
);
final myListingsProvider = FutureProvider.autoDispose<List<AgentListing>>(
  (ref) => ref.watch(listingRepositoryProvider).mine(),
);
final myListingProvider = FutureProvider.autoDispose
    .family<AgentListing?, String>(
      (ref, id) => ref.watch(listingRepositoryProvider).get(id),
    );
