import 'package:flutter/material.dart';
import '../../../core/aq/aq_forms.dart';
import '../../../core/domain/account_models.dart';
import '../../../core/localization/flow_strings.dart';
import '../../entry/models/signup_purpose.dart';
import '../state/signup_state.dart';
import 'flow_common.dart';

/// Where the person is in the real journey for their role.
enum JourneyAt { signup, business, phone, ready, documents, review, status }

/// Stage label keys for a role. The length is the real length of that journey.
List<String> journeyStages(SignupPurpose p) {
  if (p == SignupPurpose.userToShop) return const ['jr.account', 'jr.phone', 'jr.ready'];
  final business = switch (p) {
    SignupPurpose.realEstateAgent => 'jr.agency',
    SignupPurpose.constructionCompany || SignupPurpose.propertyDevelopmentCompany => 'jr.company',
    _ => 'jr.practice',
  };
  return ['jr.details', business, 'jr.documents', 'jr.review', if (roleConfigs[p]?.fourEyes ?? false) 'jr.verification'];
}

/// Stage index for a screen. Pure, so it can be tested.
int journeyIndex(SignupPurpose p, JourneyAt at, {SignupStep? step}) {
  final last = journeyStages(p).length - 1;
  if (p == SignupPurpose.userToShop) {
    return switch (at) { JourneyAt.signup || JourneyAt.business => 0, JourneyAt.phone => 1, _ => 2 };
  }
  return switch (at) {
    JourneyAt.signup => (step == SignupStep.you || step == SignupStep.contact) ? 0 : 1,
    JourneyAt.business || JourneyAt.phone || JourneyAt.ready => 1,
    JourneyAt.documents => 2,
    JourneyAt.review => 3,
    JourneyAt.status => last,
  };
}

/// Slim contextual progress rail with the current stage named. No fixed "x of 3".
Widget journeyProgress(BuildContext context, SignupPurpose p, JourneyAt at, {SignupStep? step}) {
  final f = FlowStrings.of(context);
  final stages = journeyStages(p);
  final i = journeyIndex(p, at, step: step);
  return AQProgressStepper(step: i + 1, total: stages.length, label: '${roleTitle(context, p)} · ${f.t(stages[i])}');
}
