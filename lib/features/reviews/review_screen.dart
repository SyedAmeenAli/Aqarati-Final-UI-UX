import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/aqarati_button.dart';

const _tags = ['Service', 'Communication', 'Quality', 'Timeliness', 'Value'];

class ReviewScreen extends StatefulWidget {
  final String listingLabel;
  final String listingTitle;
  final String priceLabel;
  final double? existingRating;
  final String? existingText;
  final Set<String>? existingTags;

  const ReviewScreen({
    super.key,
    required this.listingLabel,
    required this.listingTitle,
    required this.priceLabel,
    this.existingRating,
    this.existingText,
    this.existingTags,
  });

  bool get isEditing => existingRating != null;

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  late int _rating = (widget.existingRating ?? 0).round();
  late final Set<String> _selectedTags = {...(widget.existingTags ?? {})};
  late final _text = TextEditingController(text: widget.existingText ?? '');
  bool _submitted = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) return _ThanksView(rating: _rating.toDouble());

    final theme = Theme.of(context);
    final canSubmit = _rating > 0 && _text.text.trim().length >= 10;

    return Scaffold(
      appBar: AppBar(title: Text('AQARATI · عقاراتي', style: theme.textTheme.titleMedium)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text(widget.isEditing ? 'Edit your review' : 'How was your experience?', style: theme.textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.lg),
            Container(
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
                        Text(widget.listingLabel.toUpperCase(), style: theme.textTheme.labelSmall?.copyWith(color: AppColors.primary)),
                        Text(widget.listingTitle, style: theme.textTheme.titleSmall),
                        if (widget.priceLabel.isNotEmpty) Text(widget.priceLabel, style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(widget.isEditing ? 'Update your star rating' : 'Tap stars to rate your transaction', style: theme.textTheme.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: List.generate(5, (i) {
                final filled = i < _rating;
                return IconButton(
                  onPressed: () => setState(() => _rating = i + 1),
                  icon: Icon(filled ? Icons.star_rounded : Icons.star_border_rounded, color: AppColors.primary, size: 32),
                );
              }),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('What went well?', style: theme.textTheme.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: _tags.map((t) {
                final selected = _selectedTags.contains(t);
                return ChoiceChip(
                  label: Text(t),
                  selected: selected,
                  onSelected: (v) => setState(() => v ? _selectedTags.add(t) : _selectedTags.remove(t)),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Share details of your experience', style: theme.textTheme.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _text,
              maxLines: 5,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(hintText: 'Write your review here... (Minimum 10 characters)'),
            ),
            const SizedBox(height: AppSpacing.xl),
            AqaratiButton(
              label: widget.isEditing ? 'Update review' : 'Submit review',
              fullWidth: true,
              onPressed: canSubmit ? () => setState(() => _submitted = true) : null,
            ),
            if (widget.isEditing) ...[
              const SizedBox(height: AppSpacing.md),
              AqaratiButton(
                label: 'Report this review',
                variant: AqaratiButtonVariant.text,
                fullWidth: true,
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const ReportReviewScreen()),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ThanksView extends StatelessWidget {
  final double rating;

  const _ThanksView({required this.rating});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text('AQARATI · عقاراتي', style: theme.textTheme.titleMedium)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 2),
                ),
                child: const Icon(Icons.check_rounded, color: AppColors.primary, size: 40),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text('Thanks for your feedback', style: theme.textTheme.headlineLarge, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Your review has been verified and published. It helps other Omani home seekers make better, more trusted decisions.',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.line)),
                child: Column(
                  children: [
                    Text('YOUR SUBMITTED RATING', style: theme.textTheme.labelSmall?.copyWith(color: AppColors.mist)),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ...List.generate(5, (i) => Icon(i < rating ? Icons.star_rounded : Icons.star_border_rounded, color: AppColors.primary)),
                        const SizedBox(width: AppSpacing.sm),
                        Text('${rating.toStringAsFixed(1)} / 5.0', style: theme.textTheme.titleMedium),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxxl),
              AqaratiButton(label: 'Done', fullWidth: true, onPressed: () => Navigator.of(context).pop()),
            ],
          ),
        ),
      ),
    );
  }
}

class ReportReviewScreen extends StatefulWidget {
  const ReportReviewScreen({super.key});

  @override
  State<ReportReviewScreen> createState() => _ReportReviewScreenState();
}

class _ReportReviewScreenState extends State<ReportReviewScreen> {
  String? _reason;
  final _details = TextEditingController();

  static const _reasons = ['Inappropriate content', 'Spam or duplication', 'False information', 'Other violation'];

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text('AQARATI · عقاراتي', style: theme.textTheme.titleMedium)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text('Report this review', style: theme.textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(color: AppColors.red50, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.red200)),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: AppColors.error),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      'AQARATI enforces strict community guidelines for Omani housing reviews. False reporting is subject to penalty.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text('Reason for reporting', style: theme.textTheme.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            for (final r in _reasons)
              RadioListTile<String>(
                contentPadding: EdgeInsets.zero,
                value: r,
                groupValue: _reason,
                activeColor: AppColors.primary,
                title: Text(r),
                onChanged: (v) => setState(() => _reason = v),
              ),
            const SizedBox(height: AppSpacing.lg),
            Text('Additional details (optional)', style: theme.textTheme.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _details,
              maxLines: 4,
              decoration: const InputDecoration(hintText: 'Describe why you are reporting this review...'),
            ),
            const SizedBox(height: AppSpacing.xl),
            AqaratiButton(
              label: 'Submit report',
              icon: Icons.flag_outlined,
              fullWidth: true,
              onPressed: _reason == null
                  ? null
                  : () {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report submitted for review')));
                    },
            ),
          ],
        ),
      ),
    );
  }
}
