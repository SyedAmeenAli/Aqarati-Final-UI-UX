import 'package:aqarati_app/core/config/demo_mode.dart';
import 'package:aqarati_app/core/domain/account_models.dart';
import 'package:aqarati_app/data/demo/demo_backend.dart';
import 'package:aqarati_app/features/devbuild/db_models.dart';
import 'package:aqarati_app/features/devbuild/db_repository.dart';
import 'package:aqarati_app/features/entry/models/signup_purpose.dart';
import 'package:flutter_test/flutter_test.dart';

DemoBackendState approved(SignupPurpose p) => DemoBackendState()
  ..purpose = p
  ..grant = GrantState.approved
  ..businessName = 'Demo business'
  ..signedIn = true
  ..emailVerified = true;

void main() {
  group('sample workspace data follows the demo switch', () {
    test('without demo mode nothing is invented: capabilities off, lists empty', () async {
      if (kDemoMode) return;
      final repo = DemoDevBuildRepository(() => approved(SignupPurpose.buildingArchitecture), lag: Duration.zero);
      expect(repo.caps.leadEvents, isFalse);
      expect(repo.caps.engagements, isFalse);
      expect(await repo.myContactEvents(), isEmpty);
      expect(await repo.myEngagements(), isEmpty);
      expect((await repo.myOrganisation())!.mediaUrls, isEmpty);
      await expectLater(repo.confirmEngagement('en1'), throwsA(anything));
    });

    test('with demo mode on: sample contact activity, engagements and portfolio, confirmed locally', () async {
      if (!kDemoMode) return;
      for (final p in [
        SignupPurpose.propertyDevelopmentCompany,
        SignupPurpose.constructionCompany,
        SignupPurpose.buildingArchitecture,
        SignupPurpose.interiorExteriorDesign,
      ]) {
        final repo = DemoDevBuildRepository(() => approved(p), lag: Duration.zero);
        expect(repo.caps.leadEvents && repo.caps.engagements, isTrue);
        expect(await repo.myContactEvents(), isNotEmpty);
        final before = await repo.myEngagements();
        expect(before.map((e) => e.state), containsAll([EngagementState.awaitingMyConfirmation, EngagementState.awaitingClient, EngagementState.confirmedByBoth]));
        await repo.confirmEngagement('en1');
        final after = await repo.myEngagements();
        expect(after.firstWhere((e) => e.id == 'en1').state, EngagementState.confirmedByBoth);
        await expectLater(repo.confirmEngagement('en2'), throwsA(anything), reason: 'only an engagement waiting for you can be confirmed');
        if (p != SignupPurpose.propertyDevelopmentCompany) {
          expect((await repo.myOrganisation())!.mediaUrls, isNotEmpty);
        }
      }
    });
  });
}
