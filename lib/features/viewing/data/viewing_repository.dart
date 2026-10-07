import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/backend_mode.dart';
import '../../../data/models/property.dart';
import '../../../data/repositories/providers.dart';
import '../domain/viewing_models.dart';

/// Frontend contract for property viewings. The real API for these calls is not
/// confirmed yet (see STARTUP_NATIVE_CHECKLIST.md); screens depend only on this.
abstract class ViewingRepository {
  Future<ViewingHost> host(String propertyId);
  Future<ViewingAvailability> availability(String propertyId);
  /// Throws [SlotTakenException] if the slot was consumed meanwhile.
  Future<Viewing> request({required String propertyId, required ViewingSlot slot});
  Future<Viewing> cancel(String id);
  Future<Viewing> acceptSuggestion(String id, ViewingSlot slot);
  Future<Viewing> declineSuggestion(String id);
  Future<List<Viewing>> list();
  Future<Viewing?> get(String id);
}

/// DEMO data source. In-memory only; not a backend. Host responses are simulated
/// through the `host*` methods, reachable only with `--dart-define=REVIEW_TOOLS=true`.
class DemoViewingRepository implements ViewingRepository {
  DemoViewingRepository({this.seed = false, this.latency = const Duration(milliseconds: 350), DateTime Function()? clock}) : _clock = clock ?? DateTime.now {
    if (seed) _seed();
  }

  final bool seed;
  final Duration latency;
  final DateTime Function() _clock;
  final List<Viewing> _items = [];
  final Map<String, Set<ViewingSlot>> _booked = {};
  bool _conflictNext = false;
  int _seq = 0;

  static const _hosts = {
    'p1': ViewingHost(id: 'h1', name: 'Ahmed Al Rashdi', agency: 'Al Mouj Properties', verified: true, rating: 4.8, reviewCount: 124),
    'p2': ViewingHost(id: 'h2', name: 'Fatma Al Balushi', agency: 'Muscat Coastal Homes', verified: true, rating: 4.7, reviewCount: 86),
    'p4': ViewingHost(id: 'h3', name: 'Salim Al Harthy', agency: 'Salalah Estates', verified: true, rating: 4.6, reviewCount: 61),
  };
  static const _fallbackHost = ViewingHost(id: 'h0', name: 'AQARATI Host', agency: 'Property host', verified: false);
  static ViewingHost hostFor(String propertyId) => _hosts[propertyId] ?? _fallbackHost;

  Future<void> _wait() => latency == Duration.zero ? Future.value() : Future.delayed(latency);

  DateTime get _today {
    final n = _clock();
    return DateTime(n.year, n.month, n.day);
  }

  void armConflict() => _conflictNext = true;
  bool get conflictArmed => _conflictNext;

  @override
  Future<ViewingHost> host(String propertyId) async {
    await _wait();
    return hostFor(propertyId);
  }

  @override
  Future<ViewingAvailability> availability(String propertyId) async {
    await _wait();
    final booked = _booked[propertyId] ?? const <ViewingSlot>{};
    final days = <AvailabilityDay>[];
    for (var d = 1; d <= 14; d++) {
      final date = _today.add(Duration(days: d));
      final friday = date.weekday == DateTime.friday;
      final saturday = date.weekday == DateTime.saturday;
      final slots = <SlotInfo>[];
      for (var i = 0; i < 22; i++) {
        final start = DateTime(date.year, date.month, date.day, 9).add(Duration(minutes: 30 * i));
        final slot = ViewingSlot(start);
        final seedNo = (date.day * 7 + i * 13) % 9;
        var state = seedNo == 0 ? SlotState.unavailable : seedNo == 1 ? SlotState.limited : SlotState.available;
        if (friday || (saturday && start.hour < 14)) state = SlotState.unavailable;
        if (booked.contains(slot)) state = SlotState.unavailable;
        slots.add(SlotInfo(slot, state));
      }
      final free = slots.where((s) => s.bookable).length;
      days.add(AvailabilityDay(date, free == 0 ? DayLoad.none : (saturday || free <= 8 ? DayLoad.limited : DayLoad.open), slots));
    }
    return ViewingAvailability(utcOffsetMinutes: 240, zoneCity: 'Muscat', days: days);
  }

  @override
  Future<Viewing> request({required String propertyId, required ViewingSlot slot}) async {
    await _wait();
    if (_conflictNext) {
      _conflictNext = false;
      (_booked[propertyId] ??= {}).add(slot);
      throw const SlotTakenException();
    }
    if ((_booked[propertyId] ?? const <ViewingSlot>{}).contains(slot)) throw const SlotTakenException();
    (_booked[propertyId] ??= {}).add(slot);
    final v = Viewing(id: 'v${++_seq}', propertyId: propertyId, host: hostFor(propertyId), slot: slot, status: ViewingStatus.requested, createdAt: _clock());
    _items.insert(0, v);
    return v;
  }

  Viewing _update(String id, Viewing Function(Viewing) f) {
    final i = _items.indexWhere((v) => v.id == id);
    if (i < 0) throw const ViewingFailure();
    final next = f(_items[i]);
    _items[i] = next;
    return next;
  }

  @override
  Future<Viewing> cancel(String id) async {
    await _wait();
    return _update(id, (v) {
      (_booked[v.propertyId] ??= {}).remove(v.slot);
      return v.copyWith(status: ViewingStatus.cancelled, suggestions: const []);
    });
  }

  @override
  Future<Viewing> acceptSuggestion(String id, ViewingSlot slot) async {
    await _wait();
    return _update(id, (v) {
      (_booked[v.propertyId] ??= {})..remove(v.slot)..add(slot);
      return v.copyWith(slot: slot, status: ViewingStatus.confirmed, suggestions: const []);
    });
  }

  @override
  Future<Viewing> declineSuggestion(String id) async {
    await _wait();
    return _update(id, (v) => v.copyWith(suggestions: const []));
  }

  @override
  Future<List<Viewing>> list() async {
    await _wait();
    return List.unmodifiable(_items);
  }

  @override
  Future<Viewing?> get(String id) async {
    await _wait();
    for (final v in _items) {
      if (v.id == id) return v;
    }
    return null;
  }

  // ---- Simulated host (REVIEW_TOOLS only) ----
  Viewing hostConfirm(String id) => _update(id, (v) => v.copyWith(status: ViewingStatus.confirmed));
  Viewing hostDecline(String id) => _update(id, (v) => v.copyWith(status: ViewingStatus.declined));
  Viewing hostSuggest(String id) {
    final v = _items.firstWhere((x) => x.id == id);
    final base = DateTime(v.slot.start.year, v.slot.start.month, v.slot.start.day).add(const Duration(days: 1));
    return _update(id, (x) => x.copyWith(suggestions: [
          ViewingSlot(base.add(const Duration(hours: 10, minutes: 30))),
          ViewingSlot(base.add(const Duration(hours: 14))),
          ViewingSlot(base.add(const Duration(days: 1, hours: 9))),
        ]));
  }
  Viewing hostComplete(String id) => _update(id, (v) => v.copyWith(status: ViewingStatus.completed));

  void _seed() {
    final t = _today;
    ViewingSlot at(int days, int h, [int m = 0]) => ViewingSlot(DateTime(t.year, t.month, t.day + days, h, m));
    final now = _clock();
    Viewing mk(String id, String pid, ViewingSlot s, ViewingStatus st, {List<ViewingSlot> sug = const [], String? reason, bool byHost = false}) =>
        Viewing(id: id, propertyId: pid, host: hostFor(pid), slot: s, status: st, createdAt: now, suggestions: sug, declineReason: reason, cancelledByHost: byHost);
    _items.addAll([
      mk('v-seed-1', 'p1', at(2, 10), ViewingStatus.confirmed),
      mk('v-seed-2', 'p1', at(4, 9, 30), ViewingStatus.requested),
      mk('v-seed-3', 'p2', at(3, 10, 30), ViewingStatus.requested, sug: [at(4, 10, 30), at(4, 14), at(5, 9)]),
      mk('v-seed-4', 'p4', at(1, 15), ViewingStatus.declined),
      mk('v-seed-5', 'p1', at(-3, 11), ViewingStatus.completed),
      mk('v-seed-6', 'p2', at(6, 16), ViewingStatus.cancelled),
    ]);
    _seq = 6;
  }
}

final viewingRepositoryProvider = Provider<ViewingRepository>((ref) => DemoViewingRepository(seed: kShowReviewTools));

final viewingsProvider = FutureProvider.autoDispose<List<Viewing>>((ref) => ref.watch(viewingRepositoryProvider).list());
final viewingProvider = FutureProvider.autoDispose.family<Viewing?, String>((ref, id) => ref.watch(viewingRepositoryProvider).get(id));
final viewingAvailabilityProvider = FutureProvider.autoDispose.family<ViewingAvailability, String>((ref, propertyId) => ref.watch(viewingRepositoryProvider).availability(propertyId));
final viewingHostProvider = FutureProvider.family<ViewingHost, String>((ref, propertyId) => ref.watch(viewingRepositoryProvider).host(propertyId));
final viewingPropertyProvider = FutureProvider.family<Property?, String>((ref, id) => ref.watch(propertyRepositoryProvider).getById(id));

/// What the user has picked so far for one property. Survives screen changes and conflicts.
class ViewingDraft {
  final DateTime? day;
  final ViewingSlot? slot;
  final ViewingSlot? takenSlot;
  const ViewingDraft({this.day, this.slot, this.takenSlot});
}

class ViewingDraftNotifier extends FamilyNotifier<ViewingDraft, String> {
  @override
  ViewingDraft build(String arg) => const ViewingDraft();

  void selectDay(DateTime d) {
    final keep = state.slot != null && state.slot!.day == DateTime(d.year, d.month, d.day);
    state = ViewingDraft(day: DateTime(d.year, d.month, d.day), slot: keep ? state.slot : null, takenSlot: state.takenSlot);
  }

  void selectSlot(ViewingSlot s) => state = ViewingDraft(day: s.day, slot: s, takenSlot: state.takenSlot);
  void markTaken(ViewingSlot s) => state = ViewingDraft(day: s.day, slot: null, takenSlot: s);
  void clear() => state = const ViewingDraft();
}

final viewingDraftProvider = NotifierProvider.family<ViewingDraftNotifier, ViewingDraft, String>(ViewingDraftNotifier.new);
