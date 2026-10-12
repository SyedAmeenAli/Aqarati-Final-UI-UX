import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/backend_mode.dart';
import '../../core/domain/account_models.dart';
import '../../data/api/account_api.dart';
import '../../data/datasources/mock_business_data.dart';
import '../../data/demo/demo_backend.dart';
import '../../data/demo/demo_providers.dart';
import '../../data/models/enums.dart';
import 'db_models.dart';

enum DbSort { relevance, rating, name }

/// Everything a directory search is narrowed by. Value-equal so it can key a provider.
class DbQuery {
  final ProType? type;
  final String text;
  final String? governorate;
  final InteriorExteriorServiceType? serviceType;
  final DbSort sort;
  const DbQuery({
    this.type,
    this.text = '',
    this.governorate,
    this.serviceType,
    this.sort = DbSort.relevance,
  });

  DbQuery copyWith({
    ProType? type,
    bool clearType = false,
    String? text,
    String? governorate,
    bool clearGov = false,
    InteriorExteriorServiceType? serviceType,
    bool clearService = false,
    DbSort? sort,
  }) => DbQuery(
    type: clearType ? null : (type ?? this.type),
    text: text ?? this.text,
    governorate: clearGov ? null : (governorate ?? this.governorate),
    serviceType: clearService ? null : (serviceType ?? this.serviceType),
    sort: sort ?? this.sort,
  );

  int get activeFilters =>
      (governorate != null ? 1 : 0) + (serviceType != null ? 1 : 0);

  @override
  bool operator ==(Object other) =>
      other is DbQuery &&
      other.type == type &&
      other.text == text &&
      other.governorate == governorate &&
      other.serviceType == serviceType &&
      other.sort == sort;
  @override
  int get hashCode => Object.hash(type, text, governorate, serviceType, sort);
}

class DbPage<T> {
  final List<T> items;
  final bool hasMore;
  const DbPage(this.items, {this.hasMore = false});
}

/// The Development & Building data contract as the frontend sees it. Screens only ever talk
/// to this; they never call a network client. Anything the contract lacks is reported through
/// [caps] so the UI can say so instead of pretending.
abstract class DevBuildRepository {
  DbCapabilities get caps;

  // Public directory: approved businesses and approved projects only.
  Future<DbPage<DbProfessional>> professionals(
    DbQuery q, {
    int offset = 0,
    int limit = 10,
  });
  Future<DbProfessional?> professional(String id);
  Future<List<DbProject>> approvedProjects(String orgId);
  Future<DbProject?> approvedProject(String id);
  Future<List<DbReview>> publishedReviews(String orgId);
  Future<void> logContactEvent(String orgId, ContactChannel channel);

  // Workspace: scoped to the caller's own organisation. Implementations must re-check ownership.
  Future<DbProfessional?> myOrganisation();
  Future<List<DbProject>> myProjects();
  Future<DbProject> myProject(String id);
  Future<DbProject> saveProject(
    ProjectDraft draft, {
    required bool submit,
    required String idempotencyKey,
  });
  Future<DbProject> resubmitProject(
    String id, {
    required String idempotencyKey,
  });
  Future<ProfileSaveState> updateMyProfile(ProfileEdit edit);
  Future<List<ContactEvent>> myContactEvents();
  Future<List<Engagement>> myEngagements();
  Future<void> confirmEngagement(String id);
}

/// Used when no real API is wired: every call fails like an offline request, so screens show
/// their error/retry states and nothing pretends to have succeeded.
class UnavailableDevBuildRepository implements DevBuildRepository {
  const UnavailableDevBuildRepository();
  Never _no() => throw const ApiException(ApiErrorCode.network);
  @override
  DbCapabilities get caps => const DbCapabilities();
  @override
  Future<DbPage<DbProfessional>> professionals(
    DbQuery q, {
    int offset = 0,
    int limit = 10,
  }) async => _no();
  @override
  Future<DbProfessional?> professional(String id) async => _no();
  @override
  Future<List<DbProject>> approvedProjects(String orgId) async => _no();
  @override
  Future<DbProject?> approvedProject(String id) async => _no();
  @override
  Future<List<DbReview>> publishedReviews(String orgId) async => _no();
  @override
  Future<void> logContactEvent(String orgId, ContactChannel channel) async =>
      _no();
  @override
  Future<DbProfessional?> myOrganisation() async => _no();
  @override
  Future<List<DbProject>> myProjects() async => _no();
  @override
  Future<DbProject> myProject(String id) async => _no();
  @override
  Future<DbProject> saveProject(
    ProjectDraft draft, {
    required bool submit,
    required String idempotencyKey,
  }) async => _no();
  @override
  Future<DbProject> resubmitProject(
    String id, {
    required String idempotencyKey,
  }) async => _no();
  @override
  Future<ProfileSaveState> updateMyProfile(ProfileEdit edit) async => _no();
  @override
  Future<List<ContactEvent>> myContactEvents() async => _no();
  @override
  Future<List<Engagement>> myEngagements() async => _no();
  @override
  Future<void> confirmEngagement(String id) async => _no();
}

/// DEMO ONLY (see lib/core/config/backend_mode.dart): an in-memory stand-in for the documented
/// contract so the screens can be reviewed. Fictional businesses, no persistence, never a backend.
/// Capabilities stay false where the contract is not confirmed, exactly as the real one would.
class DemoDevBuildRepository implements DevBuildRepository {
  final DemoBackendState? Function() _session;
  DemoDevBuildRepository(
    this._session, {
    this.lag = const Duration(milliseconds: 220),
  });

  /// Simulated network latency. Tests pass [Duration.zero] to stay out of fake-async timers.
  final Duration lag;

  final List<DbProject> _mine = [];
  final Map<String, DbProject> _byKey = {};
  int _n = 0;

  /// Fictional but plausible-looking Oman mobile number, stable per business, for the demo roster only.
  static String _demoPhoneFor(String id) {
    final n = id.codeUnits.fold<int>(7, (a, b) => (a * 31 + b) % 10000000);
    final d = n.toString().padLeft(7, '0');
    return '+968 9${d.substring(0, 3)} ${d.substring(3)}';
  }

  static final List<DbProfessional> _roster = [
    for (final b in mockBusinesses)
      if (DbProfessional.fromBusiness(b) case final p?)
        if (p.verified) _withDemoContact(p),
    DbProfessional(
      id: 'demo-c1',
      name: 'Sahari Contracting',
      type: ProType.construction,
      bio: 'General contractor for villas and low-rise buildings, working from foundations to handover.',
      locationLabel: 'Sohar, Oman',
      governorate: 'Al Batinah North',
      latitude: 24.3475,
      longitude: 56.7090,
      mediaUrls: [
        'assets/businesses/b2/02_Concrete_structural_construction.jpg',
        'assets/businesses/b2/03_Construction_equipment_at_buildi.jpg',
      ],
      rating: 4.6,
      reviewCount: 31,
      phone: _demoPhoneFor('demo-c1'),
    ),
    DbProfessional(
      id: 'demo-d1',
      name: 'Zahra Developments',
      type: ProType.developer,
      bio:
          'Developer of small residential communities along the Batinah coast.',
      locationLabel: 'Barka, Oman',
      governorate: 'Al Batinah South',
      latitude: 23.6788,
      longitude: 57.8870,
      mediaUrls: [
        'assets/properties/p4/01_Contemporary_family_villa_comple.jpg',
      ],
      rating: 4.4,
      reviewCount: 18,
      phone: _demoPhoneFor('demo-d1'),
    ),
    DbProfessional(
      id: 'demo-i1',
      name: 'Dar Nuqta Interiors',
      type: ProType.interiorExterior,
      serviceType: InteriorExteriorServiceType.interior,
      bio: 'Interior design for homes and boutique offices, from concept to fit-out.',
      locationLabel: 'Muscat, Oman',
      governorate: 'Muscat',
      latitude: 23.6100,
      longitude: 58.5400,
      mediaUrls: [
        'assets/businesses/b3/04_Reading_and_work_nook.jpg',
        'assets/businesses/b3/01_Modern_designer_bathroom_interio.jpg',
      ],
      rating: 4.7,
      reviewCount: 22,
      phone: _demoPhoneFor('demo-i1'),
    ),
  ];

  static DbProfessional _withDemoContact(DbProfessional p) => DbProfessional(
    id: p.id,
    name: p.name,
    type: p.type,
    serviceType: p.serviceType,
    bio: p.bio,
    locationLabel: p.locationLabel,
    governorate: p.governorate,
    latitude: _coords[p.id]?.$1 ?? 23.5880,
    longitude: _coords[p.id]?.$2 ?? 58.3829,
    logoUrl: p.logoUrl,
    mediaUrls: p.mediaUrls,
    rating: p.rating,
    reviewCount: p.reviewCount,
    phone: _demoPhoneFor(p.id),
    whatsapp: _demoPhoneFor(p.id),
  );

  static const _coords = <String, (double, double)>{
    'b1': (23.5933, 58.4059),
    'b2': (23.5740, 58.2640),
  };

  /// Approved projects, keyed by the organisation that owns them.
  static final List<DbProject> _approved = [
    DbProject(
      id: 'demo-p1',
      orgId: 'b2',
      name: 'Al Mouj Residences',
      propertyType: PropertyType.villa,
      bedrooms: 4,
      bathrooms: 5,
      areaSqm: 320,
      landSqm: 450,
      governorate: 'Muscat',
      wilayat: 'As Seeb',
      area: 'Al Mouj',
      latitude: 23.6220,
      longitude: 58.2560,
      status: ProjectStatus.approved,
      rawStatus: 'approved',
      updatedAt: DateTime(2026, 9, 20),
    ),
    DbProject(
      id: 'demo-p2',
      orgId: 'b2',
      name: 'Namaa Courtyard Homes',
      propertyType: PropertyType.townhouse,
      bedrooms: 3,
      bathrooms: 4,
      areaSqm: 210,
      governorate: 'Muscat',
      wilayat: 'Bawshar',
      latitude: 23.5800,
      longitude: 58.3500,
      status: ProjectStatus.approved,
      rawStatus: 'approved',
      updatedAt: DateTime(2026, 9, 2),
    ),
    DbProject(
      id: 'demo-p3',
      orgId: 'demo-d1',
      name: 'Barka Gardens',
      propertyType: PropertyType.apartment,
      bedrooms: 2,
      bathrooms: 2,
      areaSqm: 118,
      governorate: 'Al Batinah South',
      wilayat: 'Barka',
      latitude: 23.6788,
      longitude: 57.8870,
      status: ProjectStatus.approved,
      rawStatus: 'approved',
      updatedAt: DateTime(2026, 8, 14),
    ),
  ];

  static final Map<String, List<DbReview>> _reviews = {
    'b2': [
      DbReview(
        id: 'r1',
        rating: 5,
        body:
            'Clear communication through the whole build and a clean handover.',
        author: 'Verified client',
        at: DateTime(2026, 8, 30),
      ),
      DbReview(
        id: 'r2',
        rating: 4,
        body: 'Good quality work. A few snags at handover, fixed quickly.',
        author: 'Verified client',
        at: DateTime(2026, 7, 11),
      ),
    ],
  };

  @override
  DbCapabilities get caps => const DbCapabilities(profileEdit: true);

  Future<void> _lag() =>
      lag == Duration.zero ? Future<void>.value() : Future<void>.delayed(lag);

  bool _matchesText(DbProfessional p, String t, List<DbProject> projects) {
    if (t.isEmpty) return true;
    final hay =
        '${p.name} ${p.bio} ${p.locationLabel} ${projects.map((x) => x.name).join(' ')}'
            .toLowerCase();
    return hay.contains(t.toLowerCase());
  }

  @override
  Future<DbPage<DbProfessional>> professionals(
    DbQuery q, {
    int offset = 0,
    int limit = 10,
  }) async {
    await _lag();
    final t = q.text.trim();
    final rows = [
      for (final p in _roster)
        if (p.verified &&
            (q.type == null || p.type == q.type) &&
            (q.governorate == null || p.governorate == q.governorate) &&
            _matchesText(
              p,
              t,
              _approved.where((x) => x.orgId == p.id).toList(),
            ))
          if (q.serviceType == null ||
              p.serviceType == q.serviceType ||
              p.serviceType == InteriorExteriorServiceType.both)
            // Developers appear only with at least one approved project that matches.
            if (p.type != ProType.developer ||
                _approved.any(
                  (x) =>
                      x.orgId == p.id &&
                      (t.isEmpty ||
                          x.name.toLowerCase().contains(t.toLowerCase()) ||
                          p.name.toLowerCase().contains(t.toLowerCase())),
                ))
              p,
    ];
    switch (q.sort) {
      case DbSort.rating:
        rows.sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));
      case DbSort.name:
        rows.sort((a, b) => a.name.compareTo(b.name));
      case DbSort.relevance:
        break;
    }
    final end = (offset + limit).clamp(0, rows.length);
    return DbPage(
      rows.sublist(offset.clamp(0, rows.length), end),
      hasMore: end < rows.length,
    );
  }

  @override
  Future<DbProfessional?> professional(String id) async {
    await _lag();
    return _roster.where((p) => p.id == id && p.verified).firstOrNull;
  }

  @override
  Future<List<DbProject>> approvedProjects(String orgId) async {
    await _lag();
    return [
      for (final p in _approved)
        if (p.orgId == orgId && p.status.isPublic) p,
    ];
  }

  @override
  Future<DbProject?> approvedProject(String id) async {
    await _lag();
    return _approved.where((p) => p.id == id && p.status.isPublic).firstOrNull;
  }

  @override
  Future<List<DbReview>> publishedReviews(String orgId) async {
    await _lag();
    return _reviews[orgId] ?? const [];
  }

  @override
  Future<void> logContactEvent(String orgId, ContactChannel channel) async {
    // Lead events have no confirmed endpoint: nothing is recorded and nothing is claimed.
  }

  // ---- workspace

  DbProfessional? _org() {
    final s = _session();
    final type = proTypeOfPurpose(s?.purpose);
    if (s == null || type == null || s.grant != GrantState.approved)
      return null;
    return DbProfessional(
      id: 'me',
      name: s.businessName ?? '',
      type: type,
      locationLabel: '',
      governorate: '',
      verified: true,
    );
  }

  DbProfessional _requireOrg() {
    final o = _org();
    if (o == null) throw const PermissionDeniedException();
    return o;
  }

  @override
  Future<DbProfessional?> myOrganisation() async {
    await _lag();
    return _org();
  }

  @override
  Future<List<DbProject>> myProjects() async {
    await _lag();
    final o = _requireOrg();
    if (!o.type.hasProjects) throw const PermissionDeniedException();
    return List.unmodifiable(_mine.reversed);
  }

  @override
  Future<DbProject> myProject(String id) async {
    await _lag();
    final o = _requireOrg();
    if (!o.type.hasProjects) throw const PermissionDeniedException();
    final p = _mine.where((x) => x.id == id).firstOrNull;
    if (p == null) throw const PermissionDeniedException();
    return p;
  }

  @override
  Future<DbProject> saveProject(
    ProjectDraft draft, {
    required bool submit,
    required String idempotencyKey,
  }) async {
    await _lag();
    final o = _requireOrg();
    if (!o.type.hasProjects) throw const PermissionDeniedException();
    final replay = _byKey[idempotencyKey];
    if (replay != null) return replay;
    final errors = <String, String>{};
    if (submit) {
      for (final e in draft.validateAll().values) {
        errors.addAll(e);
      }
    } else if (draft.name.trim().length < 3) {
      errors['name'] = 'db.err.name';
    }
    if (errors.isNotEmpty) throw ProjectValidationException(errors);
    final existing = draft.id == null
        ? null
        : _mine.where((x) => x.id == draft.id).firstOrNull;
    if (draft.id != null && existing == null)
      throw const PermissionDeniedException();
    // A material edit to an approved project goes back to review; a draft stays a draft until submitted.
    final ProjectStatus next;
    if (!submit) {
      next = existing == null || existing.status == ProjectStatus.draft
          ? ProjectStatus.draft
          : existing.status;
    } else {
      next = ProjectStatus.underReview;
    }
    final saved = DbProject(
      id: existing?.id ?? 'prj-${++_n}',
      orgId: o.id,
      name: draft.name.trim(),
      propertyType: draft.type ?? PropertyType.villa,
      bedrooms: typeHasRooms(draft.type) ? draft.bedrooms : null,
      bathrooms: typeHasRooms(draft.type) ? draft.bathrooms : null,
      landSqm: draft.landSqm,
      areaSqm: typeIsLand(draft.type) ? null : draft.areaSqm,
      governorate: draft.governorate ?? '',
      wilayat: draft.wilayat ?? '',
      area: draft.area.trim(),
      latitude: draft.latitude,
      longitude: draft.longitude,
      status: next,
      rawStatus: next == ProjectStatus.underReview
          ? 'pending_verification'
          : next.name,
      updatedAt: DateTime.now(),
    );
    if (existing == null) {
      _mine.add(saved);
    } else {
      _mine[_mine.indexOf(existing)] = saved;
    }
    _byKey[idempotencyKey] = saved;
    return saved;
  }

  @override
  Future<DbProject> resubmitProject(
    String id, {
    required String idempotencyKey,
  }) async {
    await _lag();
    final replay = _byKey[idempotencyKey];
    if (replay != null) return replay;
    final p = await myProject(id);
    if (!p.status.canResubmit)
      throw const ProjectValidationException({'status': 'db.err.resubmit'});
    final next = p.copyWith(
      status: ProjectStatus.underReview,
      rawStatus: 'pending_verification',
      clearFeedback: true,
      updatedAt: DateTime.now(),
    );
    _mine[_mine.indexWhere((x) => x.id == id)] = next;
    _byKey[idempotencyKey] = next;
    return next;
  }

  /// REVIEW TOOLS ONLY: simulates the external admin decision on a project.
  void debugDecide(String id, ProjectStatus status, {String? feedback}) {
    final i = _mine.indexWhere((x) => x.id == id);
    if (i < 0) return;
    _mine[i] = _mine[i].copyWith(
      status: status,
      rawStatus: switch (status) {
        ProjectStatus.changesRequested => 'resubmission_required',
        ProjectStatus.underReview => 'pending_verification',
        _ => status.name,
      },
      reviewerFeedback: feedback,
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<ProfileSaveState> updateMyProfile(ProfileEdit edit) async {
    await _lag();
    _requireOrg();
    // Bio, service type and location are material fields: they go to re-review before they are public.
    return ProfileSaveState.awaitingReview;
  }

  @override
  Future<List<ContactEvent>> myContactEvents() async {
    await _lag();
    _requireOrg();
    return const [];
  }

  @override
  Future<List<Engagement>> myEngagements() async {
    await _lag();
    _requireOrg();
    return const [];
  }

  @override
  Future<void> confirmEngagement(String id) async =>
      throw const ApiException(ApiErrorCode.network);
}

final devBuildRepositoryProvider = Provider<DevBuildRepository>((ref) {
  if (!kUseDemoBackend) return const UnavailableDevBuildRepository();
  final repo = DemoDevBuildRepository(() => ref.read(demoBackendStateProvider));
  return repo;
});

final dbProfessionalProvider = FutureProvider.autoDispose
    .family<DbProfessional?, String>(
      (ref, id) => ref.watch(devBuildRepositoryProvider).professional(id),
    );
final dbApprovedProjectsProvider = FutureProvider.autoDispose
    .family<List<DbProject>, String>(
      (ref, id) => ref.watch(devBuildRepositoryProvider).approvedProjects(id),
    );
final dbPublicProjectProvider = FutureProvider.autoDispose
    .family<DbProject?, String>(
      (ref, id) => ref.watch(devBuildRepositoryProvider).approvedProject(id),
    );
final dbReviewsProvider = FutureProvider.autoDispose
    .family<List<DbReview>, String>(
      (ref, id) => ref.watch(devBuildRepositoryProvider).publishedReviews(id),
    );
final dbMyOrgProvider = FutureProvider.autoDispose<DbProfessional?>(
  (ref) => ref.watch(devBuildRepositoryProvider).myOrganisation(),
);
final dbMyProjectsProvider = FutureProvider.autoDispose<List<DbProject>>(
  (ref) => ref.watch(devBuildRepositoryProvider).myProjects(),
);
final dbMyProjectProvider = FutureProvider.autoDispose
    .family<DbProject, String>(
      (ref, id) => ref.watch(devBuildRepositoryProvider).myProject(id),
    );
final dbMyContactEventsProvider =
    FutureProvider.autoDispose<List<ContactEvent>>(
      (ref) => ref.watch(devBuildRepositoryProvider).myContactEvents(),
    );
final dbMyEngagementsProvider = FutureProvider.autoDispose<List<Engagement>>(
  (ref) => ref.watch(devBuildRepositoryProvider).myEngagements(),
);

/// Where the current session may go. Route guards only improve UX; the repository re-checks.
enum WorkspaceGate {
  signedOut,
  notBusiness,
  onboarding,
  pending,
  awaitingSecond,
  resubmission,
  rejected,
  suspended,
  approved,
}

class WorkspaceAccess {
  final WorkspaceGate gate;
  final ProType? type;
  final GrantState? grant;
  final ReviewStage? stage;
  const WorkspaceAccess(this.gate, {this.type, this.grant, this.stage});
  bool get approved => gate == WorkspaceGate.approved;
}

WorkspaceAccess workspaceAccessOf(MeSession? me) {
  if (me == null) return const WorkspaceAccess(WorkspaceGate.signedOut);
  final type = proTypeOfPurpose(me.purpose);
  if (type == null) return const WorkspaceAccess(WorkspaceGate.notBusiness);
  return switch (me.grant) {
    null || GrantState.draft => WorkspaceAccess(
      WorkspaceGate.onboarding,
      type: type,
      grant: me.grant,
    ),
    GrantState.pendingVerification => WorkspaceAccess(
      me.stage == ReviewStage.awaitingSecondApproval
          ? WorkspaceGate.awaitingSecond
          : WorkspaceGate.pending,
      type: type,
      grant: me.grant,
      stage: me.stage,
    ),
    GrantState.approved => WorkspaceAccess(
      WorkspaceGate.approved,
      type: type,
      grant: me.grant,
    ),
    GrantState.resubmissionRequired => WorkspaceAccess(
      WorkspaceGate.resubmission,
      type: type,
      grant: me.grant,
    ),
    GrantState.rejected => WorkspaceAccess(
      WorkspaceGate.rejected,
      type: type,
      grant: me.grant,
    ),
    GrantState.suspended => WorkspaceAccess(
      WorkspaceGate.suspended,
      type: type,
      grant: me.grant,
    ),
  };
}

final workspaceAccessProvider = FutureProvider.autoDispose<WorkspaceAccess>((
  ref,
) async {
  try {
    return workspaceAccessOf(await ref.watch(meProvider.future));
  } catch (_) {
    return const WorkspaceAccess(WorkspaceGate.signedOut);
  }
});

/// Directory page keyed by query and page size. Load-more widens the size.
final dbProfessionalsProvider = FutureProvider.autoDispose
    .family<DbPage<DbProfessional>, (DbQuery, int)>(
      (ref, k) => ref
          .watch(devBuildRepositoryProvider)
          .professionals(k.$1, limit: k.$2),
    );

/// One pin on the results map. Developers pin at approved project locations; every other
/// firm pins at its office.
class DbMapPoint {
  final DbProfessional pro;
  final String label;
  final double latitude, longitude;
  const DbMapPoint(this.pro, this.label, this.latitude, this.longitude);
}

class DbMapData {
  final List<DbMapPoint> points;
  final int withoutLocation;
  const DbMapData(this.points, this.withoutLocation);
}

final dbMapDataProvider = FutureProvider.autoDispose.family<DbMapData, DbQuery>(
  (ref, q) async {
    final repo = ref.watch(devBuildRepositoryProvider);
    final page = await repo.professionals(q, limit: 100);
    final points = <DbMapPoint>[];
    var missing = 0;
    for (final p in page.items) {
      if (p.type == ProType.developer) {
        final projects = await repo.approvedProjects(p.id);
        final located = [
          for (final x in projects)
            if (x.latitude != null && x.longitude != null) x,
        ];
        if (located.isEmpty) {
          missing++;
        } else {
          for (final x in located) {
            points.add(DbMapPoint(p, x.name, x.latitude!, x.longitude!));
          }
        }
      } else if (p.latitude != null && p.longitude != null) {
        points.add(DbMapPoint(p, p.name, p.latitude!, p.longitude!));
      } else {
        missing++;
      }
    }
    return DbMapData(points, missing);
  },
);

/// First developer that has an approved project: the only thing the "featured" slot may show.
final dbFeaturedProvider =
    FutureProvider.autoDispose<(DbProfessional, DbProject)?>((ref) async {
      final repo = ref.watch(devBuildRepositoryProvider);
      final page = await repo.professionals(
        const DbQuery(type: ProType.developer),
        limit: 20,
      );
      for (final p in page.items) {
        final projects = await repo.approvedProjects(p.id);
        if (projects.isNotEmpty) return (p, projects.first);
      }
      return null;
    });
