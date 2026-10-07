import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/aq/aq_documents.dart';
import '../../../core/aq/aq_primitives.dart';
import '../../../core/aq/aq_scene.dart';
import '../../../core/aq/aq_tokens.dart';
import '../../../core/aq/aq_typography.dart';
import '../../../core/domain/account_models.dart';
import '../../../core/localization/flow_strings.dart';
import '../state/document_state.dart';
import 'document_upload_tile.dart' show documentLabelKey;

/// Document preview sheet. Shows an image thumbnail only when the picked image is still in memory
/// this session; otherwise it shows the document's metadata. No private URLs or storage keys are ever shown.
Future<void> showDocumentPreview(BuildContext context, DocumentKind kind, {DocumentStatus? status}) =>
    showAQSheet<void>(context, builder: (_) => _PreviewBody(kind: kind, status: status));

class _PreviewBody extends ConsumerWidget {
  final DocumentKind kind;
  final DocumentStatus? status;
  const _PreviewBody({required this.kind, this.status});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final f = FlowStrings.of(context);
    final c = AQColors.of(context);
    final st = ref.watch(documentControllerProvider(kind));
    final bytes = ref.watch(documentPreviewProvider(kind));
    final loc = MaterialLocalizations.of(context);
    final s = status;
    final display = s != null ? docDisplayOfStatus(s) : st.display;
    final v = aqDocVisual(display);
    final color = aqDocToneColor(c, v.tone);
    final name = s?.fileName ?? st.fileName ?? '';
    final sizeBytes = s?.sizeBytes ?? st.sizeBytes;
    final uploadedAt = s?.uploadedAt ?? st.uploadedAt;
    final expiry = s?.expiry ?? st.expiry;
    final ext = name.contains('.') ? name.split('.').last.toUpperCase() : '';
    Widget row(String k, String value) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(flex: 2, child: Text(k, style: AQTypography.of(context, AQText.bodySmall, soft: true))),
            Expanded(flex: 3, child: Text(value, style: AQTypography.of(context, AQText.titleSmall))),
          ]),
        );
    return Padding(
      padding: const EdgeInsets.fromLTRB(AQSpacing.x6, AQSpacing.x2, AQSpacing.x6, AQSpacing.x2),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Semantics(header: true, child: Text(f.t(documentLabelKey(kind)), style: AQTypography.of(context, AQText.headlineMedium))),
        const SizedBox(height: AQSpacing.x4),
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 120, maxHeight: 240),
          decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(AQRadius.medium)),
          clipBehavior: Clip.antiAlias,
          child: bytes != null
              ? Semantics(label: name, image: true, child: Image.memory(bytes, fit: BoxFit.contain))
              : Padding(
                  padding: const EdgeInsets.all(AQSpacing.x5),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(ext == 'PDF' ? Icons.picture_as_pdf_outlined : Icons.description_outlined, size: 40, color: c.inkSoft),
                    const SizedBox(height: AQSpacing.x2),
                    if (ext.isNotEmpty) Text(ext, style: AQTypography.of(context, AQText.labelMedium, soft: true)),
                    const SizedBox(height: AQSpacing.x2),
                    Text(f.t('docs.noPreview'), textAlign: TextAlign.center, style: AQTypography.of(context, AQText.bodySmall, soft: true)),
                  ]),
                ),
        ),
        const SizedBox(height: AQSpacing.x4),
        row(f.t('docs.fileName'), name),
        if (sizeBytes != null) row(f.t('docs.fileSize'), '${(sizeBytes / 1024).round()} KB'),
        if (uploadedAt != null) row(f.t('docs.uploadedOn'), loc.formatMediumDate(uploadedAt)),
        if (expiry != null) row(f.t('docs.expiry'), loc.formatMediumDate(expiry)),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(children: [
            Expanded(flex: 2, child: Text(f.t('docs.status'), style: AQTypography.of(context, AQText.bodySmall, soft: true))),
            Expanded(
              flex: 3,
              child: Row(children: [
                AQIcon(v.icon, size: AQIconSize.small, color: color),
                const SizedBox(width: AQSpacing.x2),
                Expanded(child: Text(f.t(v.key, {'p': '100'}), style: AQTypography.of(context, AQText.titleSmall, color: color))),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: AQSpacing.x4),
        AQSecondaryButton(label: f.t('docs.close'), trailingChevron: false, onPressed: () => Navigator.of(context).pop()),
        const SizedBox(height: AQSpacing.x2),
      ]),
    );
  }
}
