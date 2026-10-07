import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/aqarati_button.dart';

class DocumentsScreen extends StatelessWidget {
  const DocumentsScreen({super.key});

  static const _categories = [
    (Icons.home_work_outlined, 'Property', 'Title deeds & plots', 3),
    (Icons.description_outlined, 'Agreements', 'Lease & sales', 5),
    (Icons.request_quote_outlined, 'Quotes', 'Renovations & design', 2),
    (Icons.receipt_long_outlined, 'Invoices', 'Services & utilities', 12),
    (Icons.payments_outlined, 'Payments', 'Rent & fees ledger', 8),
    (Icons.fact_check_outlined, 'Inspections', 'Safety & municipal', 4),
    (Icons.build_outlined, 'Maintenance', 'Repairs & AC logs', 9),
    (Icons.verified_outlined, 'Warranties', 'Appliances & structure', 6),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Documents'),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz_rounded),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const AddDocumentScreen()),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text('AQARATI Records Manager', style: theme.textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.line)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.cloud_outlined, size: AppIconSize.compact, color: AppColors.slate),
                    const SizedBox(width: AppSpacing.sm),
                    Text('Cloud Space Used', style: theme.textTheme.bodyMedium),
                    const Spacer(),
                    Text('24.5 MB of 100 MB', style: theme.textTheme.bodySmall),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: LinearProgressIndicator(value: 0.245, backgroundColor: AppColors.sand, color: AppColors.sand600, minHeight: 6),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Records Categories', style: theme.textTheme.titleSmall),
          const SizedBox(height: AppSpacing.md),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: AppSpacing.md,
            crossAxisSpacing: AppSpacing.md,
            childAspectRatio: 1.6,
            children: _categories.map((c) {
              return InkWell(
                onTap: () {
                  if (c.$2 == 'Agreements') {
                    Navigator.of(context).push(MaterialPageRoute(builder: (context) => const LeaseAgreementScreen()));
                  } else if (c.$2 == 'Property') {
                    Navigator.of(context).push(MaterialPageRoute(builder: (context) => const LandTitleDeedScreen()));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${c.$2} — ${c.$4} files')));
                  }
                },
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.line)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Icon(c.$1, color: AppColors.sand600),
                          Text('${c.$4} Files', style: theme.textTheme.labelSmall?.copyWith(color: AppColors.mist)),
                        ],
                      ),
                      const Spacer(),
                      Text(c.$2, style: theme.textTheme.titleSmall),
                      Text(c.$3, style: theme.textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class LeaseAgreementScreen extends StatelessWidget {
  const LeaseAgreementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lease Agreement'),
        actions: [IconButton(icon: const Icon(Icons.more_horiz_rounded), onPressed: () {})],
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            Text('Agreements / Residential', style: theme.textTheme.bodySmall),
            const SizedBox(height: AppSpacing.lg),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.line)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Annual Lease Agreement', style: theme.textTheme.titleSmall),
                        Text('Al Mouj Muscat, Sector 4, Villa 12B', style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
                    decoration: BoxDecoration(color: AppColors.green100, borderRadius: BorderRadius.circular(AppRadius.sm)),
                    child: Text('Active', style: theme.textTheme.labelSmall?.copyWith(color: AppColors.secondary)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.line)),
              child: Column(
                children: [
                  _KeyValueRow('Lease Term', '01 Jan 2024 - 31 Dec 2024'),
                  _KeyValueRow('Rent Value', '1,200 OMR / Month', valueColor: AppColors.primary),
                  _KeyValueRow('Document ID', 'AQ-LEASE-2024-998'),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.line)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('AQARATI', style: theme.textTheme.titleMedium?.copyWith(color: AppColors.sand700)),
                    Text('MOH REG. 8872/24', style: theme.textTheme.labelSmall?.copyWith(color: AppColors.mist)),
                    const Divider(height: AppSpacing.xl),
                    Center(child: Text('TENANCY CONTRACT', style: theme.textTheme.headlineSmall)),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Standard residential tenancy agreement formulated under the municipal regulations of the Sultanate of Oman.',
                      style: theme.textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(children: [Container(width: 96, height: 1, color: AppColors.line), Text('Landlord Signature', style: theme.textTheme.labelSmall)]),
                        Column(children: [Container(width: 96, height: 1, color: AppColors.line), Text('Tenant Signature', style: theme.textTheme.labelSmall)]),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, size: AppIconSize.compact, color: AppColors.verified),
                        const SizedBox(width: 4),
                        Text('Verified by Ministry of Housing', style: theme.textTheme.labelSmall?.copyWith(color: AppColors.verified)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: AqaratiButton(
                    label: 'Download PDF',
                    icon: Icons.download_rounded,
                    fullWidth: true,
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Downloading PDF...'))),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(AppSpacing.md), side: const BorderSide(color: AppColors.line)),
                  onPressed: () {},
                  child: const Icon(Icons.share_outlined),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class LandTitleDeedScreen extends StatelessWidget {
  const LandTitleDeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Land Title Deed'),
        actions: [IconButton(icon: const Icon(Icons.more_horiz_rounded), onPressed: () {})],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Property / Mulkiya', style: theme.textTheme.bodySmall),
              const SizedBox(height: AppSpacing.xl),
              Container(
                width: 96,
                height: 96,
                decoration: const BoxDecoration(color: AppColors.sand, shape: BoxShape.circle),
                child: const Icon(Icons.shield_outlined, color: AppColors.sand700, size: 36),
              ),
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
                decoration: BoxDecoration(color: AppColors.neutral900, borderRadius: BorderRadius.circular(AppRadius.sm)),
                child: Text('PRIVATE', style: theme.textTheme.labelSmall?.copyWith(color: Colors.white)),
              ),
              const SizedBox(height: AppSpacing.md),
              Text('Secure Document Vault', style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Only you can access this document through AQARATI. Your real estate credentials are encrypted utilizing state-of-the-art secure Omani national ID systems.',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              const Divider(),
              const SizedBox(height: AppSpacing.sm),
              _CheckLine('Omani PKI / Tam authentication active'),
              _CheckLine('Secured behind biometric passcode layer'),
              const SizedBox(height: AppSpacing.xl),
              AqaratiButton(
                label: 'Unlock with Face ID / PIN',
                icon: Icons.lock_open_rounded,
                fullWidth: true,
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Document unlocked'))),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text('Protected by OMR Municipal Security Standards', style: theme.textTheme.labelSmall?.copyWith(color: AppColors.mist)),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckLine extends StatelessWidget {
  final String text;

  const _CheckLine(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          const Icon(Icons.check_rounded, size: AppIconSize.compact, color: AppColors.verified),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(text, style: Theme.of(context).textTheme.bodySmall)),
        ],
      ),
    );
  }
}

class AddDocumentScreen extends StatefulWidget {
  const AddDocumentScreen({super.key});

  @override
  State<AddDocumentScreen> createState() => _AddDocumentScreenState();
}

enum _UploadStage { choose, preview, done }

class _AddDocumentScreenState extends State<AddDocumentScreen> {
  _UploadStage _stage = _UploadStage.choose;
  double _progress = 0;
  Timer? _timer;

  void _startUpload() {
    setState(() {
      _stage = _UploadStage.preview;
      _progress = 0;
    });
    _timer = Timer.periodic(const Duration(milliseconds: 150), (t) {
      setState(() => _progress += 0.08);
      if (_progress >= 1) {
        t.cancel();
        setState(() => _stage = _UploadStage.done);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Document'),
        actions: [IconButton(icon: const Icon(Icons.more_horiz_rounded), onPressed: () {})],
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add new record to AQARATI', style: theme.textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                _StepPill(label: 'Choose', done: true),
                _StepConnector(),
                _StepPill(label: 'Preview', done: _stage != _UploadStage.choose),
                _StepConnector(),
                _StepPill(label: 'Upload', done: _stage == _UploadStage.done, active: _stage == _UploadStage.preview),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            if (_stage == _UploadStage.choose)
              InkWell(
                onTap: _startUpload,
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.xxl),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.line, style: BorderStyle.solid),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.cloud_upload_outlined, size: 40, color: AppColors.sand600),
                      const SizedBox(height: AppSpacing.md),
                      Text('Choose a file to upload', style: theme.textTheme.titleSmall),
                      const SizedBox(height: AppSpacing.xs),
                      Text('Tap to browse Mulkiya_Al_Mouj_Sector4.pdf', style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
              )
            else ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.line)),
                child: Row(
                  children: [
                    const Icon(Icons.picture_as_pdf_outlined, color: AppColors.primary),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Mulkiya_Al_Mouj_Sector4.pdf', style: theme.textTheme.titleSmall),
                          Text('4.2 MB · PDF Document', style: theme.textTheme.bodySmall),
                          if (_stage != _UploadStage.done) ...[
                            const SizedBox(height: AppSpacing.sm),
                            Text('Uploading to secure server...', style: theme.textTheme.labelSmall),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(AppRadius.pill),
                              child: LinearProgressIndicator(value: _progress.clamp(0, 1), backgroundColor: AppColors.sand, color: AppColors.sand600, minHeight: 6),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (_stage != _UploadStage.done)
                      Text('${(_progress.clamp(0, 1) * 100).toInt()}%', style: theme.textTheme.labelSmall)
                    else
                      const Icon(Icons.check_circle_rounded, color: AppColors.verified),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Supported formats: PDF, JPEG, PNG (Max 15MB). Verified through Omani municipal real estate networks automatically.',
                style: theme.textTheme.labelSmall?.copyWith(color: AppColors.mist),
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: AqaratiButton(
                      label: 'Save & Verify',
                      fullWidth: true,
                      onPressed: _stage == _UploadStage.done
                          ? () {
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Document saved — verification in progress')));
                            }
                          : null,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StepPill extends StatelessWidget {
  final String label;
  final bool done;
  final bool active;

  const _StepPill({required this.label, this.done = false, this.active = false});

  @override
  Widget build(BuildContext context) {
    final color = done ? AppColors.verified : (active ? AppColors.sand600 : AppColors.mist);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(done ? Icons.check_circle_rounded : Icons.radio_button_unchecked, size: AppIconSize.compact, color: color),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color)),
      ],
    );
  }
}

class _StepConnector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Expanded(child: Container(height: 1, margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm), color: AppColors.line));
  }
}

class DocumentStatusScreen extends StatelessWidget {
  final String documentName;
  final String reference;

  const DocumentStatusScreen({super.key, this.documentName = 'Al Mouj Tenancy Contract.pdf', this.reference = 'AQ-7729A'});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Document Status')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text('Verification Timeline', style: theme.textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(color: AppColors.red50, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.red200)),
            child: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: AppColors.error),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Verification Ref: $reference', style: theme.textTheme.labelSmall?.copyWith(color: AppColors.mist)),
                      Text(documentName, style: theme.textTheme.titleSmall),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
                  decoration: BoxDecoration(color: AppColors.error, borderRadius: BorderRadius.circular(AppRadius.sm)),
                  child: Text('Action Req.', style: theme.textTheme.labelSmall?.copyWith(color: Colors.white)),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Verification Timeline', style: theme.textTheme.titleSmall),
          const SizedBox(height: AppSpacing.md),
          _TimelineStep(title: 'Submitted', time: '12 Oct 2024, 10:14 AM', detail: 'Document successfully received by AQARATI system.', state: _TimelineState.done),
          _TimelineStep(title: 'Under Review', time: '13 Oct 2024, 02:30 PM', detail: 'Verifying credentials with Omani Ministry of Housing databases.', state: _TimelineState.done),
          _TimelineStep(title: 'Needs Attention', time: 'Active State', detail: 'Signature match mismatch on Page 3. Please review guidelines.', state: _TimelineState.active),
          _TimelineStep(title: 'Verified Document', time: 'Pending Verification', detail: 'Final ledger entry and digital stamp signature creation.', state: _TimelineState.pending, isLast: true),
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(color: AppColors.sand100, borderRadius: BorderRadius.circular(AppRadius.md)),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Fix Tenant Signature', style: theme.textTheme.titleSmall),
                      Text('Go to Page 26 Verification to update signature securely.', style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.sand600,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                    onPressed: () {},
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _TimelineState { done, active, pending }

class _TimelineStep extends StatelessWidget {
  final String title;
  final String time;
  final String detail;
  final _TimelineState state;
  final bool isLast;

  const _TimelineStep({required this.title, required this.time, required this.detail, required this.state, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = switch (state) {
      _TimelineState.done => AppColors.verified,
      _TimelineState.active => AppColors.error,
      _TimelineState.pending => AppColors.mist,
    };
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Icon(state == _TimelineState.done ? Icons.check_circle_rounded : Icons.circle, color: color, size: state == _TimelineState.done ? 22 : 12),
              if (!isLast) Expanded(child: Container(width: 2, color: AppColors.line)),
            ],
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(title, style: theme.textTheme.titleSmall?.copyWith(color: color)),
                      const Spacer(),
                      Text(time, style: theme.textTheme.labelSmall?.copyWith(color: AppColors.mist)),
                    ],
                  ),
                  Text(detail, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KeyValueRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _KeyValueRow(this.label, this.value, {this.valueColor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodySmall),
          Text(value, style: theme.textTheme.titleSmall?.copyWith(color: valueColor)),
        ],
      ),
    );
  }
}
