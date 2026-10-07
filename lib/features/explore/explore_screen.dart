import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/aqarati_search_field.dart';
import '../../core/widgets/section_header.dart';
import '../../data/models/enums.dart';
import '../calculators/calculator_models.dart';
import '../calculators/calculator_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(length: 3, vsync: this);

  static const _propertyTypes = [
    (PropertyType.villa, Icons.villa_rounded),
    (PropertyType.apartment, Icons.apartment_rounded),
    (PropertyType.residentialLand, Icons.terrain_rounded),
    (PropertyType.office, Icons.business_rounded),
    (PropertyType.shop, Icons.storefront_rounded),
    (PropertyType.warehouse, Icons.warehouse_rounded),
  ];

  static const _professionalCategories = [
    (BusinessCategory.realEstateAgent, Icons.badge_outlined),
    (BusinessCategory.propertyDevelopment, Icons.apartment_outlined),
    (BusinessCategory.construction, Icons.construction_outlined),
    (BusinessCategory.architecture, Icons.architecture_outlined),
    (BusinessCategory.interiorDesign, Icons.chair_outlined),
    (BusinessCategory.exteriorDesign, Icons.deck_outlined),
    (BusinessCategory.maintenance, Icons.build_outlined),
  ];

  static const _serviceCategories = [
    (ServiceCategory.architecture, Icons.architecture_outlined),
    (ServiceCategory.construction, Icons.construction_outlined),
    (ServiceCategory.interiorDesign, Icons.chair_outlined),
    (ServiceCategory.exteriorDesign, Icons.deck_outlined),
    (ServiceCategory.ac, Icons.ac_unit_rounded),
    (ServiceCategory.plumbing, Icons.plumbing_rounded),
    (ServiceCategory.electrical, Icons.bolt_rounded),
    (ServiceCategory.painting, Icons.format_paint_outlined),
    (ServiceCategory.cleaning, Icons.cleaning_services_outlined),
    (ServiceCategory.pestControl, Icons.pest_control_outlined),
    (ServiceCategory.landscaping, Icons.grass_rounded),
    (ServiceCategory.generalMaintenance, Icons.handyman_outlined),
  ];

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Explore', style: theme.textTheme.headlineLarge),
                  const SizedBox(height: 2),
                  Text(
                    'Properties, people and services for your next move.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AqaratiSearchField(
                    hint: 'Search properties, professionals or services',
                    readOnly: true,
                    onTap: () => context.push('/search'),
                  ),
                ],
              ),
            ),
            TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.slate,
              indicatorColor: AppColors.primary,
              tabs: const [
                Tab(text: 'Properties'),
                Tab(text: 'Professionals'),
                Tab(text: 'Services'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _PropertiesTab(types: _propertyTypes),
                  _ProfessionalsTab(categories: _professionalCategories),
                  _ServicesTab(categories: _serviceCategories),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PropertiesTab extends StatelessWidget {
  final List<(PropertyType, IconData)> types;

  const _PropertiesTab({required this.types});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
      children: [
        const SectionHeader(title: 'Popular property types'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: AppSpacing.md,
            crossAxisSpacing: AppSpacing.md,
            childAspectRatio: 2.6,
            children: types
                .map((t) => _ListTile(icon: t.$2, label: t.$1.label, onTap: () => context.push('/search')))
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _ProfessionalsTab extends StatelessWidget {
  final List<(BusinessCategory, IconData)> categories;

  const _ProfessionalsTab({required this.categories});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
      children: [
        const SectionHeader(title: 'All professional categories'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            children: categories
                .map((c) => _ListTile(
                      icon: c.$2,
                      label: c.$1.label,
                      onTap: () => context.push('/professionals'),
                      chevron: true,
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _ServicesTab extends StatelessWidget {
  final List<(ServiceCategory, IconData)> categories;

  const _ServicesTab({required this.categories});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
      children: [
        const SectionHeader(title: 'Get help from verified professionals'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            children: categories
                .map((c) => _ListTile(icon: c.$2, label: c.$1.label, onTap: () {}, chevron: true))
                .toList(),
          ),
        ),
        const SectionHeader(title: 'Property tools'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            children: CalculatorType.values
                .map((type) => _ListTile(
                      icon: Icons.calculate_outlined,
                      label: type.title,
                      onTap: () => Navigator.of(context, rootNavigator: true).push(
                        MaterialPageRoute(builder: (context) => CalculatorScreen(type: type)),
                      ),
                      chevron: true,
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _ListTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool chevron;

  const _ListTile({required this.icon, required this.label, required this.onTap, this.chevron = false});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: AppIconSize.md),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(label, style: Theme.of(context).textTheme.titleSmall),
            ),
            if (chevron) const Icon(Icons.chevron_right_rounded, color: AppColors.mist),
          ],
        ),
      ),
    );
  }
}
