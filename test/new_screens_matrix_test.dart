import 'package:aqarati_app/features/workspace/aq_home.dart' show AQHomeScreen;
import 'package:aqarati_app/core/domain/account_models.dart';
import 'package:aqarati_app/data/api/account_api.dart';
import 'package:aqarati_app/data/models/enums.dart';
import 'package:aqarati_app/features/ads/ad_models.dart';
import 'package:aqarati_app/features/ads/ad_repository.dart';
import 'package:aqarati_app/features/entry/models/signup_purpose.dart';
import 'package:aqarati_app/features/leads/lead_models.dart';
import 'package:aqarati_app/features/leads/lead_repository.dart';
import 'package:aqarati_app/features/leads/lead_screens.dart';
import 'package:aqarati_app/features/listings/listing_models.dart';
import 'package:aqarati_app/features/listings/listing_repository.dart';
import 'package:aqarati_app/features/listings/listing_screens.dart';
import 'package:aqarati_app/features/viewing/domain/viewing_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Layout matrix for the screens added with the confirmed workflows: narrow widths, dark, Arabic
/// RTL and 200% text. Release builds do not paint overflow stripes, so this is where overflow is caught.

const _agent = MeSession(
  account: AccountState.active,
  purpose: SignupPurpose.realEstateAgent,
  grant: GrantState.approved,
);

class _Cfg {
  final String name;
  final double width, height, scale;
  final bool dark, rtl;
  const _Cfg(
    this.name,
    this.width,
    this.height, {
    this.scale = 1,
    this.dark = false,
    this.rtl = false,
  });
}

const _configs = [
  _Cfg('320 light', 320, 700),
  _Cfg('320 dark', 320, 700, dark: true),
  _Cfg('360 Arabic RTL', 360, 740, rtl: true),
  _Cfg('393 at 200% text', 393, 852, scale: 2.0),
  _Cfg('430 dark Arabic RTL', 430, 900, dark: true, rtl: true),
];

class _Scene {
  final DemoListingRepository listings = DemoListingRepository(
    latency: Duration.zero,
  );
  final DemoLeadRepository leads = DemoLeadRepository(latency: Duration.zero);
  final DemoAdRepository ads = DemoAdRepository(latency: Duration.zero);
  late String listingId;
  late String contactId, viewingId, enquiryId, requestId;

  Future<void> seed() async {
    final l = await listings.create(
      const ListingInput(
        title: 'Sea view villa with a long title that has to wrap on a narrow screen',
        description: 'Quiet street near the marina.',
        type: PropertyType.villa,
        transaction: TransactionType.buy,
        priceOmr: 250000,
        governorate: 'Muscat',
        wilayat: 'Bawshar',
        sizeSqm: 420,
        bedrooms: 4,
        bathrooms: 3,
        titleDeed: 'DEED123456',
      ),
    );
    listingId = l.id;
    listings.debugSet(l.id, ListingStatus.approved);
    final now = DateTime(2026, 10, 20, 10);
    contactId = leads
        .debugAdd(
          LeadScope.agent,
          (id) => Lead(
            id: id,
            kind: LeadKind.contact,
            receivedAt: now,
            customerName: 'Customer with a rather long name',
            phone: '+968 9000 0001',
            message:
                'Is the property still available? We would like to know more.',
            propertyId: 'p1',
            propertyTitle: 'Palm villa near the sea',
          ),
        )
        .id;
    viewingId = leads
        .debugAdd(
          LeadScope.agent,
          (id) => Lead(
            id: id,
            kind: LeadKind.viewingRequest,
            receivedAt: now,
            customerName: 'Sara',
            phone: '+968 9000 0002',
            propertyId: 'p1',
            propertyTitle: 'Palm villa',
            viewingId: 'v1',
            viewingStatus: ViewingStatus.requested,
            requestedSlot: ViewingSlot(DateTime(2026, 10, 24, 16)),
          ),
        )
        .id;
    enquiryId = leads
        .debugAdd(
          LeadScope.developer,
          (id) => Lead(
            id: id,
            kind: LeadKind.projectEnquiry,
            receivedAt: now,
            customerName: 'Ahmed',
            phone: '+968 9000 0003',
            message: 'Which units are still available?',
            projectId: 'pr1',
            projectName: 'Sample project',
          ),
        )
        .id;
    requestId = leads
        .debugAdd(
          LeadScope.service,
          (id) => Lead(
            id: id,
            kind: LeadKind.serviceRequest,
            receivedAt: now,
            customerName: 'Huda',
            phone: '+968 9000 0004',
            message: 'We would like a quotation.',
            serviceCategory: ServiceCategory.construction,
            serviceLocation: 'Muscat',
            requestedTiming: 'Next month',
          ),
        )
        .id;
    ads.debugAdd(
      const AdDraft(
        sponsor: 'A sponsor with a fairly long name',
        headline: 'A headline that is long enough to wrap',
        body: 'Short supporting text for the banner.',
        cta: 'Learn more',
        destination: '/app/explore',
        imageRef: 'assets/location/11_Muscat_skyline_and_mountains.jpg',
      ),
    );
  }
}

Widget _wrap(_Scene s, _Cfg c, Widget child) => ProviderScope(
  overrides: [
    meProvider.overrideWith((ref) async => _agent),
    listingRepositoryProvider.overrideWithValue(s.listings),
    leadRepositoryProvider.overrideWithValue(s.leads),
    adRepositoryProvider.overrideWithValue(s.ads),
  ],
  child: MaterialApp(
    theme: ThemeData(brightness: c.dark ? Brightness.dark : Brightness.light),
    locale: Locale(c.rtl ? 'ar' : 'en'),
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [Locale('en'), Locale('ar')],
    home: MediaQuery(
      data: MediaQueryData(
        size: Size(c.width, c.height),
        textScaler: TextScaler.linear(c.scale),
      ),
      child: Scaffold(body: child),
    ),
  ),
);

void main() {
  final screens = <String, Widget Function(_Scene)>{
    'Home with the sponsored banner': (s) => const AQHomeScreen(),
    'My listings': (s) => const MyListingsScreen(),
    'Add listing': (s) => const ListingFormScreen(),
    'Edit listing': (s) => ListingFormScreen(editId: s.listingId),
    'Listing detail': (s) => ListingDetailScreen(id: s.listingId),
    'Agent leads': (s) => const LeadInboxScreen(scope: LeadScope.agent),
    'Contact lead': (s) =>
        LeadDetailScreen(scope: LeadScope.agent, id: s.contactId),
    'Viewing request': (s) =>
        LeadDetailScreen(scope: LeadScope.agent, id: s.viewingId),
    'Project enquiries': (s) =>
        const LeadInboxScreen(scope: LeadScope.developer),
    'Project enquiry': (s) =>
        LeadDetailScreen(scope: LeadScope.developer, id: s.enquiryId),
    'Service requests': (s) => const LeadInboxScreen(scope: LeadScope.service),
    'Service request': (s) =>
        LeadDetailScreen(scope: LeadScope.service, id: s.requestId),
  };

  for (final cfg in _configs) {
    group('new screens, ${cfg.name}', () {
      for (final e in screens.entries) {
        testWidgets(e.key, (t) async {
          await t.binding.setSurfaceSize(Size(cfg.width, cfg.height));
          addTearDown(() => t.binding.setSurfaceSize(null));
          final scene = _Scene();
          await scene.seed();
          await t.pumpWidget(_wrap(scene, cfg, e.value(scene)));
          for (var i = 0; i < 6; i++) {
            await t.pump(const Duration(milliseconds: 300));
          }
          expect(t.takeException(), isNull);
        });
      }
    });
  }
}
