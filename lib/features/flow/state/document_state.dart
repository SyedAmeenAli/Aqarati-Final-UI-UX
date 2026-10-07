import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/domain/account_models.dart';
import '../../../data/api/account_api.dart';

/// Independent per-file phases. `success` = received by the API, pending review.
enum DocPhase { idle, selecting, uploading, processing, success, failed, retrying, rejected }

const int kMaxDocumentBytes = 10 * 1024 * 1024;

class DocumentState {
  final DocPhase phase;
  final double progress;
  final String? fileName;
  final int? sizeBytes;
  final DateTime? expiry;
  final String? errorKey;
  /// Server-known outcome (verified / under review / needs update). Null for a fresh local upload.
  final DocumentOutcome? outcome;
  final DateTime? uploadedAt;
  /// The action the model asks for (replace, upload...). Drives copy; never invents state.
  final DocAction action;
  const DocumentState({this.phase = DocPhase.idle, this.progress = 0, this.fileName, this.sizeBytes, this.expiry, this.errorKey, this.outcome, this.uploadedAt, this.action = DocAction.none});

  bool get busy => phase == DocPhase.selecting || phase == DocPhase.uploading || phase == DocPhase.processing || phase == DocPhase.retrying;

  DocumentState copyWith({DocPhase? phase, double? progress, String? fileName, int? sizeBytes, DateTime? expiry, String? errorKey, bool clearError = false, DocumentOutcome? outcome, DateTime? uploadedAt, DocAction? action, bool clearOutcome = false}) => DocumentState(
        phase: phase ?? this.phase,
        progress: progress ?? this.progress,
        fileName: fileName ?? this.fileName,
        sizeBytes: sizeBytes ?? this.sizeBytes,
        expiry: expiry ?? this.expiry,
        errorKey: clearError ? null : (errorKey ?? this.errorKey),
        outcome: clearOutcome ? null : (outcome ?? this.outcome),
        uploadedAt: uploadedAt ?? this.uploadedAt,
        action: action ?? this.action,
      );

  /// The calm display state for this tile.
  DocDisplay get display {
    switch (phase) {
      case DocPhase.selecting:
      case DocPhase.uploading:
      case DocPhase.retrying:
        return DocDisplay.uploading;
      case DocPhase.processing:
        return DocDisplay.processing;
      case DocPhase.failed:
        return DocDisplay.failed;
      case DocPhase.rejected:
        return DocDisplay.needsUpdate;
      case DocPhase.success:
        if (expiryStatusOf(expiry) == ExpiryStatus.expired) return DocDisplay.expired;
        return outcome == DocumentOutcome.accepted ? DocDisplay.verified : DocDisplay.underReview;
      case DocPhase.idle:
        return action == DocAction.replaceExpired ? DocDisplay.expired : (action == DocAction.uploadMissing ? DocDisplay.missing : DocDisplay.empty);
    }
  }
}

/// Chooses a file. Replaceable in tests.
abstract class DocumentPicker {
  Future<PickedDocument?> pick();
}

class FilePickerAdapter implements DocumentPicker {
  @override
  Future<PickedDocument?> pick() async {
    final f = await FilePicker.pickFile(type: FileType.custom, allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png']);
    if (f == null) return null;
    final size = await f.length() ?? 0;
    // Oversized files are rejected by the caller; never read them into memory.
    final bytes = size > kMaxDocumentBytes ? Uint8List(0) : await f.readAsBytes();
    return PickedDocument(name: f.name, sizeBytes: size > 0 ? size : bytes.length, bytes: bytes);
  }
}

final documentPickerProvider = Provider<DocumentPicker>((ref) => FilePickerAdapter());

/// File type by SIGNATURE (not by extension).
bool hasAllowedSignature(Uint8List b) {
  bool starts(List<int> sig) => b.length >= sig.length && [for (var i = 0; i < sig.length; i++) b[i] == sig[i]].every((x) => x);
  return starts([0x25, 0x50, 0x44, 0x46]) || starts([0xFF, 0xD8, 0xFF]) || starts([0x89, 0x50, 0x4E, 0x47]);
}

/// One controller per document: failure or retry of one file never touches another.
/// The picked bytes live only in this private buffer, never in [DocumentState],
/// caches, drafts or logs, and are dropped as soon as the upload is accepted.
class DocumentController extends StateNotifier<DocumentState> {
  final Ref ref;
  final DocumentKind kind;
  PickedDocument? _buffer;
  DocumentController(this.ref, this.kind, DocumentState initial) : super(initial);

  void setExpiry(DateTime d) => state = state.copyWith(expiry: d);

  /// Apply server-known status once (e.g. a rejected document) without clobbering live work.
  void seed(DocumentState initial) {
    if (state.phase == DocPhase.idle && state.fileName == null) state = initial;
  }

  /// Choose (or replace) the file, validate, then upload.
  Future<void> chooseAndUpload() async {
    if (state.busy) return;
    final before = state.phase;
    state = state.copyWith(phase: DocPhase.selecting, clearError: true);
    PickedDocument? file;
    try {
      file = await ref.read(documentPickerProvider).pick();
    } catch (_) {
      state = state.copyWith(phase: DocPhase.failed, errorKey: 'docs.err.pick');
      return;
    }
    if (file == null) {
      state = state.copyWith(phase: before); // user cancelled the picker
      return;
    }
    if (file.sizeBytes > kMaxDocumentBytes) {
      state = state.copyWith(phase: DocPhase.failed, errorKey: 'docs.err.size', fileName: file.name);
      return;
    }
    if (!hasAllowedSignature(file.bytes)) {
      state = state.copyWith(phase: DocPhase.failed, errorKey: 'docs.err.type', fileName: file.name);
      return;
    }
    _buffer = file;
    // Images only: a transient in-memory thumbnail for the preview sheet, never stored or sent anywhere.
    if (_isImage(file.bytes)) ref.read(documentPreviewProvider(kind).notifier).state = file.bytes;
    state = state.copyWith(fileName: file.name, sizeBytes: file.sizeBytes);
    await _upload(retry: false);
  }

  /// Retry only this file, reusing the in-memory buffer when it still exists.
  Future<void> retry() async {
    if (state.busy) return;
    if (_buffer == null) return chooseAndUpload();
    await _upload(retry: true);
  }

  Future<void> _upload({required bool retry}) async {
    final file = _buffer;
    if (file == null) return;
    state = state.copyWith(phase: retry ? DocPhase.retrying : DocPhase.uploading, progress: 0, clearError: true);
    try {
      await ref.read(accountApiProvider).uploadDocument(kind, file, state.expiry, (p) {
        if (!mounted) return;
        state = state.copyWith(phase: p >= 1 ? DocPhase.processing : DocPhase.uploading, progress: p);
      });
      if (!mounted) return;
      _buffer = null; // drop the transient upload bytes
      state = state.copyWith(phase: DocPhase.success, progress: 1, uploadedAt: DateTime.now(), outcome: DocumentOutcome.pendingReview, action: DocAction.none);
    } on ApiException catch (e) {
      if (mounted) state = state.copyWith(phase: DocPhase.failed, errorKey: e.code == ApiErrorCode.network ? 'common.networkError' : 'common.genericError');
    } catch (_) {
      if (mounted) state = state.copyWith(phase: DocPhase.failed, errorKey: 'common.genericError');
    }
  }
}

DocumentState initialFromStatus(DocumentStatus? s) {
  if (s == null) return const DocumentState();
  final act = docActionOf(s);
  return switch (s.outcome) {
    DocumentOutcome.notSubmitted => DocumentState(expiry: s.expiry, action: act),
    DocumentOutcome.pendingReview || DocumentOutcome.accepted => DocumentState(phase: DocPhase.success, progress: 1, expiry: s.expiry, fileName: s.fileName, sizeBytes: s.sizeBytes, uploadedAt: s.uploadedAt, outcome: s.outcome, action: act),
    DocumentOutcome.rejected => DocumentState(phase: DocPhase.rejected, expiry: s.expiry, fileName: s.fileName, sizeBytes: s.sizeBytes, uploadedAt: s.uploadedAt, outcome: s.outcome, action: act),
  };
}

bool _isImage(Uint8List b) => (b.length >= 3 && b[0] == 0xFF && b[1] == 0xD8 && b[2] == 0xFF) || (b.length >= 4 && b[0] == 0x89 && b[1] == 0x50 && b[2] == 0x4E && b[3] == 0x47);

/// Transient image bytes for the preview sheet only (memory, released with the tile).
final documentPreviewProvider = StateProvider.autoDispose.family<Uint8List?, DocumentKind>((ref, kind) => null);

/// Keyed per document so each tile owns its own state.
final documentControllerProvider = StateNotifierProvider.autoDispose.family<DocumentController, DocumentState, DocumentKind>((ref, kind) => DocumentController(ref, kind, const DocumentState()));
