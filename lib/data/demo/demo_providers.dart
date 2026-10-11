import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/backend_mode.dart';
import '../../core/domain/account_models.dart';
import '../../features/entry/models/signup_purpose.dart';

import '../../core/auth/auth_repository.dart';
import '../api/account_api.dart';
import 'demo_backend.dart';

/// The simulated backend state, shared with other demo-only repositories. Null outside demo mode.
final demoBackendStateProvider = Provider<DemoBackendState?>((ref) => null);

/// DEMO ONLY wiring (see lib/core/config/backend_mode.dart).
List<Override> demoOverrides() {
  final state = DemoBackendState();
  _seedReviewSession(state);
  return [
    demoBackendStateProvider.overrideWithValue(state),
    authRepositoryProvider.overrideWithValue(DemoAuthRepository(state)),
    accountApiProvider.overrideWithValue(DemoAccountApi(state)),
  ];
}

/// REVIEW TOOLS ONLY (`--dart-define=REVIEW_TOOLS=true --dart-define=REVIEW_SESSION=<name>`): starts the
/// demo already signed in as an approved business, so reviewers can open the workspace without
/// clicking through sign-up and verification. Does nothing in a normal build.
const _reviewSession = String.fromEnvironment('REVIEW_SESSION');

void _seedReviewSession(DemoBackendState s) {
  if (!kShowReviewTools || _reviewSession.isEmpty) return;
  final (purpose, grant, stage) = switch (_reviewSession) {
    'developer' => (
      SignupPurpose.propertyDevelopmentCompany,
      GrantState.approved,
      null,
    ),
    'construction' => (
      SignupPurpose.constructionCompany,
      GrantState.approved,
      null,
    ),
    'architecture' => (
      SignupPurpose.buildingArchitecture,
      GrantState.approved,
      null,
    ),
    'interior' => (
      SignupPurpose.interiorExteriorDesign,
      GrantState.approved,
      null,
    ),
    'pending' => (
      SignupPurpose.propertyDevelopmentCompany,
      GrantState.pendingVerification,
      ReviewStage.underReview,
    ),
    'second' => (
      SignupPurpose.propertyDevelopmentCompany,
      GrantState.pendingVerification,
      ReviewStage.awaitingSecondApproval,
    ),
    'rejected' => (
      SignupPurpose.constructionCompany,
      GrantState.rejected,
      null,
    ),
    _ => (null, null, null),
  };
  if (purpose == null) return;
  s
    ..email = 'review@example.test'
    ..phone = '90000000'
    ..purpose = purpose
    ..account = AccountState.active
    ..grant = grant
    ..stage = stage
    ..businessName = 'Review Business'
    ..signedIn = true
    ..emailVerified = true;
}
