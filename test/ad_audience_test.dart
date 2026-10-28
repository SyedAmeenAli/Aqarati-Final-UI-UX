import 'package:aqarati_app/features/ads/ad_models.dart';
import 'package:aqarati_app/features/ads/ad_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('sponsored campaigns by Home audience', () {
    test('each of the six Homes is served exactly one seeded campaign', () async {
      final repo = DemoAdRepository(latency: Duration.zero);
      seedSampleCampaigns(repo);
      for (final a in AdAudience.values) {
        final served = await repo.served(AdPlacement.homeTop, audience: a);
        final ids = served.map((x) => x.id).toList();
        expect(served.where((x) => x.audiences.contains(a)).length, served.length);
        expect(ids.toSet().length, ids.length, reason: 'no campaign twice on one Home');
        expect(served, isNotEmpty, reason: '$a has a banner');
      }
    });

    test('paused and waiting campaigns are never served', () async {
      final repo = DemoAdRepository(latency: Duration.zero);
      seedSampleCampaigns(repo);
      final all = [
        for (final a in AdAudience.values) ...await repo.served(AdPlacement.homeTop, audience: a),
      ];
      expect(all.map((x) => x.id), isNot(contains('s7')));
      expect(all.map((x) => x.id), isNot(contains('s8')));
    });

    test('a draft needs at least one audience', () {
      const d = AdDraft(sponsor: 's', headline: 'h', cta: 'c', destination: '/app/explore', imageRef: 'x', audiences: {});
      expect(validateAd(d)['audience'], isNotNull);
    });

    test('a path the app does not have falls back; a real one and https are kept', () {
      expect(adInAppRoute('/nope/here'), kAdFallbackRoute);
      expect(adInAppRoute('/properties?cat=residential'), '/properties?cat=residential');
      expect(adInAppRoute('https://example.com/x'), isNull);
    });

    test('sample destinations all point at real screens', () {
      for (final c in kSampleCampaigns) {
        expect(adInAppRoute(c.$7), c.$7);
      }
    });
  });
}
