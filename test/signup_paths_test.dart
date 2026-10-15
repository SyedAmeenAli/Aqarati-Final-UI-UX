import 'package:aqarati_app/core/aq/aq_primitives.dart';
import 'package:aqarati_app/core/aq/aq_scene.dart';
import 'package:aqarati_app/core/domain/account_models.dart';
import 'package:aqarati_app/core/localization/entry_strings.dart';
import 'package:aqarati_app/data/demo/demo_providers.dart';
import 'package:aqarati_app/features/entry/models/signup_purpose.dart';
import 'package:aqarati_app/features/entry/screens/purpose_selection_screen.dart';
import 'package:aqarati_app/features/flow/screens/signup_form_screen.dart';
import 'package:aqarati_app/features/flow/state/signup_state.dart';
import 'dart:typed_data';

import 'package:aqarati_app/data/api/account_api.dart';
import 'package:aqarati_app/data/demo/demo_backend.dart';
import 'package:aqarati_app/features/flow/screens/verification_onboarding_screens.dart';
import 'package:aqarati_app/features/flow/state/document_state.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> pumpAt(
  WidgetTester t,
  Widget w, {
  double width = 393,
  double height = 852,
  Brightness brightness = Brightness.light,
  TextDirection dir = TextDirection.ltr,
  bool demo = false,
}) async {
  t.view.physicalSize = Size(width, height);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    ProviderScope(
      overrides: demo ? demoOverrides() : const [],
      child: MaterialApp(
        theme: ThemeData(brightness: brightness),
        builder: (context, child) =>
            Directionality(textDirection: dir, child: child!),
        home: w,
      ),
    ),
  );
  await t.pump(const Duration(milliseconds: 900));
}

const _company = [
  SignupPurpose.constructionCompany,
  SignupPurpose.propertyDevelopmentCompany,
  SignupPurpose.buildingArchitecture,
  SignupPurpose.interiorExteriorDesign,
];

void main() {
  group('purpose selection (SU-01)', () {
    test(
      'exactly the six public paths, in order, with the documented routes',
      () {
        expect(
          signupPurposeOptions.map((o) => o.id).toList(),
          SignupPurpose.values,
        );
        expect(signupPurposeOptions.map((o) => o.route).toList(), [
          '/signup/user',
          '/signup/agent',
          '/signup/construction',
          '/signup/development',
          '/signup/architecture',
          '/signup/interior-exterior',
        ]);
        expect(signupPurposeOptions.length, 6);
      },
    );

    testWidgets(
      'exact card titles and descriptions; nothing preselected; one selection at a time',
      (t) async {
        await pumpAt(t, const PurposeSelectionScreen());
        final s = EntryStrings.of(
          t.element(find.byType(PurposeSelectionScreen)),
        );
        const expected = {
          'User to Shop': 'Browse, discover and use AQARATI as a buyer.',
          'Real Estate Agent': 'Join AQARATI as a licensed real estate agent.',
          'Construction Company':
              'Register your construction business on AQARATI.',
          'Property Development Company':
              'Present your development company and projects.',
          'Building Architecture':
              'Register your architecture firm on AQARATI.',
          'Interior & Exterior Design': 'Register your design firm on AQARATI.',
        };
        for (final e in expected.entries) {
          expect(find.text(e.key), findsOneWidget);
          expect(find.text(e.value), findsOneWidget);
        }
        expect(
          signupPurposeOptions.map((o) => o.title(s)).toSet(),
          expected.keys.toSet(),
        );
        expect(find.text('Maintenance Provider'), findsNothing);
        expect(find.textContaining('Broker'), findsNothing);

        expect(
          t.widget<AQPrimaryButton>(find.byType(AQPrimaryButton)).onPressed,
          isNull,
        );
        for (final title in expected.keys) {
          await t.ensureVisible(find.text(title));
          await t.tap(find.text(title));
          await t.pump(const Duration(milliseconds: 600));
          final selected = t
              .widgetList<AQChoiceTile>(find.byType(AQChoiceTile))
              .where((w) => w.selected)
              .toList();
          expect(
            selected.length,
            1,
            reason: 'one active choice after tapping $title',
          );
          expect(selected.single.title, title);
        }
        expect(
          t.widget<AQPrimaryButton>(find.byType(AQPrimaryButton)).onPressed,
          isNotNull,
        );
      },
    );

    for (final w in [320.0, 360.0, 393.0, 412.0, 430.0]) {
      for (final b in Brightness.values) {
        testWidgets('renders without overflow at ${w.toInt()}px (${b.name})', (
          t,
        ) async {
          await pumpAt(
            t,
            const PurposeSelectionScreen(),
            width: w,
            height: 740,
            brightness: b,
          );
          expect(t.takeException(), isNull);
          // All six cards are reachable by scrolling.
          for (final o in signupPurposeOptions) {
            final s = EntryStrings.of(
              t.element(find.byType(PurposeSelectionScreen)),
            );
            await t.ensureVisible(find.text(o.title(s)));
            expect(find.text(o.title(s)), findsOneWidget);
          }
          expect(find.byType(AQPrimaryButton), findsOneWidget);
        });
      }
    }

    testWidgets('renders under RTL', (t) async {
      await pumpAt(t, const PurposeSelectionScreen(), dir: TextDirection.rtl);
      expect(t.takeException(), isNull);
    });
  });

  group('role configuration', () {
    test('every public path has a config and the documented documents', () {
      for (final p in SignupPurpose.values) {
        expect(roleConfigs[p], isNotNull, reason: p.name);
      }
      expect(roleConfigs[SignupPurpose.userToShop]!.documents, isEmpty);
      expect(roleConfigs[SignupPurpose.userToShop]!.hasBusinessStep, isFalse);
      expect(roleConfigs[SignupPurpose.realEstateAgent]!.documents, [
        DocumentKind.photoId,
        DocumentKind.agentLicence,
        DocumentKind.supportingDocument,
      ]);
      expect(roleConfigs[SignupPurpose.constructionCompany]!.documents, [
        DocumentKind.crCertificate,
        DocumentKind.municipalLicence,
      ]);
      expect(roleConfigs[SignupPurpose.buildingArchitecture]!.documents, [
        DocumentKind.crCertificate,
        DocumentKind.municipalLicence,
      ]);
      expect(roleConfigs[SignupPurpose.interiorExteriorDesign]!.documents, [
        DocumentKind.crCertificate,
        DocumentKind.municipalLicence,
      ]);
      expect(roleConfigs[SignupPurpose.propertyDevelopmentCompany]!.documents, [
        DocumentKind.officialCorporateRegistration,
        DocumentKind.crCertificate,
        DocumentKind.activityLicences,
        DocumentKind.developerLicence,
      ]);
      expect(
        roleConfigs[SignupPurpose.propertyDevelopmentCompany]!.fourEyes,
        isTrue,
      );
      for (final p in SignupPurpose.values.where(
        (p) => p != SignupPurpose.propertyDevelopmentCompany,
      )) {
        expect(roleConfigs[p]!.fourEyes, isFalse, reason: p.name);
      }
    });

    test(
      'company paths carry company email and address; people and agents do not',
      () {
        for (final p in _company) {
          expect(roleConfigs[p]!.hasCompanyContact, isTrue, reason: p.name);
        }
        expect(
          roleConfigs[SignupPurpose.userToShop]!.hasCompanyContact,
          isFalse,
        );
        expect(
          roleConfigs[SignupPurpose.realEstateAgent]!.hasCompanyContact,
          isFalse,
        );
      },
    );

    test(
      'address is required only where the architecture marks it required',
      () {
        expect(
          roleConfigs[SignupPurpose.buildingArchitecture]!
              .companyAddressRequired,
          isTrue,
        );
        expect(
          roleConfigs[SignupPurpose.interiorExteriorDesign]!
              .companyAddressRequired,
          isTrue,
        );
        expect(
          roleConfigs[SignupPurpose.constructionCompany]!
              .companyAddressRequired,
          isFalse,
        );
        expect(
          roleConfigs[SignupPurpose.propertyDevelopmentCompany]!
              .companyAddressRequired,
          isFalse,
        );
      },
    );

    test('only interior/exterior has a service type', () {
      for (final p in SignupPurpose.values) {
        expect(
          roleConfigs[p]!.hasServiceType,
          p == SignupPurpose.interiorExteriorDesign,
          reason: p.name,
        );
      }
    });

    test(
      'step list: people skip the business step, every other path has it',
      () {
        expect(stepsFor(roleConfigs[SignupPurpose.userToShop]!), [
          SignupStep.you,
          SignupStep.contact,
          SignupStep.account,
        ]);
        for (final p in SignupPurpose.values.where(
          (p) => p != SignupPurpose.userToShop,
        )) {
          expect(stepsFor(roleConfigs[p]!), [
            SignupStep.you,
            SignupStep.contact,
            SignupStep.business,
            SignupStep.account,
          ], reason: p.name);
        }
      },
    );
  });

  group('validation', () {
    test('phone is +968 and exactly eight digits, with no 7/9 restriction', () {
      for (final ok in [
        '91234567',
        '71234567',
        '21234567',
        '12345678',
        '9123 4567',
      ]) {
        expect(isValidOmanMobile(ok), isTrue, reason: ok);
      }
      for (final bad in [
        '9123456',
        '912345678',
        '9123456a',
        '',
        '+96891234567',
      ]) {
        expect(isValidOmanMobile(bad), isFalse, reason: bad);
      }
    });

    test('business step: address and company email rules per role', () {
      const base = SignupFormValues(
        businessName: 'Studio',
        serviceType: InteriorExteriorServiceType.both,
      );
      final arch = roleConfigs[SignupPurpose.buildingArchitecture]!;
      expect(
        validateStep(arch, SignupStep.business, base).keys,
        containsAll(['companyEmail', 'companyAddress']),
      );
      expect(
        validateStep(
          arch,
          SignupStep.business,
          base.copyWith(
            companyEmail: 'studio@example.com',
            companyAddress: 'Muscat',
          ),
        ),
        isEmpty,
      );
      expect(
        validateStep(
          arch,
          SignupStep.business,
          base.copyWith(companyEmail: 'not-an-email', companyAddress: 'Muscat'),
        ).keys,
        ['companyEmail'],
      );

      final construction = roleConfigs[SignupPurpose.constructionCompany]!;
      final errs = validateStep(construction, SignupStep.business, base);
      expect(errs.keys, [
        'companyEmail',
      ], reason: 'address is optional for construction');

      final dev = roleConfigs[SignupPurpose.propertyDevelopmentCompany]!;
      expect(
        validateStep(
          dev,
          SignupStep.business,
          base.copyWith(companyEmail: 'dev@example.com'),
        ),
        isEmpty,
      );

      final ie = roleConfigs[SignupPurpose.interiorExteriorDesign]!;
      expect(
        validateStep(
          ie,
          SignupStep.business,
          const SignupFormValues(
            businessName: 'D',
            companyEmail: 'd@example.com',
            companyAddress: 'Muscat',
          ),
        ).keys,
        ['serviceType'],
      );
      for (final t in InteriorExteriorServiceType.values) {
        expect(
          validateStep(
            ie,
            SignupStep.business,
            SignupFormValues(
              businessName: 'D',
              companyEmail: 'd@example.com',
              companyAddress: 'Muscat',
              serviceType: t,
            ),
          ),
          isEmpty,
          reason: t.name,
        );
      }
    });

    test('agents are not asked for company fields', () {
      final agent = roleConfigs[SignupPurpose.realEstateAgent]!;
      expect(
        validateStep(
          agent,
          SignupStep.business,
          const SignupFormValues(agencyName: 'Agency'),
        ),
        isEmpty,
      );
      expect(
        validateStep(agent, SignupStep.business, const SignupFormValues()).keys,
        ['agencyName'],
      );
    });

    test('password policy, mismatch and consent', () {
      final cfg = roleConfigs[SignupPurpose.userToShop]!;
      const v = SignupFormValues();
      expect(
        validateStep(
          cfg,
          SignupStep.account,
          v,
          password: 'weak',
          confirm: 'weak',
        ).keys,
        containsAll(['password', 'consent']),
      );
      expect(
        validateStep(
          cfg,
          SignupStep.account,
          v.copyWith(consent: true),
          password: 'Longenough1',
          confirm: 'Different1',
        ).keys,
        ['confirm'],
      );
      expect(
        validateStep(
          cfg,
          SignupStep.account,
          v.copyWith(consent: true),
          password: 'Longenough1',
          confirm: 'Longenough1',
        ),
        isEmpty,
      );
    });

    test(
      'values survive a JSON round trip (draft) and never carry a password',
      () {
        const v = SignupFormValues(
          firstName: 'A',
          lastName: 'B',
          phone: '91234567',
          email: 'a@b.co',
          businessName: 'Co',
          companyEmail: 'c@co.om',
          companyAddress: 'Muscat',
          serviceType: InteriorExteriorServiceType.exterior,
          consent: true,
        );
        final back = SignupFormValues.fromJson(v.toJson());
        expect(back.companyEmail, 'c@co.om');
        expect(back.companyAddress, 'Muscat');
        expect(back.serviceType, InteriorExteriorServiceType.exterior);
        expect(
          v.toJson().keys.any((k) => k.toLowerCase().contains('password')),
          isFalse,
        );
      },
    );
  });

  group('company business step (widget)', () {
    Future<void> toBusinessStep(WidgetTester t) async {
      Future<void> fill(List<String> values) async {
        final fields = find.byType(TextField);
        for (var i = 0; i < values.length; i++) {
          await t.enterText(fields.at(i), values[i]);
        }
        await t.pump();
      }

      Future<void> next() async {
        await t.tap(find.byType(AQPrimaryButton));
        await t.pump(const Duration(milliseconds: 600));
      }

      await fill(['Test', 'Person']);
      await next();
      await fill(['person@example.com', '91234567']);
      await next();
    }

    testWidgets(
      'architecture asks for company email and a required address, and validates before advancing',
      (t) async {
        SharedPreferences.setMockInitialValues({});
        await pumpAt(
          t,
          const SignupFormScreen(purpose: SignupPurpose.buildingArchitecture),
          demo: true,
        );
        await toBusinessStep(t);
        expect(find.text('Company email'), findsOneWidget);
        expect(find.text('Company address'), findsOneWidget);
        expect(
          find.text('This is the email you will sign in with.'),
          findsOneWidget,
        );

        // Required fields block Continue and show errors next to the field.
        await t.tap(find.byType(AQPrimaryButton));
        await t.pump(const Duration(milliseconds: 600));
        expect(find.text('This field is required.'), findsWidgets);

        final fields = find.byType(TextField);
        await t.enterText(fields.at(0), 'Vision Studio');
        await t.enterText(fields.at(1), 'studio@example.com');
        await t.enterText(fields.at(2), 'Muscat, Oman');
        await t.pump();
        expect(t.takeException(), isNull);
      },
    );

    testWidgets('construction labels the address optional', (t) async {
      SharedPreferences.setMockInitialValues({});
      await pumpAt(
        t,
        const SignupFormScreen(purpose: SignupPurpose.constructionCompany),
        demo: true,
      );
      await toBusinessStep(t);
      expect(find.text('Company address (optional)'), findsOneWidget);
    });

    for (final w in [320.0, 360.0, 430.0]) {
      testWidgets('interior/exterior business step fits at ${w.toInt()}px', (
        t,
      ) async {
        SharedPreferences.setMockInitialValues({});
        await pumpAt(
          t,
          const SignupFormScreen(purpose: SignupPurpose.interiorExteriorDesign),
          width: w,
          height: 700,
          demo: true,
        );
        await toBusinessStep(t);
        expect(t.takeException(), isNull);
        expect(find.text('Company email'), findsOneWidget);
      });
    }
  });

  group('documents to review hand-off', () {
    testWidgets('Review application shows the uploads just made and enables Submit', (t) async {
      SharedPreferences.setMockInitialValues({});
      t.view.physicalSize = const Size(393, 1100);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      final state = DemoBackendState()
        ..email = 'a@b.co'
        ..phone = '91234567'
        ..purpose = SignupPurpose.buildingArchitecture
        ..account = AccountState.active
        ..grant = GrantState.draft
        ..signedIn = true;
      final router = GoRouter(initialLocation: '/onboarding/documents', routes: [
        GoRoute(path: '/onboarding/documents', builder: (_, _) => const DocumentOnboardingScreen()),
        GoRoute(path: '/onboarding/review', builder: (_, _) => const ApplicationReviewScreen()),
      ]);
      await t.pumpWidget(ProviderScope(
        overrides: [accountApiProvider.overrideWithValue(DemoAccountApi(state)), documentPickerProvider.overrideWithValue(_PdfPicker())],
        child: MaterialApp.router(routerConfig: router),
      ));
      await t.pump(const Duration(milliseconds: 900));
      final container = ProviderScope.containerOf(t.element(find.byType(DocumentOnboardingScreen)));
      for (final k in roleConfigs[SignupPurpose.buildingArchitecture]!.documents) {
        await t.runAsync(() => container.read(documentControllerProvider(k).notifier).chooseAndUpload());
      }
      await t.pump(const Duration(milliseconds: 600));
      await t.tap(find.text('Review application'));
      await t.pump(const Duration(milliseconds: 900));
      await t.pump(const Duration(milliseconds: 900));
      expect(find.text('Upload required'), findsNothing, reason: 'review must not read a stale copy');
      expect(t.widget<AQPrimaryButton>(find.widgetWithText(AQPrimaryButton, 'Submit application')).onPressed, isNotNull);
    });
  });
}

class _PdfPicker implements DocumentPicker {
  @override
  Future<PickedDocument?> pick() async => PickedDocument(name: 'doc.pdf', sizeBytes: 5, bytes: Uint8List.fromList([0x25, 0x50, 0x44, 0x46, 0x2D]));
}
