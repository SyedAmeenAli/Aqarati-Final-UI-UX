import 'package:aqarati_app/admin/admin_models.dart';
import 'package:aqarati_app/admin/admin_repository.dart';
import 'package:aqarati_app/data/models/enums.dart';
import 'package:aqarati_app/features/ebroker/ebroker_models.dart';
import 'package:aqarati_app/features/ebroker/ebroker_repository.dart';
import 'package:flutter_test/flutter_test.dart';

EBrokerInput input({String deed = 'DEED123456', String title = 'Sea villa'}) => EBrokerInput(
  title: title,
  description: 'Corner villa',
  type: PropertyType.villa,
  governorate: 'Muscat',
  wilayat: 'Bawshar',
  sizeSqm: 420,
  priceOmr: 250000,
  titleDeed: deed,
  ownerIdName: 'id.jpg',
  deedDocName: 'deed.pdf',
  photoNames: const ['a.jpg'],
  feeAccepted: true,
);

Future<(DemoEBrokerRepository, DemoAdminStore)> setup() async {
  final eb = DemoEBrokerRepository(latency: Duration.zero);
  final store = DemoAdminStore(latency: Duration.zero)..ebroker = eb;
  await store.signIn('senior@demo.test', DemoAdminStore.demoPassword);
  await store.verifyTotp(DemoAdminStore.demoCode);
  return (eb, store);
}

void main() {
  test('a customer e-Broker submission appears in the admin queue as an e-Broker record', () async {
    final (eb, store) = await setup();
    expect(await store.listListings(), isEmpty);
    await eb.submit(input());
    final q = await store.listListings();
    expect(q, hasLength(1));
    expect(q.single.source, ListingSource.eBroker);
    expect(q.single.title, 'Sea villa');
    expect(q.single.location, 'Bawshar, Muscat');
    expect(q.single.priceOmr, 250000);
    expect(q.single.status, ModerationStatus.pending);
    expect(q.single.feeDisclosureAccepted, isTrue);
    expect(q.single.missing, isEmpty, reason: 'a complete submission can be decided');
    // Listing it twice does not duplicate the record.
    expect(await store.listListings(), hasLength(1));
  });

  test('the admin decision reaches the customer record, and only that record', () async {
    final (eb, store) = await setup();
    final a = await eb.submit(input());
    final b = await eb.submit(input(deed: 'DEED999999', title: 'Other plot'));
    final q = await store.listListings();
    final forA = q.firstWhere((l) => l.title == 'Sea villa');
    await store.decideListing(forA.id, Decision.approve);
    final mine = {for (final s in await eb.mine()) s.id: s};
    expect(mine[a.id]!.status, EBrokerStatus.approved);
    expect(mine[b.id]!.status, EBrokerStatus.pendingVerification, reason: 'unrelated record untouched');
  });

  test('changes requested carries the reason to the customer, who can resubmit; the queue shows it again', () async {
    final (eb, store) = await setup();
    final a = await eb.submit(input());
    final l = (await store.listListings()).single;
    await store.decideListing(l.id, Decision.requestResubmission, reason: ReasonCode.docUnreadable, note: 'Deed scan is blurred');
    final back = (await eb.mine()).single;
    expect(back.status, EBrokerStatus.resubmissionRequired);
    expect(back.feedback, contains('Deed scan is blurred'));
    await eb.resubmit(a.id, input(title: 'Sea villa, new scan'));
    final again = (await store.listListings()).single;
    expect(again.id, l.id, reason: 'same record, not a duplicate');
    expect(again.title, 'Sea villa, new scan');
    expect(again.status, ModerationStatus.pending);
    expect(again.history, hasLength(1), reason: 'earlier decision kept');
  });

  test('demo sample records can still be added next to an e-Broker record', () async {
    final (eb, store) = await setup();
    await eb.submit(input());
    await store.listListings();
    store.seedDemoRecords();
    final q = await store.listListings();
    expect(q.length, greaterThan(1));
    expect(q.where((l) => l.source == ListingSource.eBroker).length, greaterThanOrEqualTo(2));
  });
}
