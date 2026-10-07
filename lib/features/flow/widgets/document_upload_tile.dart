import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/aq/aq_documents.dart';
import '../../../core/aq/aq_primitives.dart';
import '../../../core/aq/aq_tokens.dart';
import '../../../core/aq/aq_typography.dart';
import '../../../core/domain/account_models.dart';
import '../../../core/localization/flow_strings.dart';
import '../state/document_state.dart';
import 'document_preview.dart';

String documentLabelKey(DocumentKind k) => 'doc.${k.name}';

/// Per-document upload tile with independent state. One tile failing never resets another.
/// Upload bytes stay in a transient buffer; only an image thumbnail is kept in memory for Preview.
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
    // An expired date must be replaced, not reused.
    if (widget.kind.tracksExpiry && (st.expiry == null || expiryStatusOf(st.expiry) == ExpiryStatus.expired)) {
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
    final display = st.display;
    final v = aqDocVisual(display);
    final color = aqDocToneColor(c, v.tone);
    final attention = v.tone == AQDocTone.attention;
    final loc = MaterialLocalizations.of(context);
    final status = switch (display) {
      DocDisplay.uploading => st.phase == DocPhase.retrying ? f.t('docs.state.retrying') : f.t('docs.state.uploading', {'p': (st.progress * 100).round().toString()}),
      DocDisplay.failed => f.t(st.errorKey ?? 'docs.state.failed'),
      _ => f.t(v.key),
    };
    final reason = switch (display) {
      DocDisplay.needsUpdate when widget.rejectionReason != null => '${f.t('ver.reason')}: ${widget.rejectionReason}',
      DocDisplay.expired => f.t('resub.reasonExpired'),
      DocDisplay.missing when st.action == DocAction.uploadMissing => f.t('resub.reasonMissing'),
      _ => null,
    };
    final ex = expiryStatusOf(st.expiry);
    final expiry = st.expiry == null ? null : loc.formatMediumDate(st.expiry!);
    final busy = st.busy;
    final haveFile = st.fileName != null;
    final needsFix = display == DocDisplay.needsUpdate || display == DocDisplay.expired;
    final onFile = display == DocDisplay.underReview || display == DocDisplay.verified;

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
          // The ring only appears when something needs attention.
          border: Border.all(color: attention ? c.danger.withValues(alpha: 0.7) : Colors.transparent, width: 1.2),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: Text(label, style: AQTypography.of(context, AQText.titleMedium))),
            const SizedBox(width: AQSpacing.x2),
            _Pill(text: f.t('docs.required'), color: c.inkSoft),
          ]),
          const SizedBox(height: 2),
          Text(f.t('docdesc.${widget.kind.name}'), style: AQTypography.of(context, AQText.bodySmall, soft: true)),
          const SizedBox(height: AQSpacing.x3),
          AnimatedSwitcher(
            duration: AQMotion.scaled(context, AQMotion.fast),
            child: Row(key: ValueKey(status), children: [
              AQIcon(v.icon, size: AQIconSize.small, color: color),
              const SizedBox(width: AQSpacing.x2),
              Expanded(child: Text(status, style: AQTypography.of(context, AQText.labelMedium, color: color))),
            ]),
          ),
          if (reason != null) ...[
            const SizedBox(height: AQSpacing.x2),
            Text(reason, style: AQTypography.of(context, AQText.bodySmall, color: c.inkSoft)),
          ],
          if (haveFile) ...[
            const SizedBox(height: 2),
            Text('${st.fileName}${st.sizeBytes == null ? '' : ' · ${(st.sizeBytes! / 1024).round()} KB'}', maxLines: 1, overflow: TextOverflow.ellipsis, style: AQTypography.of(context, AQText.bodySmall, color: c.inkFaint)),
          ],
          if (display == DocDisplay.uploading || display == DocDisplay.processing) ...[
            const SizedBox(height: AQSpacing.x3),
            ClipRRect(borderRadius: BorderRadius.circular(3), child: LinearProgressIndicator(value: st.phase == DocPhase.uploading ? st.progress : null, minHeight: 3, color: c.accent, backgroundColor: c.hairline)),
          ],
          if (widget.kind.tracksExpiry) ...[
            const SizedBox(height: AQSpacing.x2),
            AQTextButton(
              label: expiry == null ? f.t('docs.setExpiry') : '${f.t('docs.expiry')}: $expiry',
              color: ex == ExpiryStatus.expired ? c.danger : c.accent,
              onPressed: busy ? null : _pickExpiry,
            ),
          ] else
            const SizedBox(height: AQSpacing.x2),
          Text(f.t('docs.rules'), style: AQTypography.of(context, AQText.bodySmall, color: c.inkFaint)),
          const SizedBox(height: AQSpacing.x3),
          Wrap(spacing: AQSpacing.x2, runSpacing: AQSpacing.x2, crossAxisAlignment: WrapCrossAlignment.center, children: [
            display == DocDisplay.failed
                ? _TileButton(label: f.t('docs.retry'), primary: true, onTap: ctl.retry)
                : _TileButton(label: (onFile || needsFix) ? f.t('docs.replace') : f.t('docs.choose'), primary: !onFile, onTap: busy ? null : _start),
            if (haveFile && !busy) _TileButton(label: f.t('docs.preview'), primary: false, onTap: () => showDocumentPreview(context, widget.kind)),
          ]),
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
            Flexible(child: Text(label, style: AQTypography.of(context, AQText.titleSmall, color: fg))),
          ]),
        ),
      ),
    );
  }
}
