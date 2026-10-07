import 'package:flutter/widgets.dart' show ValueKey;
import 'package:go_router/go_router.dart';
import '../../features/business/business_profile_screen.dart';
import '../../features/business/professional_discovery_screen.dart';
import '../../features/explore/explore_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/messages/messages_screen.dart';
import '../../features/onboarding/onboarding_flow.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/property/property_detail_screen.dart';
import '../../features/saved/saved_screen.dart';
import '../../features/search/search_results_screen.dart';
import '../../features/search/search_screen.dart';
import '../../features/entry/screens/onboarding_entry_screen.dart';
import '../../features/entry/models/signup_purpose.dart';
import '../../features/flow/screens/auth_screens.dart';
import '../../features/flow/screens/otp_screens.dart';
import '../../features/flow/screens/signup_form_screen.dart';
import '../../features/flow/screens/approval_screens.dart';
import '../../features/flow/screens/verification_onboarding_screens.dart';
import '../../features/flow/screens/verification_status_screens.dart';
import '../../features/entry/screens/purpose_selection_screen.dart';
import '../../features/entry/widgets/entry_common.dart';
import '../../features/workspace/aq_app_shell.dart';
import 'app_shell.dart';

final appRouter = GoRouter(
  initialLocation: '/entry',
  routes: [
    GoRoute(path: '/entry', pageBuilder: (context, state) => brandPage(key: state.pageKey, child: const OnboardingEntryScreen())),
    GoRoute(path: '/onboarding/purpose', pageBuilder: (context, state) => brandPage(key: state.pageKey, child: const PurposeSelectionScreen())),
    GoRoute(path: '/login', pageBuilder: (context, state) => brandPage(key: state.pageKey, child: const LoginScreen())),
    GoRoute(path: '/forgot-password', pageBuilder: (context, state) => brandPage(key: state.pageKey, child: const ForgotPasswordScreen())),
    GoRoute(path: '/reset-password', pageBuilder: (context, state) => brandPage(key: state.pageKey, child: ResetPasswordScreen(key: ValueKey(state.uri.queryParameters['oobCode']), oobCode: state.uri.queryParameters['oobCode']))),
    for (final o in signupPurposeOptions)
      GoRoute(path: o.route, pageBuilder: (context, state) => brandPage(key: state.pageKey, child: SignupFormScreen(purpose: o.id))),
    GoRoute(path: '/otp', pageBuilder: (context, state) => brandPage(key: state.pageKey, child: const OtpScreen())),
    GoRoute(path: '/account/active', pageBuilder: (context, state) => brandPage(key: state.pageKey, child: const AccountActiveScreen())),
    GoRoute(path: '/onboarding/documents', pageBuilder: (context, state) => brandPage(key: state.pageKey, child: const DocumentOnboardingScreen())),
    GoRoute(path: '/onboarding/verification-intro', pageBuilder: (context, state) => brandPage(key: state.pageKey, child: const VerificationIntroScreen())),
    GoRoute(path: '/onboarding/review', pageBuilder: (context, state) => brandPage(key: state.pageKey, child: const ApplicationReviewScreen())),
    GoRoute(path: '/onboarding/submitted', pageBuilder: (context, state) => brandPage(key: state.pageKey, child: const ApplicationSubmittedScreen())),
    GoRoute(path: '/verification', pageBuilder: (context, state) => brandPage(key: state.pageKey, child: const VerificationStatusScreen())),
    GoRoute(path: '/verification/details', pageBuilder: (context, state) => brandPage(key: state.pageKey, child: const ApplicationDetailsScreen())),
    GoRoute(path: '/verification/resubmit', pageBuilder: (context, state) => brandPage(key: state.pageKey, child: const ResubmissionScreen())),
    GoRoute(path: '/verification/resubmit/review', pageBuilder: (context, state) => brandPage(key: state.pageKey, child: const ResubmitReviewScreen())),
    GoRoute(path: '/verification/resubmitted', pageBuilder: (context, state) => brandPage(key: state.pageKey, child: const ResubmittedScreen())),
    GoRoute(path: '/verification/approved', pageBuilder: (context, state) => brandPage(key: state.pageKey, child: const ApprovedScreen())),
    GoRoute(path: '/verification/summary', pageBuilder: (context, state) => brandPage(key: state.pageKey, child: const VerifiedSummaryScreen())),
    GoRoute(path: '/workspace/activation', pageBuilder: (context, state) => brandPage(key: state.pageKey, child: const WorkspaceActivationScreen())),
    ShellRoute(
      builder: (context, state, child) => AQAppShell(child: child),
      routes: [
        GoRoute(path: '/app/home', pageBuilder: (context, state) => NoTransitionPage(key: state.pageKey, child: const HomeTab())),
        GoRoute(path: '/app/explore', pageBuilder: (context, state) => NoTransitionPage(key: state.pageKey, child: const ExploreTab())),
        GoRoute(path: '/app/activity', pageBuilder: (context, state) => NoTransitionPage(key: state.pageKey, child: const ActivityTab())),
        GoRoute(path: '/app/account', pageBuilder: (context, state) => NoTransitionPage(key: state.pageKey, child: const AccountTab())),
      ],
    ),
    GoRoute(path: '/onboarding', builder: (context, state) => const OnboardingFlow()),
    GoRoute(path: '/saved', builder: (context, state) => const SavedScreen()),
    GoRoute(
      path: '/search',
      builder: (context, state) => SearchResultsScreen(initialQuery: state.uri.queryParameters['q']),
    ),
    GoRoute(path: '/search/start', builder: (context, state) => const SearchScreen()),
    GoRoute(
      path: '/property/:id',
      builder: (context, state) => PropertyDetailScreen(propertyId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/professionals',
      builder: (context, state) => const ProfessionalDiscoveryScreen(),
    ),
    GoRoute(
      path: '/business/:id',
      builder: (context, state) => BusinessProfileScreen(businessId: state.pathParameters['id']!),
    ),
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
        GoRoute(path: '/explore', builder: (context, state) => const ExploreScreen()),
        GoRoute(path: '/messages', builder: (context, state) => const MessagesScreen()),
        GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),
      ],
    ),
  ],
);
