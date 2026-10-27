import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/backend_mode.dart';
import '../../core/config/qa_faults.dart';
import '../../data/api/account_api.dart' show ApiErrorCode, ApiException;
import 'maintenance_models.dart';

/// Frontend contract for maintenance booking requests. The real API is not confirmed; screens depend
/// only on this. A request is only ever "requested" until the provider answers; the app never
/// presents a request as confirmed on its own.
abstract class MaintenanceRepository {
  Future<MaintenanceBooking> request({
    required String providerId,
    required String providerName,
    required MaintenanceService service,
    required DateTime date,
    required MaintenanceWindow window,
    String notes = '',
  });
  Future<MaintenanceBooking> cancel(String id);
  Future<List<MaintenanceBooking>> list();
  Future<MaintenanceBooking?> get(String id);
}

/// Used when no real service is wired: every call fails like an offline request.
class UnavailableMaintenanceRepository implements MaintenanceRepository {
  const UnavailableMaintenanceRepository();
  Never _no() => throw const ApiException(ApiErrorCode.network);
  @override
  Future<MaintenanceBooking> request({required String providerId, required String providerName, required MaintenanceService service, required DateTime date, required MaintenanceWindow window, String notes = ''}) async => _no();
  @override
  Future<MaintenanceBooking> cancel(String id) async => _no();
  @override
  Future<List<MaintenanceBooking>> list() async => _no();
  @override
  Future<MaintenanceBooking?> get(String id) async => _no();
}

/// DEMO ONLY: in memory. Provider answers are simulated through [debugSet] (QA tools only).
class DemoMaintenanceRepository implements MaintenanceRepository {
  DemoMaintenanceRepository({this.latency = const Duration(milliseconds: 350), DateTime Function()? clock}) : _clock = clock ?? DateTime.now;
  final Duration latency;
  final DateTime Function() _clock;
  final List<MaintenanceBooking> _items = [];
  int _seq = 0;

  Future<void> _lag() async {
    if (latency > Duration.zero) await Future<void>.delayed(latency);
    if (qaCallsFail()) throw const ApiException(ApiErrorCode.network);
  }

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  Future<MaintenanceBooking> request({required String providerId, required String providerName, required MaintenanceService service, required DateTime date, required MaintenanceWindow window, String notes = ''}) async {
    await _lag();
    final day = _day(date);
    final today = _day(_clock());
    if (day.isBefore(today) || day.difference(today).inDays > kMaintenanceHorizonDays) {
      throw const ApiException(ApiErrorCode.validationFailed);
    }
    final dup = _items.any((b) => b.isOpen && b.providerId == providerId && b.service == service && _day(b.date) == day && b.window == window);
    if (dup) throw const DuplicateBookingException();
    final b = MaintenanceBooking(
      id: 'm${++_seq}',
      providerId: providerId,
      providerName: providerName,
      service: service,
      date: day,
      window: window,
      notes: notes.trim(),
      status: MaintenanceStatus.requested,
      createdAt: _clock(),
    );
    _items.add(b);
    return b;
  }

  @override
  Future<MaintenanceBooking> cancel(String id) async {
    await _lag();
    final i = _items.indexWhere((b) => b.id == id);
    if (i < 0) throw const ApiException(ApiErrorCode.server);
    if (!_items[i].canCancel) throw const ApiException(ApiErrorCode.conflict);
    return _items[i] = _items[i].copyWith(status: MaintenanceStatus.cancelled);
  }

  @override
  Future<List<MaintenanceBooking>> list() async {
    await _lag();
    return List.unmodifiable(_items.reversed);
  }

  @override
  Future<MaintenanceBooking?> get(String id) async {
    await _lag();
    return _items.where((b) => b.id == id).firstOrNull;
  }

  // ---- provider side (the same store, so the customer sees the provider's answer)
  Future<List<MaintenanceBooking>> forProvider(String providerId) async {
    await _lag();
    return List.unmodifiable(_items.reversed.where((b) => b.providerId == providerId));
  }

  /// requested -> confirmed | declined. Any other state is a conflict and nothing changes.
  Future<MaintenanceBooking> respond(String id, {required bool confirm}) async {
    await _lag();
    final i = _items.indexWhere((b) => b.id == id);
    if (i < 0) throw const ApiException(ApiErrorCode.server);
    if (_items[i].status != MaintenanceStatus.requested) throw const ApiException(ApiErrorCode.conflict);
    return _items[i] = _items[i].copyWith(status: confirm ? MaintenanceStatus.confirmed : MaintenanceStatus.declined);
  }

  /// confirmed -> completed.
  Future<MaintenanceBooking> complete(String id) async {
    await _lag();
    final i = _items.indexWhere((b) => b.id == id);
    if (i < 0) throw const ApiException(ApiErrorCode.server);
    if (_items[i].status != MaintenanceStatus.confirmed) throw const ApiException(ApiErrorCode.conflict);
    return _items[i] = _items[i].copyWith(status: MaintenanceStatus.completed);
  }

  /// QA only: simulates the provider's answer.
  void debugSet(String id, MaintenanceStatus status) {
    final i = _items.indexWhere((b) => b.id == id);
    if (i >= 0) _items[i] = _items[i].copyWith(status: status);
  }
}

final maintenanceRepositoryProvider = Provider<MaintenanceRepository>((ref) => kUseDemoBackend ? DemoMaintenanceRepository() : const UnavailableMaintenanceRepository());
final maintenanceBookingsProvider = FutureProvider.autoDispose<List<MaintenanceBooking>>((ref) => ref.watch(maintenanceRepositoryProvider).list());
final maintenanceBookingProvider = FutureProvider.autoDispose.family<MaintenanceBooking?, String>((ref, id) => ref.watch(maintenanceRepositoryProvider).get(id));
