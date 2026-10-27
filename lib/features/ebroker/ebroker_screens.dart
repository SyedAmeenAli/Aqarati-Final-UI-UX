import 'package:flutter/material.dart';
import 'package:flutter/services.dart'
    show FilteringTextInputFormatter, LengthLimitingTextInputFormatter;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/aq/aq_demo.dart';
import '../../core/aq/aq_forms.dart';
import '../../core/aq/aq_help.dart';
import '../../core/aq/aq_primitives.dart';
import '../../core/aq/aq_scene.dart';
import '../../core/aq/aq_status.dart';
import '../../core/aq/aq_tokens.dart';
import '../../core/aq/aq_typography.dart';
import '../../core/config/backend_mode.dart';
import '../../core/localization/flow_strings.dart';
import '../../data/api/account_api.dart' show meProvider;
import '../../data/models/enums.dart';
import '../devbuild/db_models.dart'
    show PermissionDeniedException, omanGovernorates;
import '../devbuild/db_widgets.dart'
    show DbErrorCard, DbFieldFrame, DbNotice, DbSelectField, showDbChoiceSheet;
import '../flow/state/document_state.dart'
    show documentPickerProvider, kMaxDocumentBytes;
import '../listings/listing_models.dart'
    show PropertyMarket, kMarketTypes, marketOf;
import '../viewing/domain/viewing_presentation.dart' show AQTone;
import '../viewing/screens/viewing_kit.dart'
    show AQViewingSectionTitle, AQViewingSkeleton;
import '../viewing/widgets/viewing_components.dart';
import '../viewing/widgets/viewing_format.dart';
import '../viewing/widgets/viewing_scaffold.dart';
import 'ebroker_models.dart';
import 'ebroker_repository.dart';

(AQTone, String) _look(EBrokerStatus s) => switch (s) {
  EBrokerStatus.approved => (AQTone.success, 'check'),
  EBrokerStatus.pendingVerification => (AQTone.pending, 'clock'),
  EBrokerStatus.resubmissionRequired => (AQTone.warning, 'alert'),
  EBrokerStatus.rejected => (AQTone.danger, 'close'),
};

class EBrokerStatusPill extends StatelessWidget {
  final EBrokerStatus status;
  const EBrokerStatusPill(this.status, {super.key});
  @override
  Widget build(BuildContext context) {
    final f = FlowStrings.of(context);
    final (tone, icon) = _look(status);
    return AQStatusPill(
      label: f.t('eb.st.${status.name}'),
      tone: tone,
      icon: icon,
      dense: true,
    );
  }
}

String _typeLabel(FlowStrings f, PropertyType t) => f.t('ptype.${t.name}');

// ------------------------------------------------------------------ intro and list

class EBrokerIntroScreen extends ConsumerWidget {
  const EBrokerIntroScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final f = FlowStrings.of(context);
    final c = AQColors.of(context);
    final me = ref.watch(meProvider);
    final signedIn = me.hasValue;
    void back() => aqBack(context, '/properties');
    return AQViewingScaffold(
      title: f.t('eb.title'),
      subtitle: f.t('eb.sub'),
      backLabel: f.t('common.back'),
      onBack: back,
      bottom: signedIn
          ? AQBottomActionBar(
              primary: AQPrimaryButton(
                label: f.t('eb.start'),
                trailingChevron: false,
                onPressed: () => context.push('/sell/new'),
              ),
            )
          : null,
      children: [
        AQViewingSectionTitle(f.t('eb.how.t')),
        AQSurface(
          padding: const EdgeInsets.all(AQSpacing.x4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 1; i <= 4; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AQSpacing.x1),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: c.surfaceSelected,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$i',
                          style: AQTypography.of(
                            context,
                            AQText.labelMedium,
                            color: c.accentDeep,
                          ),
                        ),
                      ),
                      const SizedBox(width: AQSpacing.x3),
                      Expanded(
                        child: Text(
                          f.t('eb.how.$i'),
                          style: AQTypography.of(context, AQText.bodyMedium),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        AQViewingSectionTitle(f.t('eb.fee.t')),
        AQNoticeCard(
          icon: 'info',
          title: f.t('eb.fee.text'),
          body: f.t('eb.fee.note'),
        ),
        const Align(
          alignment: AlignmentDirectional.centerStart,
          child: AQHelpButton(),
        ),
        if (!signedIn)
          Padding(
            padding: const EdgeInsets.only(top: AQSpacing.x2),
            child: AQNoticeCard(
              icon: 'lock',
              title: f.t('eb.signin.t'),
              body: f.t('eb.signin.b'),
            ),
          ),
        if (!signedIn)
          Padding(
            padding: const EdgeInsets.only(top: AQSpacing.x3),
            child: AQPrimaryButton(
              label: f.t('eb.signin.cta'),
              trailingChevron: false,
              onPressed: () => context.push('/login'),
            ),
          ),
        if (signedIn) ...[
          AQViewingSectionTitle(f.t('eb.mine')),
          ref
              .watch(myEBrokerProvider)
              .when(
                loading: () => const AQViewingSkeleton(height: 84),
                error: (e, _) => DbErrorCard(
                  error: e,
                  onRetry: () => ref.invalidate(myEBrokerProvider),
                ),
                data: (list) => list.isEmpty
                    ? DbNotice(f.t('eb.mine.none.b'), icon: 'info')
                    : Column(
                        children: [
                          for (final s in list)
                            Padding(
                              padding: const EdgeInsets.only(
                                bottom: AQSpacing.x3,
                              ),
                              child: _Card(s),
                            ),
                        ],
                      ),
              ),
        ],
        const SizedBox(height: AQSpacing.x4),
        const AQDemoNotice(),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  final EBrokerSubmission s;
  const _Card(this.s);
  @override
  Widget build(BuildContext context) {
    final f = FlowStrings.of(context);
    return Semantics(
      button: true,
      label: '${s.input.title}, ${f.t('eb.st.${s.status.name}')}',
      excludeSemantics: true,
      child: AQPressable(
        onTap: () => context.push('/sell/${s.id}'),
        child: AQSurface(
          padding: const EdgeInsets.all(AQSpacing.x4),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      VFmt.iso(s.input.title),
                      style: AQTypography.of(context, AQText.titleSmall),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_typeLabel(f, s.input.type)} · ${VFmt.iso(s.input.wilayat)}',
                      style: AQTypography.of(
                        context,
                        AQText.bodySmall,
                        soft: true,
                      ),
                    ),
                    const SizedBox(height: AQSpacing.x2),
                    EBrokerStatusPill(s.status),
                  ],
                ),
              ),
              const AQIcon('chevron-right', size: 18, directional: true),
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------ form

class EBrokerFormScreen extends ConsumerStatefulWidget {
  final String? editId;
  const EBrokerFormScreen({super.key, this.editId});
  @override
  ConsumerState<EBrokerFormScreen> createState() => _EBrokerFormState();
}

class _EBrokerFormState extends ConsumerState<EBrokerFormScreen> {
  final _title = TextEditingController();
  final _desc = TextEditingController();
  final _size = TextEditingController();
  final _price = TextEditingController();
  final _deed = TextEditingController();
  PropertyMarket? _market;
  PropertyType? _type;
  String? _gov, _wilayat, _idName, _deedName;
  final List<String> _photos = [];
  bool _accepted = false, _tried = false, _saving = false, _loaded = false;
  String? _failKey, _photoErr, _fileErr;

  bool get _editing => widget.editId != null;

  @override
  void dispose() {
    for (final c in [_title, _desc, _size, _price, _deed]) {
      c.dispose();
    }
    super.dispose();
  }

  double? _num(String s) => double.tryParse(s.trim().replaceAll(',', '.'));

  String? get _eMarket => _market == null ? 'eb.err.market' : null;
  String? get _eType => _type == null ? 'eb.err.type' : null;
  String? get _eTitle => _title.text.trim().isEmpty ? 'eb.err.title' : null;
  String? get _eGov => _gov == null ? 'eb.err.gov' : null;
  String? get _eWil => _wilayat == null ? 'eb.err.wilayat' : null;
  String? get _eSize => (_num(_size.text) ?? 0) > 0 ? null : 'eb.err.size';
  String? get _ePrice => (_num(_price.text) ?? 0) > 0 ? null : 'eb.err.price';
  String? get _eDeed => eBrokerDeedValid(_deed.text) ? null : 'eb.err.deed';
  String? get _eId => _idName == null ? 'eb.err.id' : null;
  String? get _eDeedDoc => _deedName == null ? 'eb.err.deedDoc' : null;
  String? get _ePhotos => _photos.isEmpty ? 'eb.err.photos' : null;
  String? get _eAccept => _accepted ? null : 'eb.err.accept';

  bool get _valid => [
    _eMarket,
    _eType,
    _eTitle,
    _eGov,
    _eWil,
    _eSize,
    _ePrice,
    _eDeed,
    _eId,
    _eDeedDoc,
    _ePhotos,
    _eAccept,
  ].every((e) => e == null);

  void _load(EBrokerSubmission s) {
    if (_loaded) return;
    _loaded = true;
    final i = s.input;
    _market = marketOf(i.type);
    _type = i.type;
    _title.text = i.title;
    _desc.text = i.description;
    _gov = i.governorate;
    _wilayat = i.wilayat;
    _size.text = i.sizeSqm.toStringAsFixed(i.sizeSqm % 1 == 0 ? 0 : 1);
    _price.text = i.priceOmr.toStringAsFixed(i.priceOmr % 1 == 0 ? 0 : 3);
    _deed.text = i.titleDeed;
    _idName = i.ownerIdName;
    _deedName = i.deedDocName;
    _photos.addAll(i.photoNames);
  }

  Future<void> _pickFile(bool owner) async {
    final f = FlowStrings.of(context);
    final d = await ref.read(documentPickerProvider).pick();
    if (d == null || !mounted) return;
    final b = d.bytes;
    final ok =
        d.sizeBytes <= kMaxDocumentBytes &&
        (isJpgOrPng(b) ||
            (b.length > 4 && b[0] == 0x25 && b[1] == 0x50 && b[2] == 0x44));
    setState(() {
      if (ok) {
        _fileErr = null;
        if (owner) {
          _idName = d.name;
        } else {
          _deedName = d.name;
        }
      } else {
        _fileErr = f.t('eb.file.hint');
      }
    });
  }

  Future<void> _addPhoto() async {
    final f = FlowStrings.of(context);
    final d = await ref.read(documentPickerProvider).pick();
    if (d == null || !mounted) return;
    setState(() {
      if (isJpgOrPng(d.bytes) && d.sizeBytes <= kMaxDocumentBytes) {
        _photoErr = null;
        _photos.add(d.name);
      } else {
        _photoErr = f.t('eb.photo.bad');
      }
    });
  }

  Future<void> _submit() async {
    setState(() => _tried = true);
    if (!_valid || _saving) return;
    FocusScope.of(context).unfocus();
    final input = EBrokerInput(
      title: _title.text.trim(),
      description: _desc.text.trim(),
      type: _type!,
      governorate: _gov!,
      wilayat: _wilayat!,
      sizeSqm: _num(_size.text)!,
      priceOmr: _num(_price.text)!,
      titleDeed: _deed.text,
      ownerIdName: _idName!,
      deedDocName: _deedName!,
      photoNames: List.of(_photos),
      feeAccepted: _accepted,
    );
    setState(() {
      _saving = true;
      _failKey = null;
    });
    try {
      final repo = ref.read(eBrokerRepositoryProvider);
      final s = _editing
          ? await repo.resubmit(widget.editId!, input)
          : await repo.submit(input);
      ref.invalidate(myEBrokerProvider);
      ref.invalidate(eBrokerProvider(s.id));
      if (mounted) context.go('/sell/${s.id}?flash=sent');
    } on EBrokerDuplicateException {
      if (mounted) setState(() => _failKey = 'eb.dup');
    } catch (_) {
      if (mounted) setState(() => _failKey = 'eb.fail');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final f = FlowStrings.of(context);
    String? err(String? k) => _tried ? k : null;
    void back() =>
        aqBack(context, _editing ? '/sell/${widget.editId}' : '/sell');

    if (_editing && !_loaded) {
      final async = ref.watch(eBrokerProvider(widget.editId!));
      return async.when(
        loading: () => AQViewingScaffold(
          title: f.t('eb.form.edit'),
          backLabel: f.t('common.back'),
          onBack: back,
          children: const [AQViewingSkeleton(height: 96)],
        ),
        error: (e, _) => AQViewingScaffold(
          title: f.t('eb.form.edit'),
          backLabel: f.t('common.back'),
          onBack: back,
          children: [
            DbErrorCard(
              error: e,
              onRetry: () => ref.invalidate(eBrokerProvider(widget.editId!)),
            ),
          ],
        ),
        data: (s) {
          if (s == null || !s.canResubmit) {
            return AQViewingScaffold(
              title: f.t('eb.form.edit'),
              backLabel: f.t('common.back'),
              onBack: back,
              children: [DbNotice(f.t('eb.d.notFound'), icon: 'info')],
            );
          }
          _load(s);
          return _form(context, f, err, back);
        },
      );
    }
    return _form(context, f, err, back);
  }

  Widget _form(
    BuildContext context,
    FlowStrings f,
    String? Function(String?) err,
    VoidCallback back,
  ) {
    String? txt(String? k) {
      final e = err(k);
      return e == null ? null : f.t(e);
    }

    Widget gap() => const SizedBox(height: AQSpacing.x3);
    Widget fileTile(String label, String? name, bool owner, String? e) =>
        DbFieldFrame(
          label: label,
          required: true,
          error: err(e),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  name == null ? f.t('eb.file.hint') : VFmt.iso(name),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AQTypography.of(
                    context,
                    AQText.bodyMedium,
                    soft: true,
                  ),
                ),
              ),
              AQTextButton(
                label: name == null ? f.t('eb.pick') : f.t('eb.replace'),
                color: AQColors.of(context).accent,
                onPressed: () => _pickFile(owner),
              ),
            ],
          ),
        );
    return AQViewingScaffold(
      title: _editing ? f.t('eb.form.edit') : f.t('eb.form.title'),
      subtitle: f.t('eb.sub'),
      backLabel: f.t('common.back'),
      onBack: back,
      bottom: AQBottomActionBar(
        primary: AQPrimaryButton(
          label: f.t('eb.submit'),
          trailingChevron: false,
          loading: _saving,
          onPressed: _saving ? null : _submit,
        ),
      ),
      children: [
        if (_failKey != null) AQErrorBanner(text: f.t(_failKey!)),
        AQViewingSectionTitle(f.t('eb.sec.owner')),
        fileTile(f.t('eb.f.id'), _idName, true, _eId),
        gap(),
        fileTile(f.t('eb.f.deedDoc'), _deedName, false, _eDeedDoc),
        if (_fileErr != null)
          Padding(
            padding: const EdgeInsets.only(top: AQSpacing.x1),
            child: Text(
              _fileErr!,
              style: AQTypography.of(
                context,
                AQText.bodySmall,
                color: AQColors.of(context).danger,
              ),
            ),
          ),
        AQViewingSectionTitle(f.t('eb.sec.property')),
        DbSelectField<PropertyMarket>(
          label: f.t('eb.f.market'),
          valueLabel: _market == null
              ? null
              : f.t('ls.market.${_market!.name}'),
          hint: f.t('eb.f.market'),
          required: true,
          error: err(_eMarket),
          onTap: () async {
            final r = await showDbChoiceSheet<PropertyMarket>(
              context,
              title: f.t('eb.f.market'),
              options: [
                for (final m in PropertyMarket.values)
                  (m, f.t('ls.market.${m.name}')),
              ],
              selected: _market,
            );
            if (r != null) {
              setState(() {
                if (_market != r) _type = null;
                _market = r;
              });
            }
          },
        ),
        gap(),
        DbSelectField<PropertyType>(
          label: f.t('eb.f.type'),
          valueLabel: _type == null ? null : _typeLabel(f, _type!),
          hint: f.t('eb.f.type'),
          required: true,
          error: err(_eType),
          onTap: _market == null
              ? null
              : () async {
                  final r = await showDbChoiceSheet<PropertyType>(
                    context,
                    title: f.t('eb.f.type'),
                    options: [
                      for (final t in kMarketTypes[_market]!)
                        (t, _typeLabel(f, t)),
                    ],
                    selected: _type,
                  );
                  if (r != null) setState(() => _type = r);
                },
        ),
        gap(),
        AQTextField(
          label: f.t('eb.f.title'),
          controller: _title,
          error: txt(_eTitle),
          onChanged: (_) => setState(() {}),
        ),
        gap(),
        AQTextField(
          label: f.t('eb.f.desc'),
          controller: _desc,
          minLines: 3,
          maxLines: 6,
          keyboardType: TextInputType.multiline,
          action: TextInputAction.newline,
        ),
        AQViewingSectionTitle(f.t('eb.sec.location')),
        DbSelectField<String>(
          label: f.t('eb.f.gov'),
          valueLabel: _gov,
          hint: f.t('eb.f.gov'),
          required: true,
          error: err(_eGov),
          onTap: () async {
            final r = await showDbChoiceSheet<String>(
              context,
              title: f.t('eb.f.gov'),
              options: [for (final g in omanGovernorates.keys) (g, g)],
              selected: _gov,
            );
            if (r != null) {
              setState(() {
                if (_gov != r) _wilayat = null;
                _gov = r;
              });
            }
          },
        ),
        gap(),
        DbSelectField<String>(
          label: f.t('eb.f.wilayat'),
          valueLabel: _wilayat,
          hint: f.t('eb.f.wilayat'),
          required: true,
          error: err(_eWil),
          onTap: _gov == null
              ? null
              : () async {
                  final r = await showDbChoiceSheet<String>(
                    context,
                    title: f.t('eb.f.wilayat'),
                    options: [for (final w in omanGovernorates[_gov]!) (w, w)],
                    selected: _wilayat,
                  );
                  if (r != null) setState(() => _wilayat = r);
                },
        ),
        AQViewingSectionTitle(f.t('eb.sec.facts')),
        AQTextField(
          label: f.t('eb.f.size'),
          controller: _size,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          formatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            LengthLimitingTextInputFormatter(10),
          ],
          error: txt(_eSize),
          onChanged: (_) => setState(() {}),
        ),
        gap(),
        AQTextField(
          label: f.t('eb.f.price'),
          controller: _price,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          formatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            LengthLimitingTextInputFormatter(14),
          ],
          error: txt(_ePrice),
          onChanged: (_) => setState(() {}),
        ),
        gap(),
        AQTextField(
          label: f.t('eb.f.deed'),
          controller: _deed,
          error: txt(_eDeed),
          formatters: [LengthLimitingTextInputFormatter(24)],
          onChanged: (_) => setState(() {}),
        ),
        AQViewingSectionTitle(f.t('eb.sec.photos')),
        if (_photos.isEmpty)
          DbNotice(txt(_ePhotos) ?? f.t('eb.photo.none'), icon: 'info')
        else
          for (var i = 0; i < _photos.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: AQSpacing.x1),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      VFmt.iso(_photos[i]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AQTypography.of(context, AQText.bodyMedium),
                    ),
                  ),
                  AQIconButton(
                    icon: 'close',
                    semanticsLabel: f.t('eb.photo.remove', {'n': '${i + 1}'}),
                    onPressed: () => setState(() => _photos.removeAt(i)),
                  ),
                ],
              ),
            ),
        if (_photoErr != null)
          Text(
            _photoErr!,
            style: AQTypography.of(
              context,
              AQText.bodySmall,
              color: AQColors.of(context).danger,
            ),
          ),
        AQTextButton(
          label: f.t('eb.photo.add'),
          color: AQColors.of(context).accent,
          onPressed: _addPhoto,
        ),
        AQViewingSectionTitle(f.t('eb.sec.fee')),
        AQNoticeCard(
          icon: 'info',
          title: f.t('eb.fee.text'),
          body: f.t('eb.fee.note'),
        ),
        const SizedBox(height: AQSpacing.x2),
        AQCheckRow(
          value: _accepted,
          label: f.t('eb.accept'),
          error: txt(_eAccept),
          onChanged: (v) => setState(() => _accepted = v),
        ),
        const SizedBox(height: AQSpacing.x4),
        if (kUseDemoBackend) DbNotice(f.t('eb.demo'), icon: 'info'),
      ],
    );
  }
}

// ------------------------------------------------------------------ detail

class EBrokerDetailScreen extends ConsumerWidget {
  final String id;
  final String? flash;
  const EBrokerDetailScreen({super.key, required this.id, this.flash});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final f = FlowStrings.of(context);
    void back() => aqBack(context, '/sell');
    final async = ref.watch(eBrokerProvider(id));
    return async.when(
      loading: () => AQViewingScaffold(
        title: f.t('eb.d.title'),
        backLabel: f.t('common.back'),
        onBack: back,
        children: const [AQViewingSkeleton(height: 96)],
      ),
      error: (e, _) => AQViewingScaffold(
        title: f.t('eb.d.title'),
        backLabel: f.t('common.back'),
        onBack: back,
        children: [
          if (e is PermissionDeniedException)
            AQNoticeCard(
              icon: 'lock',
              title: f.t('eb.d.denied.t'),
              body: f.t('eb.d.denied.b'),
            )
          else
            DbErrorCard(
              error: e,
              onRetry: () => ref.invalidate(eBrokerProvider(id)),
            ),
        ],
      ),
      data: (s) {
        if (s == null) {
          return AQViewingScaffold(
            title: f.t('eb.d.title'),
            backLabel: f.t('common.back'),
            onBack: back,
            children: [
              AQNoticeCard(icon: 'info', title: f.t('eb.d.notFound'), body: ''),
            ],
          );
        }
        final (tone, icon) = _look(s.status);
        final i = s.input;
        Widget row(String k, String v) => Padding(
          padding: const EdgeInsets.symmetric(vertical: AQSpacing.x1),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 110,
                child: Text(
                  k,
                  style: AQTypography.of(context, AQText.bodySmall, soft: true),
                ),
              ),
              Expanded(
                child: Text(
                  v,
                  style: AQTypography.of(context, AQText.bodyMedium),
                ),
              ),
            ],
          ),
        );
        return AQViewingScaffold(
          title: VFmt.iso(i.title),
          subtitle:
              'OMR ${i.priceOmr.toStringAsFixed(i.priceOmr % 1 == 0 ? 0 : 3)}',
          backLabel: f.t('common.back'),
          onBack: back,
          bottom: s.canResubmit
              ? AQBottomActionBar(
                  primary: AQPrimaryButton(
                    label: f.t('eb.d.edit'),
                    trailingChevron: false,
                    onPressed: () => context.push('/sell/${s.id}/edit'),
                  ),
                )
              : null,
          children: [
            if (flash == 'sent')
              AQErrorBanner(
                tone: AQBannerTone.success,
                text: '${f.t('eb.sent')} ${f.t('eb.sent.b')}',
              ),
            const SizedBox(height: AQSpacing.x2),
            AQNoticeCard(
              icon: icon,
              title: f.t('eb.st.${s.status.name}'),
              body: f.t('eb.ex.${s.status.name}'),
              tone: tone,
            ),
            if (s.feedback != null && s.feedback!.isNotEmpty) ...[
              AQViewingSectionTitle(f.t('eb.d.feedback')),
              AQSurface(
                padding: const EdgeInsets.all(AQSpacing.x4),
                child: Text(
                  s.feedback!,
                  style: AQTypography.of(context, AQText.bodyMedium),
                ),
              ),
            ],
            AQViewingSectionTitle(f.t('eb.sec.property')),
            AQSurface(
              padding: const EdgeInsets.all(AQSpacing.x4),
              child: Column(
                children: [
                  row(f.t('eb.f.type'), _typeLabel(f, i.type)),
                  row(
                    f.t('eb.f.gov'),
                    VFmt.iso('${i.wilayat}, ${i.governorate}'),
                  ),
                  row(
                    f.t('eb.f.size'),
                    '${i.sizeSqm.toStringAsFixed(i.sizeSqm % 1 == 0 ? 0 : 1)} m²',
                  ),
                  row(f.t('eb.f.deed'), VFmt.iso(i.titleDeed)),
                  row(f.t('eb.sec.photos'), '${i.photoNames.length}'),
                ],
              ),
            ),
            AQViewingSectionTitle(f.t('eb.d.fee')),
            AQNoticeCard(
              icon: 'check',
              title: f.t('eb.fee.text'),
              body: s.feeAcceptedAt == null
                  ? ''
                  : VFmt.fullDate(context, s.feeAcceptedAt!),
            ),
            if (kShowReviewTools) _QaReview(id: s.id),
            const SizedBox(height: AQSpacing.x4),
            if (kUseDemoBackend) DbNotice(f.t('eb.demo'), icon: 'info'),
          ],
        );
      },
    );
  }
}

/// QA only (`REVIEW_TOOLS`): stands in for the reviewer. Never in a production build.
class _QaReview extends ConsumerWidget {
  final String id;
  const _QaReview({required this.id});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(eBrokerRepositoryProvider);
    if (repo is! DemoEBrokerRepository) return const SizedBox.shrink();
    void decide(EBrokerStatus s, {String? feedback}) {
      repo.debugSet(id, s, feedback: feedback);
      ref.invalidate(eBrokerProvider(id));
      ref.invalidate(myEBrokerProvider);
    }

    return Padding(
      padding: const EdgeInsets.only(top: AQSpacing.x4),
      child: AQSurface(
        padding: const EdgeInsets.all(AQSpacing.x3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'QA only: simulate the reviewer',
              style: AQTypography.of(context, AQText.labelMedium, soft: true),
            ),
            const SizedBox(height: AQSpacing.x2),
            AQSecondaryButton(
              label: 'Reviewer approves',
              trailingChevron: false,
              onPressed: () => decide(EBrokerStatus.approved),
            ),
            const SizedBox(height: AQSpacing.x2),
            AQSecondaryButton(
              label: 'Reviewer asks for changes',
              trailingChevron: false,
              onPressed: () => decide(
                EBrokerStatus.resubmissionRequired,
                feedback: 'Sample feedback: the title deed is hard to read.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
