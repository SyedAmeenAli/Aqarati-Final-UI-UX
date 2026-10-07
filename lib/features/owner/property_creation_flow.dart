import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/aqarati_button.dart';
import '../../data/models/enums.dart';
import '../../data/models/money.dart';
import '../../data/models/property.dart';
import '../../data/models/property_verification.dart';
import 'owner_state.dart';

enum _Step { transaction, type, location, basics, details, media, preview, submitted }

class PropertyCreationFlow extends ConsumerStatefulWidget {
  const PropertyCreationFlow({super.key});

  @override
  ConsumerState<PropertyCreationFlow> createState() => _PropertyCreationFlowState();
}

class _PropertyCreationFlowState extends ConsumerState<PropertyCreationFlow> {
  _Step _step = _Step.transaction;
  static const _order = _Step.values;

  TransactionType? _transactionType;
  PropertyType? _propertyType;
  final _locationController = TextEditingController();
  final _priceController = TextEditingController();
  final _bedroomsController = TextEditingController();
  final _bathroomsController = TextEditingController();
  final _areaController = TextEditingController();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _locationController.dispose();
    _priceController.dispose();
    _bedroomsController.dispose();
    _bathroomsController.dispose();
    _areaController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _next() {
    final i = _order.indexOf(_step);
    if (i < _order.length - 1) setState(() => _step = _order[i + 1]);
  }

  void _back() {
    final i = _order.indexOf(_step);
    if (i > 0) setState(() => _step = _order[i - 1]);
  }

  void _submit() {
    final property = Property(
      id: 'owner_${DateTime.now().millisecondsSinceEpoch}',
      title: _titleController.text.trim().isEmpty ? 'Untitled listing' : _titleController.text.trim(),
      locationLabel: _locationController.text.trim(),
      area: _locationController.text.trim(),
      type: _propertyType ?? PropertyType.apartment,
      transactionType: _transactionType ?? TransactionType.buy,
      price: Money(double.tryParse(_priceController.text.replaceAll(',', '')) ?? 0),
      bedrooms: int.tryParse(_bedroomsController.text),
      bathrooms: int.tryParse(_bathroomsController.text),
      areaSqm: double.tryParse(_areaController.text) ?? 0,
      verification: const PropertyVerification(status: VerificationStatus.submitted),
      listedByBusinessId: '',
      description: _descriptionController.text.trim(),
    );
    ref.read(ownerListingsProvider.notifier).update((state) => [...state, property]);
    setState(() => _step = _Step.submitted);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('List a Property')),
      body: SafeArea(child: _buildStep()),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case _Step.transaction:
        return _StepScaffold(
          title: 'Transaction',
          subtitle: 'What are you listing this property for?',
          canContinue: _transactionType != null,
          onBack: null,
          onContinue: _next,
          child: Column(
            children: TransactionType.values
                .map((t) => _OptionTile(
                      label: t.label,
                      selected: _transactionType == t,
                      onTap: () => setState(() => _transactionType = t),
                    ))
                .toList(),
          ),
        );
      case _Step.type:
        return _StepScaffold(
          title: 'Property type',
          subtitle: 'Choose the category that best fits.',
          canContinue: _propertyType != null,
          onBack: _back,
          onContinue: _next,
          child: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: PropertyType.values
                .map((t) => ChoiceChip(
                      label: Text(t.label),
                      selected: _propertyType == t,
                      onSelected: (_) => setState(() => _propertyType = t),
                    ))
                .toList(),
          ),
        );
      case _Step.location:
        return _StepScaffold(
          title: 'Location',
          subtitle: 'Where is this property located?',
          canContinue: _locationController.text.trim().isNotEmpty,
          onBack: _back,
          onContinue: _next,
          child: TextField(
            controller: _locationController,
            decoration: const InputDecoration(hintText: 'e.g. Al Mouj, Muscat, Oman'),
            onChanged: (_) => setState(() {}),
          ),
        );
      case _Step.basics:
        return _StepScaffold(
          title: 'Basics',
          subtitle: 'Add the key facts buyers look for first.',
          canContinue: _priceController.text.trim().isNotEmpty && _areaController.text.trim().isNotEmpty,
          onBack: _back,
          onContinue: _next,
          child: Column(
            children: [
              TextField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Price (OMR)'),
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _bedroomsController,
                      decoration: const InputDecoration(labelText: 'Bedrooms'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: TextField(
                      controller: _bathroomsController,
                      decoration: const InputDecoration(labelText: 'Bathrooms'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _areaController,
                decoration: const InputDecoration(labelText: 'Area (m²)'),
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
              ),
            ],
          ),
        );
      case _Step.details:
        return _StepScaffold(
          title: 'Details',
          subtitle: 'Give this listing a title and description.',
          canContinue: _titleController.text.trim().isNotEmpty,
          onBack: _back,
          onContinue: _next,
          child: Column(
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Listing title'),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 4,
              ),
            ],
          ),
        );
      case _Step.media:
        return _StepScaffold(
          title: 'Photos & documents',
          subtitle: 'Add photos and ownership documents (optional for now).',
          canContinue: true,
          onBack: _back,
          onContinue: _next,
          child: Column(
            children: [
              _UploadPlaceholder(icon: Icons.add_photo_alternate_outlined, label: 'Add photos'),
              const SizedBox(height: AppSpacing.md),
              _UploadPlaceholder(icon: Icons.upload_file_outlined, label: 'Add title deed'),
            ],
          ),
        );
      case _Step.preview:
        return _StepScaffold(
          title: 'Preview',
          subtitle: 'This is how buyers will see your listing.',
          canContinue: true,
          onBack: _back,
          onContinue: _submit,
          continueLabel: 'Submit for review',
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _titleController.text.trim().isEmpty ? 'Untitled listing' : _titleController.text.trim(),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(_locationController.text.trim(), style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'OMR ${_priceController.text.trim()}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.primary),
                ),
              ],
            ),
          ),
        );
      case _Step.submitted:
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.schedule_rounded, size: 72, color: AppColors.pending),
              const SizedBox(height: AppSpacing.xl),
              Text('Under review', style: Theme.of(context).textTheme.headlineLarge, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.sm),
              Text(
                "We've received your listing. Our team is reviewing it before it goes live.",
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xxxl),
              AqaratiButton(
                label: 'Go to Owner Dashboard',
                fullWidth: true,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
    }
  }
}

class _StepScaffold extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  final bool canContinue;
  final VoidCallback? onBack;
  final VoidCallback onContinue;
  final String continueLabel;

  const _StepScaffold({
    required this.title,
    required this.subtitle,
    required this.child,
    required this.canContinue,
    required this.onBack,
    required this.onContinue,
    this.continueLabel = 'Continue',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
          child: Row(
            children: [
              if (onBack != null) IconButton(onPressed: onBack, icon: const Icon(Icons.arrow_back_rounded)),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.headlineMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(subtitle, style: theme.textTheme.bodyMedium),
                const SizedBox(height: AppSpacing.xl),
                child,
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: AqaratiButton(label: continueLabel, fullWidth: true, onPressed: canContinue ? onContinue : null),
        ),
      ],
    );
  }
}

class _OptionTile extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _OptionTile({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: selected ? AppColors.primary : AppColors.line, width: selected ? 1.5 : 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: Theme.of(context).textTheme.titleMedium),
              if (selected) const Icon(Icons.check_circle_rounded, color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }
}

class _UploadPlaceholder extends StatelessWidget {
  final IconData icon;
  final String label;

  const _UploadPlaceholder({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.sand,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: AppColors.slate),
          const SizedBox(height: AppSpacing.sm),
          Text(label, style: Theme.of(context).textTheme.titleSmall),
        ],
      ),
    );
  }
}
