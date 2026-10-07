import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/aqarati_button.dart';

enum _Stage { upload, review, verified }

/// Property verification — "Is this particular listing valid?" Separate
/// question from identity verification. Human copy per spec section 21.
class PropertyVerificationFlow extends StatefulWidget {
  const PropertyVerificationFlow({super.key});

  @override
  State<PropertyVerificationFlow> createState() => _PropertyVerificationFlowState();
}

class _PropertyVerificationFlowState extends State<PropertyVerificationFlow> {
  _Stage _stage = _Stage.upload;
  bool _titleDeedUploaded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Property Verification')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: switch (_stage) {
          _Stage.upload => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Verify property ownership', style: theme.textTheme.headlineSmall),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Upload the title deed so we can confirm this listing is valid.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.xl),
                InkWell(
                  onTap: () => setState(() => _titleDeedUploaded = true),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    decoration: BoxDecoration(
                      color: AppColors.sand,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                        color: _titleDeedUploaded ? AppColors.verified : AppColors.line,
                        width: _titleDeedUploaded ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          _titleDeedUploaded ? Icons.check_circle_rounded : Icons.upload_file_outlined,
                          size: 40,
                          color: _titleDeedUploaded ? AppColors.verified : AppColors.slate,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          _titleDeedUploaded ? 'Title deed uploaded' : 'Upload title deed',
                          style: theme.textTheme.titleSmall,
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                AqaratiButton(
                  label: 'Submit for review',
                  fullWidth: true,
                  onPressed: _titleDeedUploaded ? () => setState(() => _stage = _Stage.review) : null,
                ),
              ],
            ),
          _Stage.review => Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.schedule_rounded, size: 72, color: AppColors.pending),
                const SizedBox(height: AppSpacing.xl),
                Text('Ownership under review', style: theme.textTheme.headlineLarge, textAlign: TextAlign.center),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  "We've received your documents. Our team is reviewing them — this usually "
                  'takes 1-2 business days.',
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xxxl),
                AqaratiButton(label: 'Done', fullWidth: true, onPressed: () => Navigator.of(context).pop(true)),
              ],
            ),
          _Stage.verified => Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.verified_rounded, size: 72, color: AppColors.verified),
                const SizedBox(height: AppSpacing.xl),
                Text('Property verified', style: theme.textTheme.headlineLarge, textAlign: TextAlign.center),
                const SizedBox(height: AppSpacing.sm),
                Text('Your property has been verified.', style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
              ],
            ),
        },
      ),
    );
  }
}
