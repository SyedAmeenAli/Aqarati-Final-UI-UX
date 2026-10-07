import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/aq/aq_primitives.dart';
import '../../../core/aq/aq_tokens.dart';
import '../../../core/aq/aq_typography.dart';
import '../../../core/domain/account_models.dart';
import '../../../core/localization/flow_strings.dart';
import '../state/document_state.dart';

String documentLabelKey(DocumentKind k) => 'doc.${k.name}';

/// Per-document upload tile with independent state: idle, selecting, uploading,
/// processing (scanning), success (received, pending review), failed (retry),
/// retrying, rejected (replace). One tile failing never resets another.
/// File bytes stay in a transient buffer and are never previewed or persisted.
class DocumentUploadTile extends ConsumerStatefulWidget {
  final DocumentKind kind;
  final DocumentState? seed;
  final String? rejectionReason;
  const DocumentUploadTile({super.key, required this.kind, this.seed, this.rejectionReason});

  @override
  ConsumerState<DocumentUploadTile> createState() => _DocumentUploadTileState();
}

class _DocumentUploadTileState extends ConsumerState<DocumentUploadTile> {
  @override
  void initState() {
    super.initState();
    final seed = widget.seed;
    if (seed != null) Future.microtask(() => ref.read(documentControllerProvider(widget.kind).notifier).seed(seed));
  }

  Future<DateTime?> _pickExpiry() async {
    final now = DateTime.now();
    final d = await showDatePicker(context: context, initialDate: now.add(const Duration(days: 365)), firstDate: now, lastDate: DateTime(now.year + 20));
    if (d != null) ref.read(documentControllerProvider(widget.kind).notifier).setExpiry(d);
    return d;
  }

  Future<void> _start() async {
    final st = ref.read(documentControllerProvider(widget.kind));
    if (widget.kind.tracksExpiry && st.expiry == null) {
      final d = await _pickExpiry();
      if (d == null) return;
    }
    if (!mounted) return;
    await ref.read(documentControllerProvider(widget.kind).notifier).chooseAndUpload();
    if (mounted && ref.read(documentControllerProvider(widget.kind)).phase == DocPhase.success) AQHaptics.confirm();
  }

  @override
  Widget build(BuildContext context) {
    final f = FlowStrings.of(context);
    final c = AQColors.of(context);
    final st = ref.watch(documentControllerProvider(widget.kind));
    final ctl = ref.read(documentControllerProvider(widget.kind).notifier);
    final label = f.t(documentLabelKey(widget.kind));
    final done = st.phase == DocPhase.success;
    final bad = st.phase == DocPhase.failed || st.phase == DocPhase.rejected;

    final status = switch (st.phase) {
      DocPhase.idle => f.t('docs.state.idle'),
      DocPhase.selecting => f.t('docs.state.selecting'),
      DocPhase.uploading => f.t('docs.state.uploading', {'p': (st.progress * 100).round().toString()}),
      DocPhase.processing => f.t('docs.state.processing'),
      DocPhase.success => f.t('docs.state.success'),
      DocPhase.failed => f.t(st.errorKey ?? 'docs.state.failed'),
      DocPhase.retrying => f.t('docs.state.retrying'),
      DocPhase.rejected => f.t('docs.state.rejected'),
    };
    final color = done ? c.success : bad ? c.danger : c.inkSoft;
    final icon = done ? 'check' : bad ? 'alert' : 'info';
    final expiry = st.expiry == null ? null : MaterialLocalizations.of(context).formatMediumDate(st.expiry!);
    final ex = expiryStatusOf(st.expiry);

    return Semantics(
      container: true,
      label: '$label. $status',
      child: AnimatedContainer(
        duration: AQMotion.scaled(context, AQMotion.fast),
        margin: const EdgeInsets.only(bottom: AQSpacing.x3),
        padding: const EdgeInsets.all(AQSpacing.x4),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(AQRadius.medium),
          // Border only signals a state that needs attention.
          border: Border.all(color: bad ? c.danger : Colors.transparent, width: 1.2),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: Text(label, style: AQTypography.of(context, AQText.titleMedium))),
            _Pill(text: f.t('docs.required'), color: c.inkSoft),
          ]),
          const SizedBox(height: 2),
          Text(f.t('docdesc.${widget.kind.name}'), style: AQTypography.of(context, AQText.bodySmall, soft: true)),
          const SizedBox(height: AQSpacing.x3),
          AnimatedSwitcher(
            duration: AQMotion.scaled(context, AQMotion.fast),
            child: Row(key: ValueKey(status), children: [
              AQIcon(icon, size: AQIconSize.small, color: color),
              const SizedBox(width: AQSpacing.x2),
              Expanded(child: Text(status, style: AQTypography.of(context, AQText.labelMedium, color: color))),
            ]),
          ),
          if (widget.rejectionReason != null && st.phase == DocPhase.rejected) ...[
            const SizedBox(height: AQSpacing.x2),
            Text('${f.t('ver.reason')}: ${widget.rejectionReason}', style: AQTypography.of(context, AQText.bodySmall, color: c.danger)),
          ],
          if (st.fileName != null) ...[
            const SizedBox(height: 2),
            Text('${st.fileName}${st.sizeBytes == null ? '' : ' · ${(st.sizeBytes! / 1024).round()} KB'}', maxLines: 1, overflow: TextOverflow.ellipsis, style: AQTypography.of(context, AQText.bodySmall, color: c.inkFaint)),
          ],
          if (st.phase == DocPhase.uploading || st.phase == DocPhase.processing || st.phase == DocPhase.retrying) ...[
            const SizedBox(height: AQSpacing.x3),
            ClipRRect(borderRadius: BorderRadius.circular(3), child: LinearProgressIndicator(value: st.phase == DocPhase.uploading ? st.progress : null, minHeight: 3, color: c.accent, backgroundColor: c.hairline)),
          ],
          if (widget.kind.tracksExpiry) ...[
            const SizedBox(height: AQSpacing.x2),
            AQTextButton(
              label: expiry == null ? f.t('docs.setExpiry') : '${f.t('docs.expiry')}: $expiry',
              color: ex == ExpiryStatus.expired ? c.danger : c.accent,
              onPressed: st.busy ? null : _pickExpiry,
            ),
          ] else
            const SizedBox(height: AQSpacing.x2),
          Text(f.t('docs.rules'), style: AQTypography.of(context, AQText.bodySmall, color: c.inkFaint)),
          const SizedBox(height: AQSpacing.x3),
          st.phase == DocPhase.failed
              ? _TileButton(label: f.t('docs.retry'), primary: true, onTap: ctl.retry)
              : _TileButton(label: (done || st.phase == DocPhase.rejected) ? f.t('docs.replace') : f.t('docs.choose'), primary: !done, onTap: st.busy ? null : _start),
        ]),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final Color color;
  const _Pill({required this.text, required this.color});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(AQRadius.small)),
        child: Text(text, style: AQTypography.of(context, AQText.labelSmall, color: color).copyWith(letterSpacing: 0.4)),
      );
}

class _TileButton extends StatelessWidget {
  final String label;
  final bool primary;
  final VoidCallback? onTap;
  const _TileButton({required this.label, required this.primary, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = AQColors.of(context);
    final off = onTap == null;
    final fg = primary ? c.onAccent : (off ? c.inkFaint : c.accent);
    return Semantics(
      button: true,
      enabled: !off,
      label: label,
      excludeSemantics: true,
      child: AQPressable(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 44, minWidth: 48),
          padding: const EdgeInsets.symmetric(horizontal: AQSpacing.x4, vertical: 10),
          decoration: BoxDecoration(
            color: primary ? (off ? c.accentDisabled : c.accent) : c.accent.withValues(alpha: off ? 0.04 : 0.10),
            borderRadius: BorderRadius.circular(AQRadius.medium - 4),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(label, style: AQTypography.of(context, AQText.titleSmall, color: fg)),
          ]),
        ),
      ),
    );
  }
}
