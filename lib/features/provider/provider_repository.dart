import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/backend_mode.dart';
import '../../core/config/qa_faults.dart';
import '../../data/api/account_api.dart' show ApiErrorCode, ApiException;
import '../maintenance/maintenance_models.dart';
import '../maintenance/maintenance_repository.dart';

/// Maintenance providers are NOT a public signup role. An administrator invites them with a
/// one-time link (architecture: roles and signup). Everything here goes through contracts with an
/// "unavailable" production implementation and a labelled in-memory demo.

enum InviteProblem { invalid, expired, used }

class InviteException implements Exception {
  final InviteProblem problem;
  const InviteException(this.problem);
}

/// What an invitation carries: the categories the administrator invited the business for.
class InviteInfo {
  final String code;
  final List<MaintenanceService> services;
  const InviteInfo(this.code, this.services);
}

class ProviderSetup {
  final String businessName, phone;
  final List<MaintenanceService> services;

  /// File names only; the demo keeps no content. CR certificate and municipal licence are required.
  final String crName, licenceName;
  const ProviderSetup({
    required this.businessName,
    required this.phone,
    required this.services,
    required this.crName,
    required this.licenceName,
  });
}

/// pendingVerification -> approved | resubmissionRequired. Only an administrator decides.
enum ProviderGrant { pendingVerification, approved, resubmissionRequired }

class ProviderAccount {
  final String providerId;
  final String businessName;
  final List<MaintenanceService> services;
  final ProviderGrant grant;
  const ProviderAccount({
    required this.providerId,
    required this.businessName,
    required this.services,
    required this.grant,
  });
  bool get canWork => grant == ProviderGrant.approved;
}

abstract class ProviderInviteRepository {
  Future<InviteInfo> check(String code);
  Future<ProviderAccount> accept(String code, ProviderSetup setup);

  /// The signed-in provider account, or null when this session is not a provider.
  Future<ProviderAccount?> account();
}

class UnavailableProviderInviteRepository implements ProviderInviteRepository {
  const UnavailableProviderInviteRepository();
  Never _no() => throw const ApiException(ApiErrorCode.network);
  @override
  Future<InviteInfo> check(String code) async => _no();
  @override
  Future<ProviderAccount> accept(String code, ProviderSetup setup) async =>
      _no();
  @override
  Future<ProviderAccount?> account() async => _no();
}

/// The demo keeps three clearly named fixtures so every invitation state can be reached.
const kDemoInviteOk = 'DEMO-INVITE';
const kDemoInviteExpired = 'DEMO-EXPIRED';
const kDemoInviteUsed = 'DEMO-USED';

class DemoProviderInviteRepository implements ProviderInviteRepository {
  DemoProviderInviteRepository({
    this.latency = const Duration(milliseconds: 300),
  });
  final Duration latency;
  final Set<String> _used = {kDemoInviteUsed};
  ProviderAccount? _account;
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

  @override
  Future<InviteInfo> check(String code) async {
    await _lag();
    final c = code.trim().toUpperCase();
    if (_used.contains(c)) throw const InviteException(InviteProblem.used);
    if (c == kDemoInviteExpired)
      throw const InviteException(InviteProblem.expired);
    if (c != kDemoInviteOk) throw const InviteException(InviteProblem.invalid);
    return InviteInfo(c, MaintenanceService.values);
  }

  @override
  Future<ProviderAccount> accept(String code, ProviderSetup setup) async {
    await check(code);
    _used.add(code.trim().toUpperCase());
    return _account = ProviderAccount(
      providerId: 'b4',
      businessName: setup.businessName,
      services: setup.services,
      grant: ProviderGrant.pendingVerification,
    );
  }

  @override
  Future<ProviderAccount?> account() async {
    await _lag();
    return _account;
  }

  /// QA only: the administrator's decision.
  void debugGrant(ProviderGrant g) {
    final a = _account;
    if (a != null) {
      _account = ProviderAccount(
        providerId: a.providerId,
        businessName: a.businessName,
        services: a.services,
        grant: g,
      );
    }
  }

  /// QA only: a session that is already an approved provider (skips the invitation).
  void debugSignInApproved() {
    _account = const ProviderAccount(
      providerId: 'b4',
      businessName: 'Demo maintenance business',
      services: MaintenanceService.values,
      grant: ProviderGrant.approved,
    );
  }
}

/// Provider side of the same bookings a customer makes. A provider only ever sees requests for their
/// own business; confirm and decline apply only to a request that is still requested, completion only
/// to a confirmed one, and a failed call never shows a status the service did not give.
abstract class ProviderWorkRepository {
  Future<List<MaintenanceBooking>> requests(String providerId);
  Future<MaintenanceBooking?> request(String providerId, String id);
  Future<MaintenanceBooking> respond(
    String providerId,
    String id, {
    required bool confirm,
  });
  Future<MaintenanceBooking> complete(String providerId, String id);
}

class UnavailableProviderWorkRepository implements ProviderWorkRepository {
  const UnavailableProviderWorkRepository();
  Never _no() => throw const ApiException(ApiErrorCode.network);
  @override
  Future<List<MaintenanceBooking>> requests(String providerId) async => _no();
  @override
  Future<MaintenanceBooking?> request(String providerId, String id) async =>
      _no();
  @override
  Future<MaintenanceBooking> respond(
    String providerId,
    String id, {
    required bool confirm,
  }) async => _no();
  @override
  Future<MaintenanceBooking> complete(String providerId, String id) async =>
      _no();
}

class DemoProviderWorkRepository implements ProviderWorkRepository {
  DemoProviderWorkRepository(this._store);
  final DemoMaintenanceRepository _store;

  @override
  Future<List<MaintenanceBooking>> requests(String providerId) =>
      _store.forProvider(providerId);

  @override
  Future<MaintenanceBooking?> request(String providerId, String id) async {
    final b = await _store.get(id);
    if (b == null) return null;
    if (b.providerId != providerId) throw const ProviderNotYoursException();
    return b;
  }

  @override
  Future<MaintenanceBooking> respond(
    String providerId,
    String id, {
    required bool confirm,
  }) async {
    await request(providerId, id);
    return _store.respond(id, confirm: confirm);
  }

  @override
  Future<MaintenanceBooking> complete(String providerId, String id) async {
    await request(providerId, id);
    return _store.complete(id);
  }
}

/// A request that belongs to another business.
class ProviderNotYoursException implements Exception {
  const ProviderNotYoursException();
}

final providerInviteRepositoryProvider = Provider<ProviderInviteRepository>(
  (ref) => kUseDemoBackend
      ? DemoProviderInviteRepository()
      : const UnavailableProviderInviteRepository(),
);
final providerWorkRepositoryProvider = Provider<ProviderWorkRepository>((ref) {
  final store = ref.watch(maintenanceRepositoryProvider);
  return store is DemoMaintenanceRepository
      ? DemoProviderWorkRepository(store)
      : const UnavailableProviderWorkRepository();
});
final providerAccountProvider = FutureProvider.autoDispose<ProviderAccount?>(
  (ref) => ref.watch(providerInviteRepositoryProvider).account(),
);
final providerRequestsProvider = FutureProvider.autoDispose
    .family<List<MaintenanceBooking>, String>(
      (ref, providerId) =>
          ref.watch(providerWorkRepositoryProvider).requests(providerId),
    );
final providerRequestProvider = FutureProvider.autoDispose
    .family<MaintenanceBooking?, ({String providerId, String id})>(
      (ref, k) =>
          ref.watch(providerWorkRepositoryProvider).request(k.providerId, k.id),
    );
