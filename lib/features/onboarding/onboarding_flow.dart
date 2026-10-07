import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/aqarati_button.dart';
import '../../core/widgets/aqarati_startup_video.dart';
import '../../data/models/enums.dart';
import 'onboarding_background.dart';
import 'onboarding_preferences.dart';

/// One real photograph per onboarding concept (see AQARATI_ONBOARDING_ASSETS.md
/// for the full asset audit). `intro` and `language` share the same subtle
/// welcome image since both are generic pre-commitment screens; `transaction`
/// is the actual "What are you looking for?" (Buy/Rent/Lease) screen — it's a
/// single combined chooser in this implementation, not three separate
/// screens, so it gets one representative image rather than a Buy/Rent/Lease
/// split that doesn't exist in the current UI. `locationPermission` and
/// `location` share the location asset since they're the same concept.
const _stepBackgrounds = {
  _Step.language: 'assets/onboarding/onboarding_01_language.jpg',
  _Step.intro: 'assets/onboarding/onboarding_01_language.jpg',
  _Step.transaction: 'assets/onboarding/onboarding_02_intent.jpg',
  _Step.propertyType: 'assets/onboarding/onboarding_06_property_types.jpg',
  _Step.services: 'assets/onboarding/onboarding_07_services.jpg',
  _Step.locationPermission: 'assets/onboarding/onboarding_08_location.jpg',
  _Step.location: 'assets/onboarding/onboarding_08_location.jpg',
  _Step.budget: 'assets/onboarding/onboarding_09_preferences.jpg',
  _Step.summary: 'assets/onboarding/onboarding_10_summary.jpg',
  _Step.success: 'assets/onboarding/onboarding_11_complete.jpg',
};

enum _Step {
  splash,
  language,
  locationPermission,
  intro,
  transaction,
  propertyType,
  services,
  location,
  budget,
  summary,
  success,
}

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  final _prefs = OnboardingPreferences();
  _Step _step = _Step.splash;
  bool _skippedEarly = false;

  static const _order = [
    _Step.splash,
    _Step.language,
    _Step.locationPermission,
    _Step.intro,
    _Step.transaction,
    _Step.propertyType,
    _Step.services,
    _Step.location,
    _Step.budget,
    _Step.summary,
    _Step.success,
  ];

  void _goTo(_Step step) => setState(() => _step = step);

  void _next() {
    final i = _order.indexOf(_step);
    if (i < _order.length - 1) _goTo(_order[i + 1]);
  }

  void _back() {
    final i = _order.indexOf(_step);
    if (i > 0) _goTo(_order[i - 1]);
  }

  void _skipToHome() {
    if (_prefs.hasAnyAnswer) {
      setState(() => _skippedEarly = true);
      _goTo(_Step.success);
    } else {
      context.go('/home');
    }
  }

  void _finish() => context.go('/home');

  @override
  Widget build(BuildContext context) {
    // The startup video is a true full-bleed cinematic opening — no
    // SafeArea gaps around it. Every other onboarding step keeps SafeArea.
    if (_step == _Step.splash) {
      return Scaffold(
        backgroundColor: AppColors.background,
        extendBodyBehindAppBar: true,
        body: AqaratiStartupVideo(onFinished: () => _goTo(_Step.language)),
      );
    }
    final asset = _stepBackgrounds[_step];
    return Scaffold(
      backgroundColor: AppColors.background,
      body: asset == null
          ? SafeArea(child: _buildStep())
          : AqaratiOnboardingBackground(asset: asset, child: SafeArea(child: _buildStep())),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case _Step.splash:
        return const SizedBox.shrink();
      case _Step.language:
        return _LanguageStep(onContinue: _next);
      case _Step.locationPermission:
        return _LocationPermissionStep(onContinue: _next, onSkip: _skipToHome);
      case _Step.intro:
        return _IntroStep(onGetStarted: _next, onSkip: () => context.go('/home'));
      case _Step.transaction:
        return _TransactionStep(
          prefs: _prefs,
          onBack: _back,
          onContinue: _next,
          onSkip: _skipToHome,
          onChanged: () => setState(() {}),
        );
      case _Step.propertyType:
        return _PropertyTypeStep(
          prefs: _prefs,
          onBack: _back,
          onContinue: _next,
          onSkip: _skipToHome,
          onChanged: () => setState(() {}),
        );
      case _Step.services:
        return _ServicesStep(
          prefs: _prefs,
          onBack: _back,
          onContinue: _next,
          onSkip: _skipToHome,
          onChanged: () => setState(() {}),
        );
      case _Step.location:
        return _LocationStep(
          prefs: _prefs,
          onBack: _back,
          onContinue: _next,
          onSkip: _skipToHome,
          onChanged: () => setState(() {}),
        );
      case _Step.budget:
        return _BudgetStep(
          prefs: _prefs,
          onBack: _back,
          onContinue: _next,
          onSkip: _skipToHome,
          onChanged: () => setState(() {}),
        );
      case _Step.summary:
        return _SummaryStep(prefs: _prefs, onBack: _back, onConfirm: _next);
      case _Step.success:
        return _SuccessStep(skippedEarly: _skippedEarly, onDone: _finish);
    }
  }
}

/// Shared chrome for every intake step: back arrow, Skip link, title,
/// scrollable content, bottom Continue button.
class _OnboardingScaffold extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final VoidCallback? onBack;
  final VoidCallback onSkip;
  final VoidCallback onContinue;
  final bool continueEnabled;
  final String continueLabel;

  const _OnboardingScaffold({
    required this.title,
    this.subtitle,
    required this.child,
    this.onBack,
    required this.onSkip,
    required this.onContinue,
    this.continueEnabled = true,
    this.continueLabel = 'Continue',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              onBack != null
                  ? IconButton(onPressed: onBack, icon: const Icon(Icons.arrow_back_rounded))
                  : const SizedBox(width: 48),
              TextButton(onPressed: onSkip, child: const Text('Skip')),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.headlineMedium),
                if (subtitle != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(subtitle!, style: Theme.of(context).textTheme.bodyMedium),
                ],
                const SizedBox(height: AppSpacing.xl),
                child,
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: AqaratiButton(
            label: continueLabel,
            fullWidth: true,
            onPressed: continueEnabled ? onContinue : null,
          ),
        ),
      ],
    );
  }
}

class _LanguageStep extends StatefulWidget {
  final VoidCallback onContinue;

  const _LanguageStep({required this.onContinue});

  @override
  State<_LanguageStep> createState() => _LanguageStepState();
}

class _LanguageStepState extends State<_LanguageStep> {
  String _language = 'English';

  @override
  Widget build(BuildContext context) {
    return _OnboardingScaffold(
      title: 'Choose your language',
      subtitle: 'You can change this later in Profile settings.',
      onSkip: widget.onContinue,
      onContinue: widget.onContinue,
      child: Column(
        children: [
          _LanguageTile(
            label: 'English',
            selected: _language == 'English',
            onTap: () => setState(() => _language = 'English'),
          ),
          const SizedBox(height: AppSpacing.md),
          _LanguageTile(
            label: 'العربية (Arabic)',
            selected: _language == 'Arabic',
            onTap: () => setState(() => _language = 'Arabic'),
          ),
        ],
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageTile({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: selected ? AppColors.primary : AppColors.line, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: Theme.of(context).textTheme.titleMedium),
            if (selected) const Icon(Icons.check_circle_rounded, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}

class _LocationPermissionStep extends StatelessWidget {
  final VoidCallback onContinue;
  final VoidCallback onSkip;

  const _LocationPermissionStep({required this.onContinue, required this.onSkip});

  @override
  Widget build(BuildContext context) {
    return _OnboardingScaffold(
      title: 'Find properties near you',
      subtitle: 'Allow location access to see verified properties and services close to you.',
      onSkip: onSkip,
      onContinue: onContinue,
      continueLabel: 'Enable location',
      child: const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.xxxl),
          child: Icon(Icons.location_on_rounded, size: 72, color: AppColors.primary),
        ),
      ),
    );
  }
}

class _IntroStep extends StatelessWidget {
  final VoidCallback onGetStarted;
  final VoidCallback onSkip;

  const _IntroStep({required this.onGetStarted, required this.onSkip});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          const Spacer(),
          Text('Make Aqarati yours', style: Theme.of(context).textTheme.headlineLarge, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.sm),
          Text(
            "Tell us what you're interested in right now — we'll make your experience more relevant.",
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          AqaratiButton(label: 'Get started', fullWidth: true, onPressed: onGetStarted),
          const SizedBox(height: AppSpacing.md),
          TextButton(onPressed: onSkip, child: const Text('Skip for now')),
        ],
      ),
    );
  }
}

class _TransactionStep extends StatelessWidget {
  final OnboardingPreferences prefs;
  final VoidCallback onBack;
  final VoidCallback onContinue;
  final VoidCallback onSkip;
  final VoidCallback onChanged;

  const _TransactionStep({
    required this.prefs,
    required this.onBack,
    required this.onContinue,
    required this.onSkip,
    required this.onChanged,
  });

  static const _copy = {
    TransactionType.buy: 'Find a property to buy.',
    TransactionType.rent: 'Find a property to rent.',
    TransactionType.lease: 'Find a property to lease.',
  };

  @override
  Widget build(BuildContext context) {
    return _OnboardingScaffold(
      title: 'What are you looking for?',
      subtitle: "Choose what you're interested in right now.",
      onBack: onBack,
      onSkip: onSkip,
      onContinue: onContinue,
      continueEnabled: prefs.transactionType != null,
      child: Column(
        children: TransactionType.values.map((t) {
          final selected = prefs.transactionType == t;
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: _LanguageTile(
              label: '${t.label}\n${_copy[t]}',
              selected: selected,
              onTap: () {
                prefs.transactionType = t;
                onChanged();
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _PropertyTypeStep extends StatelessWidget {
  final OnboardingPreferences prefs;
  final VoidCallback onBack;
  final VoidCallback onContinue;
  final VoidCallback onSkip;
  final VoidCallback onChanged;

  const _PropertyTypeStep({
    required this.prefs,
    required this.onBack,
    required this.onContinue,
    required this.onSkip,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _OnboardingScaffold(
      title: 'What kind of property?',
      subtitle: 'You can select more than one.',
      onBack: onBack,
      onSkip: onSkip,
      onContinue: onContinue,
      continueEnabled: prefs.propertyTypes.isNotEmpty,
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: onboardingPropertyTypes.map((type) {
          final selected = prefs.propertyTypes.contains(type);
          return FilterChip(
            label: Text(type.label),
            selected: selected,
            onSelected: (_) {
              selected ? prefs.propertyTypes.remove(type) : prefs.propertyTypes.add(type);
              onChanged();
            },
          );
        }).toList(),
      ),
    );
  }
}

class _ServicesStep extends StatelessWidget {
  final OnboardingPreferences prefs;
  final VoidCallback onBack;
  final VoidCallback onContinue;
  final VoidCallback onSkip;
  final VoidCallback onChanged;

  const _ServicesStep({
    required this.prefs,
    required this.onBack,
    required this.onContinue,
    required this.onSkip,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _OnboardingScaffold(
      title: 'Any services you need?',
      subtitle: "We'll show relevant professionals near you.",
      onBack: onBack,
      onSkip: onSkip,
      onContinue: onContinue,
      continueEnabled: prefs.services.isNotEmpty,
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: BusinessCategory.values.map((category) {
          final selected = prefs.services.contains(category);
          return FilterChip(
            label: Text(category.label),
            selected: selected,
            onSelected: (_) {
              selected ? prefs.services.remove(category) : prefs.services.add(category);
              onChanged();
            },
          );
        }).toList(),
      ),
    );
  }
}

class _LocationStep extends StatelessWidget {
  final OnboardingPreferences prefs;
  final VoidCallback onBack;
  final VoidCallback onContinue;
  final VoidCallback onSkip;
  final VoidCallback onChanged;

  const _LocationStep({
    required this.prefs,
    required this.onBack,
    required this.onContinue,
    required this.onSkip,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _OnboardingScaffold(
      title: 'Where are you looking?',
      subtitle: 'Choose one or more places in Oman.',
      onBack: onBack,
      onSkip: onSkip,
      onContinue: onContinue,
      continueEnabled: prefs.locations.isNotEmpty,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TextField(
            decoration: InputDecoration(
              hintText: 'Search a city, area or neighbourhood',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('POPULAR LOCATIONS', style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: omanPopularLocations.map((loc) {
              final selected = prefs.locations.contains(loc);
              return FilterChip(
                label: Text(loc),
                selected: selected,
                onSelected: (_) {
                  selected ? prefs.locations.remove(loc) : prefs.locations.add(loc);
                  onChanged();
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _BudgetStep extends StatelessWidget {
  final OnboardingPreferences prefs;
  final VoidCallback onBack;
  final VoidCallback onContinue;
  final VoidCallback onSkip;
  final VoidCallback onChanged;

  const _BudgetStep({
    required this.prefs,
    required this.onBack,
    required this.onContinue,
    required this.onSkip,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _OnboardingScaffold(
      title: 'Anything else?',
      subtitle: 'These help us show the most relevant results.',
      onBack: onBack,
      onSkip: onSkip,
      onContinue: onContinue,
      continueEnabled: prefs.budget != null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('BUDGET', style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: BudgetBucket.values.map((bucket) {
              final selected = prefs.budget == bucket;
              return ChoiceChip(
                label: Text(bucket.label),
                selected: selected,
                onSelected: (_) {
                  prefs.budget = bucket;
                  onChanged();
                },
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('BEDROOMS', style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            children: [null, 1, 2, 3, 4].map((n) {
              final selected = prefs.bedrooms == n;
              return ChoiceChip(
                label: Text(n == null ? 'Any' : n == 4 ? '4+' : '$n'),
                selected: selected,
                onSelected: (_) {
                  prefs.bedrooms = n;
                  onChanged();
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _SummaryStep extends StatelessWidget {
  final OnboardingPreferences prefs;
  final VoidCallback onBack;
  final VoidCallback onConfirm;

  const _SummaryStep({required this.prefs, required this.onBack, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
          child: Row(
            children: [IconButton(onPressed: onBack, icon: const Icon(Icons.arrow_back_rounded))],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your Aqarati', style: Theme.of(context).textTheme.headlineMedium),
                Text(
                  "Here's a summary of what you're looking for.",
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.xl),
                if (prefs.transactionType != null)
                  _SummaryRow(label: 'LOOKING TO', value: prefs.transactionType!.label),
                if (prefs.propertyTypes.isNotEmpty)
                  _SummaryRow(
                    label: 'PROPERTY TYPES',
                    value: prefs.propertyTypes.map((t) => t.label).join(', '),
                  ),
                if (prefs.services.isNotEmpty)
                  _SummaryRow(
                    label: 'SERVICES',
                    value: prefs.services.map((s) => s.label).join(', '),
                  ),
                if (prefs.locations.isNotEmpty)
                  _SummaryRow(label: 'LOCATIONS', value: prefs.locations.join(', ')),
                if (prefs.budget != null) _SummaryRow(label: 'BUDGET', value: prefs.budget!.label),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: AqaratiButton(label: "Explore Aqarati", fullWidth: true, onPressed: onConfirm),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: Theme.of(context).textTheme.labelMedium),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.titleSmall, textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }
}

class _SuccessStep extends StatelessWidget {
  final bool skippedEarly;
  final VoidCallback onDone;

  const _SuccessStep({required this.skippedEarly, required this.onDone});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            skippedEarly ? Icons.info_outline_rounded : Icons.check_circle_rounded,
            size: 72,
            color: AppColors.primary,
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            skippedEarly ? 'No problem.' : "You're all set.",
            style: Theme.of(context).textTheme.headlineLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            skippedEarly
                ? 'You can personalize Aqarati anytime from your profile.'
                : "We'll use your preferences to make Aqarati more relevant.",
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xxxl),
          AqaratiButton(label: 'Explore Aqarati', fullWidth: true, onPressed: onDone),
        ],
      ),
    );
  }
}
