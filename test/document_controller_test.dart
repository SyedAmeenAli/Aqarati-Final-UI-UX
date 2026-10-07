import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aqarati_app/core/domain/account_models.dart';
import 'package:aqarati_app/data/api/account_api.dart';
import 'package:aqarati_app/data/demo/demo_backend.dart';
import 'package:aqarati_app/features/entry/models/signup_purpose.dart';
import 'package:aqarati_app/features/flow/state/document_state.dart';

class _Picker implements DocumentPicker {
  PickedDocument? next;
  _Picker(this.next);
  @override
  Future<PickedDocument?> pick() async => next;
}

PickedDocument _pdf(String name, {int? size}) {
  final bytes = Uint8List.fromList([0x25, 0x50, 0x44, 0x46, 0x2D]);
  return PickedDocument(name: name, sizeBytes: size ?? bytes.length, bytes: bytes);
}

ProviderContainer _container(_Picker picker, DemoBackendState s) => ProviderContainer(overrides: [
      documentPickerProvider.overrideWithValue(picker),
      accountApiProvider.overrideWithValue(DemoAccountApi(s)),
    ]);

void main() {
  final kind = DocumentKind.municipalLicence;

  test('happy path ends in success and keeps no bytes in state', () async {
    final s = DemoBackendState()..purpose = SignupPurpose.constructionCompany;
    final c = _container(_Picker(_pdf('ok.pdf')), s);
    final sub = c.listen(documentControllerProvider(kind), (_, _) {});
    await c.read(documentControllerProvider(kind).notifier).chooseAndUpload();
    expect(sub.read().phase, DocPhase.success);
    expect(s.docs[kind]?.outcome, DocumentOutcome.pendingReview);
    sub.close();
    c.dispose();
  });

  test('failed upload is retryable on its own without re-picking', () async {
    final s = DemoBackendState()..purpose = SignupPurpose.constructionCompany;
    final picker = _Picker(_pdf('fail.pdf'));
    final c = _container(picker, s);
    final sub = c.listen(documentControllerProvider(kind), (_, _) {});
    final ctl = c.read(documentControllerProvider(kind).notifier);
    await ctl.chooseAndUpload();
    expect(sub.read().phase, DocPhase.failed);
    picker.next = null; // retry must reuse the transient buffer, not open the picker
    await ctl.retry();
    expect(sub.read().phase, DocPhase.failed);
    // another document is unaffected
    final other = c.read(documentControllerProvider(DocumentKind.crCertificate));
    expect(other.phase, DocPhase.idle);
    sub.close();
    c.dispose();
  });

  test('rejects wrong type and oversize before any upload', () async {
    final s = DemoBackendState()..purpose = SignupPurpose.constructionCompany;
    final bad = PickedDocument(name: 'x.pdf', sizeBytes: 4, bytes: Uint8List.fromList([0x4D, 0x5A, 0, 0]));
    final c = _container(_Picker(bad), s);
    final sub = c.listen(documentControllerProvider(kind), (_, _) {});
    await c.read(documentControllerProvider(kind).notifier).chooseAndUpload();
    expect(sub.read().errorKey, 'docs.err.type');
    expect(s.docs, isEmpty);
    final big = PickedDocument(name: 'big.pdf', sizeBytes: kMaxDocumentBytes + 1, bytes: Uint8List(0));
    (c.read(documentPickerProvider) as _Picker).next = big;
    await c.read(documentControllerProvider(kind).notifier).chooseAndUpload();
    expect(sub.read().errorKey, 'docs.err.size');
    sub.close();
    c.dispose();
  });

  test('cancelling the picker restores the previous phase', () async {
    final s = DemoBackendState()..purpose = SignupPurpose.constructionCompany;
    final c = _container(_Picker(null), s);
    final sub = c.listen(documentControllerProvider(kind), (_, _) {});
    await c.read(documentControllerProvider(kind).notifier).chooseAndUpload();
    expect(sub.read().phase, DocPhase.idle);
    sub.close();
    c.dispose();
  });
}
