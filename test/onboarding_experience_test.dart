import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aqarati_app/core/aq/aq_primitives.dart';
import 'package:aqarati_app/core/aq/aq_tokens.dart';
import 'package:aqarati_app/core/domain/account_models.dart';
import 'package:aqarati_app/core/localization/entry_strings.dart';
import 'package:aqarati_app/core/localization/flow_strings.dart';
import 'package:aqarati_app/core/router/app_router.dart';
import 'package:go_router/go_router.dart';
import 'package:aqarati_app/data/demo/demo_backend.dart';
import 'package:aqarati_app/features/entry/models/signup_purpose.dart';
import 'package:aqarati_app/features/entry/screens/purpose_selection_screen.dart';
import 'package:aqarati_app/features/flow/screens/approval_screens.dart' show workspaceCaps;
import 'package:aqarati_app/features/flow/screens/email_verification_screen.dart' show maskEmail;
import 'package:aqarati_app/data/demo/demo_providers.dart';
import 'package:aqarati_app/features/flow/screens/otp_screens.dart';
import 'package:aqarati_app/features/flow/screens/signup_form_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aqarati_app/features/flow/state/document_state.dart';
import 'package:aqarati_app/features/flow/state/otp_state.dart';
import 'package:aqarati_app/features/flow/state/signup_state.dart';
import 'package:aqarati_app/features/flow/widgets/document_upload_tile.dart';
import 'package:aqarati_app/features/flow/widgets/journey.dart';

DocumentStatus doc(DocumentKind k, DocumentOutcome o, {DateTime? expiry}) => DocumentStatus(kind: k, outcome: o, expiry: expiry, fileName: 'f.pdf', sizeBytes: 1024);

Future<void> pumpAt(WidgetTester t, Widget w, {double width = 375, double height = 812, double textScale = 1, bool reduceMotion = false, bool demo = false}) async {
  t.view.physicalSize = Size(width, height);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(ProviderScope(
    overrides: demo ? demoOverrides() : const [],
    child: MaterialApp(
      builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale), disableAnimations: reduceMotion), child: child!),
      home: w,
    ),
  ));
  await t.pump(const Duration(milliseconds: 900));
}

void main() {
  group('journey (contextual progress)', () {
    test('stage count is the real length of each role journey', () {
      expect(journeyStages(SignupPurpose.userToShop), ['jr.account', 'jr.phone', 'jr.ready']);
      expect(journeyStages(SignupPurpose.realEstateAgent).length, 4);
      expect(journeyStages(SignupPurpose.constructionCompany).length, 4);
      expect(journeyStages(SignupPurpose.propertyDevelopmentCompany).length, 5, reason: 'developer adds a Verification stage');
    });

    test('screens map to stages', () {
      const p = SignupPurpose.propertyDevelopmentCompany;
      expect(journeyIndex(p, JourneyAt.signup, step: SignupStep.you), 0);
      expect(journeyIndex(p, JourneyAt.signup, step: SignupStep.business), 1);
      expect(journeyIndex(p, JourneyAt.documents), 2);
      expect(journeyIndex(p, JourneyAt.review), 3);
      expect(journeyIndex(p, JourneyAt.status), 4);
      expect(journeyIndex(SignupPurpose.userToShop, JourneyAt.phone), 1);
      expect(journeyIndex(SignupPurpose.userToShop, JourneyAt.ready), 2);
    });

    test('every stage label has English and Arabic copy', () {
      for (final p in SignupPurpose.values) {
        for (final k in journeyStages(p)) {
          expect(FlowStrings.keys, contains(k));
        }
      }
    });
  });

  group('document status mapping', () {
    final now = DateTime(2026, 10, 7);
    test('action comes from the model only', () {
      expect(docActionOf(doc(DocumentKind.crCertificate, DocumentOutcome.rejected), now: now), DocAction.fix);
      expect(docActionOf(doc(DocumentKind.crCertificate, DocumentOutcome.notSubmitted), now: now), DocAction.uploadMissing);
      expect(docActionOf(doc(DocumentKind.crCertificate, DocumentOutcome.accepted, expiry: DateTime(2026, 1, 1)), now: now), DocAction.replaceExpired);
      expect(docActionOf(doc(DocumentKind.crCertificate, DocumentOutcome.pendingReview, expiry: DateTime(2027, 1, 1)), now: now), DocAction.none);
    });

    test('display vocabulary', () {
      expect(docDisplayOfStatus(doc(DocumentKind.crCertificate, DocumentOutcome.accepted), now: now), DocDisplay.verified);
      expect(docDisplayOfStatus(doc(DocumentKind.crCertificate, DocumentOutcome.pendingReview), now: now), DocDisplay.underReview);
      expect(docDisplayOfStatus(doc(DocumentKind.crCertificate, DocumentOutcome.rejected), now: now), DocDisplay.needsUpdate);
    });

    test('tile display: verified, under review, expired, missing, failed', () {
      expect(const DocumentState(phase: DocPhase.success, outcome: DocumentOutcome.accepted).display, DocDisplay.verified);
      expect(const DocumentState(phase: DocPhase.success, outcome: DocumentOutcome.pendingReview).display, DocDisplay.underReview);
      expect(DocumentState(phase: DocPhase.success, outcome: DocumentOutcome.accepted, expiry: DateTime(2020)).display, DocDisplay.expired);
      expect(const DocumentState(action: DocAction.uploadMissing).display, DocDisplay.missing);
      expect(const DocumentState().display, DocDisplay.empty);
      expect(const DocumentState(phase: DocPhase.failed).display, DocDisplay.failed);
      expect(const DocumentState(phase: DocPhase.rejected).display, DocDisplay.needsUpdate);
    });
  });

  group('resubmission', () {
    final now = DateTime(2026, 10, 7);
    final docs = [
      doc(DocumentKind.officialCorporateRegistration, DocumentOutcome.rejected),
      doc(DocumentKind.crCertificate, DocumentOutcome.accepted, expiry: DateTime(2020, 1, 1)), // expired
      doc(DocumentKind.activityLicences, DocumentOutcome.notSubmitted),
      doc(DocumentKind.developerLicence, DocumentOutcome.pendingReview, expiry: DateTime(2027, 6, 1)),
      doc(DocumentKind.photoId, DocumentOutcome.accepted),
    ];

    test('targets are rejected, expired and missing documents', () {
      expect(resubmissionTargetsOf(docs, now: now), {DocumentKind.officialCorporateRegistration, DocumentKind.crCertificate, DocumentKind.activityLicences});
    });

    test('only truly approved documents are "already approved"; pending stays pending', () {
      final g = groupForReview(docs, {DocumentKind.officialCorporateRegistration}, now: now);
      expect(g.updated.map((d) => d.kind), [DocumentKind.officialCorporateRegistration]);
      expect(g.approved.map((d) => d.kind), [DocumentKind.photoId]);
      expect(g.pending.map((d) => d.kind), [DocumentKind.developerLicence]);
      expect(g.stillNeeds.map((d) => d.kind), [DocumentKind.crCertificate, DocumentKind.activityLicences]);
    });
  });

  group('workspace handoff', () {
    test('role-aware capabilities and titles', () {
      expect(workspaceCaps(SignupPurpose.realEstateAgent), contains('ws.cap.agent.1'));
      expect(workspaceCaps(SignupPurpose.propertyDevelopmentCompany), ['ws.cap.dev.1', 'ws.cap.dev.2']);
      expect(workspaceCaps(SignupPurpose.userToShop), isEmpty);
      for (final p in SignupPurpose.values) {
        expect(FlowStrings.keys, contains('ws.t.${p.name}'));
      }
    });
  });

  group('OTP change number', () {
    test('changing the number resets the code state and requests a fresh code', () async {
      final s = DemoBackendState()
        ..purpose = SignupPurpose.userToShop
        ..phone = '91234567';
      final api = DemoAccountApi(s);
      final c = OtpController(api);
      await c.send();
      await c.verify('000000');
      expect(c.state.phase, OtpPhase.invalid);
      await api.changePhone('92345678');
      await c.restartForNewNumber();
      expect(s.phone, '92345678');
      expect(c.state.phase, OtpPhase.sent);
      expect(c.state.cooldown, greaterThan(0));
      c.dispose();
    });
  });

  group('email verification helpers', () {
    test('masking keeps the domain and one character', () {
      expect(maskEmail('sara@example.com'), 's••••@example.com');
    });
  });

  group('routes', () {
    List<String> flatten(List<RouteBase> rs) => [for (final r in rs) ...[if (r is GoRoute) r.path, ...flatten(r.routes)]];

    test('legacy onboarding route is gone; legal and email routes exist', () {
      final paths = flatten(appRouter.configuration.routes);
      expect(paths, isNot(contains('/onboarding')));
      expect(paths, containsAll(['/legal/terms', '/legal/privacy', '/verify-email', '/onboarding/purpose', '/verification']));
    });
  });

  group('motion', () {
    testWidgets('reduced motion is detected and animation durations collapse', (t) async {
      late BuildContext ctx;
      await pumpAt(t, Builder(builder: (c) {
        ctx = c;
        return const SizedBox();
      }), reduceMotion: true);
      expect(AQMotion.reduced(ctx), isTrue);
      expect(AQMotion.scaled(ctx, AQMotion.slow), Duration.zero);
    });
  });

  group('purpose screen', () {
    testWidgets('no immediate navigation: Continue stays disabled until a role is chosen', (t) async {
      await pumpAt(t, const PurposeSelectionScreen());
      expect(t.widget<AQPrimaryButton>(find.byType(AQPrimaryButton)).onPressed, isNull);
      await t.tap(find.text('Real Estate Agent'));
      await t.pump(const Duration(milliseconds: 700));
      expect(t.widget<AQPrimaryButton>(find.byType(AQPrimaryButton)).onPressed, isNotNull);
      expect(find.text('Build trust around every property you represent.'), findsOneWidget);
    });

    for (final w in [375.0, 430.0]) {
      testWidgets('descriptions are never clipped at ${w.toInt()} wide (large text 2.0 too)', (t) async {
        await pumpAt(t, const PurposeSelectionScreen(), width: w, height: w == 375 ? 812 : 932, textScale: 2.0);
        expect(t.takeException(), isNull, reason: 'no overflow at 200% text');
        final s = EntryStrings.of(t.element(find.byType(PurposeSelectionScreen)));
        for (final o in signupPurposeOptions) {
          final text = t.widget<Text>(find.text(o.description(s)));
          expect(text.maxLines, isNull, reason: o.id.name);
          expect(text.overflow, isNull, reason: o.id.name);
        }
      });
    }
  });

  group('document tile', () {
    testWidgets('shows icon + text status and stays within bounds at 200% text', (t) async {
      await pumpAt(
        t,
        Scaffold(body: SingleChildScrollView(child: Column(children: [DocumentUploadTile(kind: DocumentKind.crCertificate, seed: initialFromStatus(doc(DocumentKind.crCertificate, DocumentOutcome.rejected)), rejectionReason: 'Unreadable')]))),
        textScale: 2.0,
      );
      expect(t.takeException(), isNull);
      expect(find.text('Needs replacing'), findsOneWidget);
      expect(find.text('Replace file'), findsOneWidget);
    });
  });

  group('large text and small screens', () {
    for (final scale in [1.5, 2.0]) {
      for (final purpose in [SignupPurpose.realEstateAgent, SignupPurpose.userToShop]) {
        testWidgets('signup (${purpose.name}) steps fit at ${scale}x text on 360x640', (t) async {
          SharedPreferences.setMockInitialValues({});
          await pumpAt(t, SignupFormScreen(purpose: purpose), width: 360, height: 640, textScale: scale, demo: true);
          expect(t.takeException(), isNull);
          expect(find.text("Let's start with you."), findsOneWidget);
        });
      }
    }

    testWidgets('OTP screen fits at 2.0x text and offers "Wrong number?"', (t) async {
      await pumpAt(t, const OtpScreen(), width: 360, height: 640, textScale: 2.0, demo: true);
      expect(t.takeException(), isNull);
      expect(find.text('Wrong number?'), findsOneWidget);
    });

    testWidgets('account active fits at 2.0x text', (t) async {
      await pumpAt(t, const AccountActiveScreen(), width: 360, height: 640, textScale: 2.0, demo: true);
      expect(t.takeException(), isNull);
    });
  });
}
