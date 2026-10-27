import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/backend_mode.dart';
import '../../core/config/qa_faults.dart';
import '../../data/api/account_api.dart' show ApiErrorCode, ApiException;
import '../devbuild/db_models.dart' show PermissionDeniedException;
import '../viewing/domain/viewing_models.dart';
import 'lead_models.dart';

/// Frontend contract for lead inboxes. The service decides which leads and which contact details a
/// caller may see; the app shows only what comes back. There is no lead API in the repository yet,
/// so production wiring answers "unavailable" and nothing is invented.
abstract class LeadRepository {
  Future<List<Lead>> list(LeadScope scope);

  /// Null when it does not exist; throws [PermissionDeniedException] when it is not the caller's.
  Future<Lead?> get(String id);
  Future<Lead> respondToViewing(String leadId, ViewingResponse response);
}

class UnavailableLeadRepository implements LeadRepository {
  const UnavailableLeadRepository();
  Never _no() => throw const ApiException(ApiErrorCode.network);
  @override
  Future<List<Lead>> list(LeadScope scope) async => _no();
  @override
  Future<Lead?> get(String id) async => _no();
  @override
  Future<Lead> respondToViewing(
    String leadId,
    ViewingResponse response,
  ) async => _no();
}

/// DEMO ONLY: starts empty. Leads exist only when a QA control adds a clearly labelled sample.
class DemoLeadRepository implements LeadRepository {
  DemoLeadRepository({this.latency = const Duration(milliseconds: 300)});
  final Duration latency;
  final Map<LeadScope, List<Lead>> _items = {
    for (final s in LeadScope.values) s: [],
  };
  final Set<String> _foreign = {};
  int _seq = 0;

  /// Test and QA hook: the next write fails with this error.
  Object? debugNextError;

  Future<void> _lag() async {
    if (latency > Duration.zero) await Future<void>.delayed(latency);
  }

  @override
  Future<List<Lead>> list(LeadScope scope) async {
    await _lag();
    return List.unmodifiable(_items[scope]!.reversed);
  }

  @override
  Future<Lead?> get(String id) async {
    await _lag();
    if (_foreign.contains(id)) throw const PermissionDeniedException();
    for (final list in _items.values) {
      for (final l in list) {
        if (l.id == id) return l;
      }
    }
    return null;
  }

  @override
  Future<Lead> respondToViewing(String leadId, ViewingResponse response) async {
    await _lag();
    if (qaCallsFail()) throw const ApiException(ApiErrorCode.network);
    final err = debugNextError;
    if (err != null) {
      debugNextError = null;
      throw err;
    }
    for (final list in _items.values) {
      final i = list.indexWhere((l) => l.id == leadId);
      if (i < 0) continue;
      final l = list[i];
      if (!l.canRespondToViewing) {
        throw const ApiException(ApiErrorCode.conflict);
      }
      return list[i] = l.copyWith(
        viewingStatus: response == ViewingResponse.confirm
            ? ViewingStatus.confirmed
            : ViewingStatus.declined,
      );
    }
    throw const ApiException(ApiErrorCode.server);
  }

  /// QA only: adds a sample lead to [scope]. Never called in a normal build.
  Lead debugAdd(LeadScope scope, Lead Function(String id) build) {
    final l = build('ld${++_seq}');
    _items[scope]!.add(l);
    return l;
  }

  /// QA only: an id that belongs to someone else, to prove it cannot be opened.
  String debugForeignId() {
    final id = 'lx${++_seq}';
    _foreign.add(id);
    return id;
  }
}

final leadRepositoryProvider = Provider<LeadRepository>(
  (ref) => kUseDemoBackend
      ? DemoLeadRepository()
      : const UnavailableLeadRepository(),
);
final leadsProvider = FutureProvider.autoDispose.family<List<Lead>, LeadScope>(
  (ref, scope) => ref.watch(leadRepositoryProvider).list(scope),
);
final leadProvider = FutureProvider.autoDispose.family<Lead?, String>(
  (ref, id) => ref.watch(leadRepositoryProvider).get(id),
);

/// Opens the phone dialler. Replaceable in tests. A true result means the dialler was opened, not
/// that a call was made or connected.
abstract class PhoneLauncher {
  Future<bool> dial(String number);
}
