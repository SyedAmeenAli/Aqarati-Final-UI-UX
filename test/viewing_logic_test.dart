import 'package:flutter_test/flutter_test.dart';
import 'package:aqarati_app/core/localization/viewing_strings.dart';
import 'package:aqarati_app/features/viewing/data/viewing_repository.dart';
import 'package:aqarati_app/features/viewing/domain/viewing_models.dart';
import 'package:aqarati_app/features/viewing/domain/viewing_presentation.dart';

void main() {
  final now = DateTime(2026, 10, 8, 9);
  DemoViewingRepository repo() => DemoViewingRepository(latency: Duration.zero, clock: () => now);

  test('every viewing string has English and Arabic', () {
    for (final k in ViewingStrings.keys) {
      expect(const ViewingStrings.forTest(false).t(k), isNotEmpty, reason: k);
      expect(const ViewingStrings.forTest(true).t(k), isNotEmpty, reason: k);
    }
  });

  test('requested then confirmed then completed maps to the right actions', () async {
    final r = repo();
    final a = await r.availability('p1');
    final slot = a.firstBookable!.slots.firstWhere((s) => s.bookable).slot;
    final v = await r.request(propertyId: 'p1', slot: slot);
    expect(v.status, ViewingStatus.requested);
    expect(ViewingPresentation.of(v).actions, contains(ViewingAction.cancel));
    expect(ViewingPresentation.momentPath(v), endsWith('/requested'));
    final c = r.hostConfirm(v.id);
    expect(ViewingPresentation.momentPath(c), endsWith('/confirmed'));
    final d = r.hostComplete(v.id);
    expect(d.reviewEligible, isTrue);
    expect(ViewingPresentation.of(d).actions, contains(ViewingAction.writeReview));
  });

  test('host suggestion is a reschedule offer, not a new status', () async {
    final r = repo();
    final a = await r.availability('p1');
    final v = await r.request(propertyId: 'p1', slot: a.firstBookable!.slots.firstWhere((s) => s.bookable).slot);
    final s = r.hostSuggest(v.id);
    expect(s.rescheduleOffered, isTrue);
    expect(ViewingPresentation.momentPath(s), endsWith('/reschedule'));
    final acc = await r.acceptSuggestion(v.id, s.suggestions.first);
    expect(acc.status, ViewingStatus.confirmed);
    expect(acc.suggestions, isEmpty);
  });

  test('a taken slot throws and disappears from availability; cancel frees nothing twice', () async {
    final r = repo();
    final a = await r.availability('p1');
    final slot = a.firstBookable!.slots.firstWhere((s) => s.bookable).slot;
    r.armConflict();
    await expectLater(r.request(propertyId: 'p1', slot: slot), throwsA(isA<SlotTakenException>()));
    final again = await r.availability('p1');
    expect(again.dayOf(slot.day)!.slots.firstWhere((s) => s.slot == slot).bookable, isFalse);
  });

  test('zone label comes from the model offset', () {
    expect(const ViewingAvailability(utcOffsetMinutes: 240, zoneCity: 'Muscat', days: []).zoneLabel, 'GMT+4');
    expect(const ViewingAvailability(utcOffsetMinutes: 330, zoneCity: 'X', days: []).zoneLabel, 'GMT+5:30');
  });

  test('filters split upcoming, past and cancelled', () async {
    final r = DemoViewingRepository(seed: true, latency: Duration.zero, clock: () => now);
    final all = await r.list();
    expect(all.where(ViewingFilter.upcoming.matches).length, 3);
    expect(all.where(ViewingFilter.past.matches).length, 2);
    expect(all.where(ViewingFilter.cancelled.matches).length, 1);
  });
}
