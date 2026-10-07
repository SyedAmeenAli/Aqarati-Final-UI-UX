import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/aqarati_button.dart';
import '../../data/models/property.dart';
import '../../data/repositories/app_state_providers.dart';

class EnquiryScreen extends ConsumerStatefulWidget {
  final Property property;

  const EnquiryScreen({super.key, required this.property});

  @override
  ConsumerState<EnquiryScreen> createState() => _EnquiryScreenState();
}

class _EnquiryScreenState extends ConsumerState<EnquiryScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _messageController = TextEditingController(
    text: "Hi, I'm interested in this property. Could you share more details?",
  );
  bool _sent = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  bool get _canSend =>
      _nameController.text.trim().isNotEmpty &&
      (_emailController.text.trim().isNotEmpty || _phoneController.text.trim().isNotEmpty) &&
      _messageController.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Property Enquiry')),
      body: _sent ? _buildSuccess(theme) : _buildForm(theme),
    );
  }

  Widget _buildForm(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Enquire about this property', style: theme.textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.md),
          _PropertySummaryCard(property: widget.property),
          const SizedBox(height: AppSpacing.xl),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Full name'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(labelText: 'Email address'),
            keyboardType: TextInputType.emailAddress,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _phoneController,
            decoration: const InputDecoration(labelText: 'Phone number'),
            keyboardType: TextInputType.phone,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _messageController,
            decoration: const InputDecoration(labelText: 'Message'),
            maxLines: 4,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.xl),
          AqaratiButton(
            label: 'Send enquiry',
            fullWidth: true,
            onPressed: _canSend
                ? () {
                    ref.read(enquiriesProvider.notifier).update((state) => [
                          ...state,
                          SentEnquiry(
                            id: DateTime.now().millisecondsSinceEpoch.toString(),
                            propertyTitle: widget.property.title,
                            message: _messageController.text.trim(),
                            sentAt: DateTime.now(),
                          ),
                        ]);
                    setState(() => _sent = true);
                  }
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildSuccess(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle_rounded, size: 72, color: AppColors.primary),
          const SizedBox(height: AppSpacing.xl),
          Text('Enquiry sent successfully', style: theme.textTheme.headlineLarge, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.sm),
          Text(
            "We've sent your enquiry to the listing owner. They typically respond within 24 hours.",
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xxxl),
          AqaratiButton(
            label: 'Back to listing',
            fullWidth: true,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

class _PropertySummaryCard extends StatelessWidget {
  final Property property;

  const _PropertySummaryCard({required this.property});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(color: AppColors.sand, borderRadius: BorderRadius.circular(AppRadius.sm)),
            child: const Icon(Icons.landscape_outlined, color: AppColors.mist),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(property.title, style: theme.textTheme.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(property.priceLabel, style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.primary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
