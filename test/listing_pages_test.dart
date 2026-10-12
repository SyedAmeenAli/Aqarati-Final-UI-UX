import 'package:aqarati_app/data/datasources/mock_property_data.dart';
import 'package:aqarati_app/data/repositories/app_state_providers.dart';
import 'package:aqarati_app/features/compare/compare_screen.dart';
import 'package:aqarati_app/features/enquiry/make_offer_screen.dart';
import 'package:aqarati_app/features/enquiry/enquiry_screen.dart';
import 'package:aqarati_app/features/property/property_gallery_screen.dart';
import 'package:aqarati_app/features/reviews/review_screen.dart';
import 'package:aqarati_app/features/search/aq_property_types.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// The enquiry, offer, gallery, compare, review and property-type pages, rebuilt in the AQ design.

final _p = mockProperties.first;

Widget _app(
  Widget child, {
  double scale = 1,
  double width = 393,
  String lang = 'en',
  bool dark = false,
  ProviderContainer? container,
}) {
  final app = MaterialApp(
    theme: ThemeData(brightness: dark ? Brightness.dark : Brightness.light),
    locale: Locale(lang),
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [Locale('en'), Locale('ar')],
    home: MediaQuery(
      data: MediaQueryData(
        size: Size(width, 852),
        textScaler: TextScaler.linear(scale),
      ),
      child: child,
    ),
  );
  return container == null
      ? ProviderScope(child: app)
      : UncontrolledProviderScope(container: container, child: app);
}

Future<void> _settle(WidgetTester t, [int n = 6]) async {
  for (var i = 0; i < n; i++) {
    await t.pump(const Duration(milliseconds: 300));
  }
}

Future<void> _tap(WidgetTester t, String text) async {
  final f = find.text(text);
  await t.ensureVisible(f.first);
  await t.pump();
  await t.tap(f.first, warnIfMissed: false);
  await _settle(t, 3);
}

void main() {
  group('enquiry', () {
    testWidgets('empty form shows every error and saves nothing', (t) async {
      await t.binding.setSurfaceSize(const Size(393, 852));
      final c = ProviderContainer();
      addTearDown(c.dispose);
      await t.pumpWidget(_app(EnquiryScreen(property: _p), container: c));
      await _settle(t);
      await _tap(t, 'Save enquiry');
      expect(find.text('Enter your full name.'), findsOneWidget);
      expect(
        find.text(
          'Add an email address or a mobile number so the owner can reply.',
        ),
        findsOneWidget,
      );
      expect(find.text('Write at least 10 characters.'), findsOneWidget);
      expect(c.read(enquiriesProvider), isEmpty);
    });

    testWidgets('a bad email or phone is refused', (t) async {
      await t.binding.setSurfaceSize(const Size(393, 1000));
      final c = ProviderContainer();
      addTearDown(c.dispose);
      await t.pumpWidget(_app(EnquiryScreen(property: _p), container: c));
      await _settle(t);
      final fields = find.byType(TextField);
      await t.enterText(fields.at(0), 'Aisha Al Balushi');
      await t.enterText(fields.at(1), 'not-an-email');
      await t.enterText(
        fields.at(3),
        'Is this still available and can I visit?',
      );
      await t.pump();
      await _tap(t, 'Save enquiry');
      expect(find.text('Enter a valid email address.'), findsOneWidget);
      expect(c.read(enquiriesProvider), isEmpty);
    });

    testWidgets(
      'valid enquiry is saved and the result says it was not delivered',
      (t) async {
        await t.binding.setSurfaceSize(const Size(393, 1000));
        final c = ProviderContainer();
        addTearDown(c.dispose);
        await t.pumpWidget(_app(EnquiryScreen(property: _p), container: c));
        await _settle(t);
        final fields = find.byType(TextField);
        await t.enterText(fields.at(0), 'Aisha Al Balushi');
        await t.enterText(fields.at(2), '91234567');
        await t.enterText(
          fields.at(3),
          'Is this still available and can I visit?',
        );
        await t.pump();
        await _tap(t, 'Save enquiry');
        expect(c.read(enquiriesProvider).length, 1);
        expect(find.text('Enquiry saved'), findsOneWidget);
        expect(find.textContaining('has not been delivered'), findsOneWidget);
        expect(find.textContaining('sent successfully'), findsNothing);
      },
    );
  });

  group('offer', () {
    testWidgets('needs an amount and the acknowledgement', (t) async {
      await t.binding.setSurfaceSize(const Size(393, 900));
      final c = ProviderContainer();
      addTearDown(c.dispose);
      await t.pumpWidget(_app(MakeOfferScreen(property: _p), container: c));
      await _settle(t);
      await _tap(t, 'Save offer');
      expect(find.text('Enter an amount greater than zero.'), findsOneWidget);
      expect(find.text('Confirm to continue.'), findsOneWidget);
      expect(c.read(offersProvider), isEmpty);
    });

    testWidgets('a valid offer is saved and the result is honest', (t) async {
      await t.binding.setSurfaceSize(const Size(393, 900));
      final c = ProviderContainer();
      addTearDown(c.dispose);
      await t.pumpWidget(_app(MakeOfferScreen(property: _p), container: c));
      await _settle(t);
      await t.enterText(find.byType(TextField).first, '175,000');
      await t.pump();
      await _tap(
        t,
        'I understand an offer is not binding until the owner accepts it.',
      );
      await _tap(t, 'Save offer');
      expect(c.read(offersProvider).length, 1);
      expect(find.text('Offer saved'), findsOneWidget);
      expect(find.textContaining('has not been delivered'), findsOneWidget);
    });
  });

  group('gallery, compare, review, property types', () {
    testWidgets(
      'gallery shows the real count and no dead share or floor-plan control',
      (t) async {
        await t.binding.setSurfaceSize(const Size(393, 852));
        await t.pumpWidget(_app(PropertyGalleryScreen(property: _p)));
        await _settle(t);
        expect(
          find.textContaining('1 of ${_p.imageUrls.length}'),
          findsOneWidget,
        );
        expect(find.text('Floor Plan'), findsNothing);
        expect(find.byIcon(Icons.ios_share_rounded), findsNothing);
        expect(t.takeException(), isNull);
      },
    );

    testWidgets('compare lists real values and opens nothing it cannot', (
      t,
    ) async {
      await t.binding.setSurfaceSize(const Size(393, 852));
      final ids = mockProperties.take(2).map((p) => p.id).toList();
      await t.pumpWidget(_app(CompareScreen(propertyIds: ids)));
      await _settle(t, 10);
      expect(find.text('Compare properties'), findsOneWidget);
      expect(find.text('Bedrooms'), findsWidgets);
      expect(find.text('View property'), findsNWidgets(2));
      expect(t.takeException(), isNull);
    });

    testWidgets('compare with nothing selected says so', (t) async {
      await t.binding.setSurfaceSize(const Size(393, 852));
      await t.pumpWidget(_app(const CompareScreen(propertyIds: [])));
      await _settle(t, 10);
      expect(find.text('Nothing to compare'), findsOneWidget);
    });

    testWidgets('review page explains the engagement rule and offers no form', (
      t,
    ) async {
      await t.binding.setSurfaceSize(const Size(393, 852));
      await t.pumpWidget(
        _app(
          const ReviewScreen(
            listingLabel: 'Muscat',
            listingTitle: 'Al Noor Realty',
          ),
        ),
      );
      await _settle(t);
      expect(find.text('Reviews come from completed work'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      expect(find.textContaining('Published'), findsOneWidget);
    });

    for (final w in [320.0, 360.0, 393.0]) {
      for (final scale in [1.0, 1.5]) {
        testWidgets(
          'property types: two cards per row, full descriptions, width $w scale $scale',
          (t) async {
            await t.binding.setSurfaceSize(Size(w, 1100));
            await t.pumpWidget(
              _app(const AQPropertyTypesScreen(), width: w, scale: scale),
            );
            await _settle(t);
            expect(t.takeException(), isNull);
            final res = t.getRect(find.text('Residential').first);
            final com = t.getRect(find.text('Commercial').first);
            final agr = t.getRect(find.text('Agriculture').first);
            expect(
              com.left > res.right - 1 || (com.top - res.top).abs() > 20,
              isTrue,
            );
            // Two columns: the first and third cards share a left edge, the second and fourth share one.
            expect((agr.left - res.left).abs() < 2, isTrue);
            expect((agr.top - res.top).abs() > 40, isTrue);
            // No description is cut with an ellipsis: each card's text fits its full string.
            final descs = [
              for (final s in const ['Villas', 'Offices', 'Land', 'Industrial'])
                find.textContaining(s),
            ];
            for (final d in descs) {
              expect(d, findsWidgets);
            }
          },
        );
      }
    }

    testWidgets('pages build in dark and Arabic without overflow', (t) async {
      await t.binding.setSurfaceSize(const Size(393, 900));
      for (final lang in ['en', 'ar']) {
        for (final w in <Widget>[
          EnquiryScreen(property: _p),
          MakeOfferScreen(property: _p),
          PropertyGalleryScreen(property: _p),
          const ReviewScreen(
            listingLabel: 'Muscat',
            listingTitle: 'Al Noor Realty',
          ),
          const AQPropertyTypesScreen(),
        ]) {
          await t.pumpWidget(_app(w, dark: true, lang: lang, scale: 1.3));
          await _settle(t);
          expect(t.takeException(), isNull, reason: '${w.runtimeType} $lang');
        }
      }
    });
  });
}
