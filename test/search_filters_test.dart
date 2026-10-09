import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:aqarati_app/data/models/enums.dart';
import 'package:aqarati_app/data/repositories/app_state_providers.dart';
import 'package:aqarati_app/data/repositories/providers.dart';
import 'package:aqarati_app/features/search/aq_filters.dart';
import 'package:aqarati_app/features/business/aq_business_profile.dart';
import 'package:aqarati_app/features/business/aq_professionals.dart';
import 'package:aqarati_app/features/saved/saved_screen.dart';
import 'package:aqarati_app/features/search/aq_map.dart';
import 'package:aqarati_app/features/search/aq_search.dart';
import 'package:aqarati_app/features/workspace/aq_home.dart';

Widget _app(Widget child, {double scale = 1}) => ProviderScope(
      child: MaterialApp(
        localizationsDelegates: const [GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
        supportedLocales: const [Locale('en'), Locale('ar')],
        home: MediaQuery(data: MediaQueryData(size: const Size(393, 852), textScaler: TextScaler.linear(scale)), child: child),
      ),
    );

void main() {
  test('filters narrow and sort the listing', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final all = await container.read(propertyRepositoryProvider).search();
    expect(all, isNotEmpty);

    final buy = AQFilters(tx: TransactionType.buy).apply(all);
    expect(buy.every((p) => p.transactionType == TransactionType.buy), isTrue);

    final (lo, hi) = aqPriceBounds(all, TransactionType.buy);
    expect(hi, greaterThan(lo));
    final cheap = AQFilters(tx: TransactionType.buy, maxPrice: (lo + hi) / 2).apply(all);
    expect(cheap.every((p) => p.price.amount <= (lo + hi) / 2), isTrue);

    final sorted = AQFilters(sort: AQSort.priceHigh).apply(all);
    for (var i = 1; i < sorted.length; i++) {
      expect(sorted[i - 1].price.amount >= sorted[i].price.amount, isTrue);
    }

    final f = AQFilters(beds: 3, verifiedOnly: true)..areas.add('Muscat');
    expect(f.activeCount, 3);
    f.reset();
    expect(f.activeCount, 0);
    expect(f.apply(all).length, all.length);
  });

  test('query ignores filler words and plurals', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final all = await container.read(propertyRepositoryProvider).search();
    final villa = all.firstWhere((p) => p.type == PropertyType.villa);
    expect(AQFilters().apply(all, query: 'Villas in ${villa.area}').contains(villa), isTrue);
    expect(AQFilters().apply(all, query: 'zzzz nothing').isEmpty, isTrue);
  });

  for (final scale in [1.0, 2.0]) {
    testWidgets('Search home builds at text scale $scale', (t) async {
      await t.binding.setSurfaceSize(const Size(393, 852));
      await t.pumpWidget(_app(const SearchScreen(), scale: scale));
      await t.pump(const Duration(seconds: 1));
      expect(t.takeException(), isNull);
      await t.enterText(find.byType(TextField), 'villa');
      await t.pump(const Duration(seconds: 1));
      await t.pump(const Duration(seconds: 2));
      expect(t.takeException(), isNull);
    });

    testWidgets('Results and filter sheet build at text scale $scale', (t) async {
      await t.binding.setSurfaceSize(const Size(393, 852));
      await t.pumpWidget(_app(const SearchResultsScreen(initialQuery: 'villa'), scale: scale));
      await t.pump(const Duration(seconds: 1));
      await t.pump(const Duration(seconds: 1));
      expect(t.takeException(), isNull);
      await t.tap(find.bySemanticsLabel(RegExp(r'^Filters')).first);
      await t.pump(const Duration(seconds: 1));
      await t.pump(const Duration(seconds: 1));
      expect(t.takeException(), isNull);
      expect(find.text('Refine your search to find the perfect property.'), findsOneWidget);
    });

    testWidgets('Properties page builds at text scale $scale', (t) async {
      await t.binding.setSurfaceSize(const Size(393, 852));
      await t.pumpWidget(_app(const AQPropertiesScreen(), scale: scale));
      await t.pump(const Duration(seconds: 1));
      await t.pump(const Duration(seconds: 1));
      expect(t.takeException(), isNull);
    });

    testWidgets('Map screen builds at text scale $scale', (t) async {
      await t.binding.setSurfaceSize(const Size(393, 852));
      await t.pumpWidget(_app(const AQMapScreen(), scale: scale));
      await t.pump(const Duration(seconds: 1));
      await t.pump(const Duration(seconds: 2));
      expect(t.takeException(), isNull);
    });

    testWidgets('Professionals builds at text scale $scale', (t) async {
      await t.binding.setSurfaceSize(const Size(393, 852));
      await t.pumpWidget(_app(const AQProfessionalsScreen(category: 'maintenance'), scale: scale));
      await t.pump(const Duration(seconds: 1));
      await t.pump(const Duration(seconds: 2));
      expect(t.takeException(), isNull);
      expect(find.bySemanticsLabel(RegExp('Rawaq')), findsWidgets);
    });

    testWidgets('Business profile builds at text scale $scale', (t) async {
      await t.binding.setSurfaceSize(const Size(393, 852));
      await t.pumpWidget(_app(const AQBusinessProfileScreen(businessId: 'b2'), scale: scale));
      await t.pump(const Duration(seconds: 1));
      await t.pump(const Duration(seconds: 2));
      expect(t.takeException(), isNull);
      expect(find.textContaining('Namaa'), findsWidgets);
    });

    testWidgets('Saved builds with saved items at text scale $scale', (t) async {
      await t.binding.setSurfaceSize(const Size(393, 852));
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(savedPropertyIdsProvider.notifier).state = {'p1', 'p2', 'p3'};
      await t.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: const [GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
          home: MediaQuery(data: MediaQueryData(size: const Size(393, 852), textScaler: TextScaler.linear(scale)), child: const SavedScreen()),
        ),
      ));
      await t.pump(const Duration(seconds: 1));
      await t.pump(const Duration(seconds: 2));
      expect(t.takeException(), isNull);
    });
  }
}
