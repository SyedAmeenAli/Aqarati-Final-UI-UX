import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/aqarati_button.dart';

enum _Stage { intro, method, waiting, success, failed }

enum _Method { qr, push }

/// Represents the intended THEQA authentication experience per Gov.om's
/// documented QR/push flow. No live THEQA integration exists — this is the
/// frontend states only, ready to wire to a real provider later.
class IdentityVerificationFlow extends StatefulWidget {
  const IdentityVerificationFlow({super.key});

  @override
  State<IdentityVerificationFlow> createState() => _IdentityVerificationFlowState();
}

class _IdentityVerificationFlowState extends State<IdentityVerificationFlow> {
  _Stage _stage = _Stage.intro;
  _Method? _method;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startWaiting(_Method method) {
    setState(() {
      _method = method;
      _stage = _Stage.waiting;
    });
    _timer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _stage = _Stage.success);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Identity Verification')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: _buildStage(),
      ),
    );
  }

  Widget _buildStage() {
    final theme = Theme.of(context);
    switch (_stage) {
      case _Stage.intro:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.fingerprint_rounded, size: 72, color: AppColors.primary),
            const SizedBox(height: AppSpacing.xl),
            Text('Secure authentication', style: theme.textTheme.headlineLarge, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.sm),
            Text(
              "You'll continue with THEQA to confirm your identity. We only ask for what's "
              "needed to verify who you are.",
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xxxl),
            AqaratiButton(label: 'Continue with THEQA', fullWidth: true, onPressed: () => setState(() => _stage = _Stage.method)),
          ],
        );
      case _Stage.method:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Choose how to authenticate', style: theme.textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.xl),
            _MethodTile(
              icon: Icons.qr_code_2_rounded,
              title: 'Scan QR code',
              subtitle: 'Open THEQA and scan the code to confirm.',
              onTap: () => _startWaiting(_Method.qr),
            ),
            const SizedBox(height: AppSpacing.md),
            _MethodTile(
              icon: Icons.notifications_active_outlined,
              title: 'Push notification',
              subtitle: "We'll send a request to your THEQA app.",
              onTap: () => _startWaiting(_Method.push),
            ),
          ],
        );
      case _Stage.waiting:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_method == _Method.qr)
              Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(color: AppColors.sand, borderRadius: BorderRadius.circular(AppRadius.md)),
                child: const Icon(Icons.qr_code_2_rounded, size: 100, color: AppColors.slate),
              )
            else
              const CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: AppSpacing.xl),
            Text(
              _method == _Method.qr ? 'Waiting for scan...' : 'Waiting for approval in THEQA...',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text('This usually takes a few seconds.', style: theme.textTheme.bodySmall),
          ],
        );
      case _Stage.success:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_rounded, size: 72, color: AppColors.primary),
            const SizedBox(height: AppSpacing.xl),
            Text('Identity confirmed', style: theme.textTheme.headlineLarge, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.sm),
            Text("You're verified. This helps others trust your listings and messages.",
                style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.xxxl),
            AqaratiButton(label: 'Continue', fullWidth: true, onPressed: () => Navigator.of(context).pop(true)),
          ],
        );
      case _Stage.failed:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 72, color: AppColors.error),
            const SizedBox(height: AppSpacing.xl),
            Text('Verification unsuccessful', style: theme.textTheme.headlineLarge, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.sm),
            Text('Please try again.', style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.xxxl),
            AqaratiButton(label: 'Try again', fullWidth: true, onPressed: () => setState(() => _stage = _Stage.method)),
          ],
        );
    }
  }
}

class _MethodTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MethodTile({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleSmall),
                  Text(subtitle, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.mist),
          ],
        ),
      ),
    );
  }
}
