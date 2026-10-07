/// One public onboarding page. Page 1 is the only approved page today; the
/// model lets further pages be added without touching the screen widget.
class OnboardingPage {
  final String backgroundAsset;
  final String primaryRoute;
  final String loginRoute;
  const OnboardingPage({required this.backgroundAsset, required this.primaryRoute, required this.loginRoute});
}

const onboardingPages = <OnboardingPage>[
  OnboardingPage(
    backgroundAsset: 'assets/entry/entry_bg_01.jpg',
    primaryRoute: '/onboarding/purpose',
    loginRoute: '/login',
  ),
];
