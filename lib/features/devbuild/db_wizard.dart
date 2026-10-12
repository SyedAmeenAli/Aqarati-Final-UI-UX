import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/aq/aq_forms.dart';
import '../../core/aq/aq_primitives.dart';
import '../../core/aq/aq_scene.dart';
import '../../core/aq/aq_tokens.dart';
import '../../core/aq/aq_typography.dart';
import '../../core/localization/flow_strings.dart';
import '../../core/widgets/aqarati_map_view.dart';
import '../../data/models/enums.dart';
import '../viewing/widgets/viewing_format.dart';
import '../viewing/widgets/viewing_scaffold.dart';
import 'db_models.dart';
import 'db_projects.dart' show dbNewIdempotencyKey;
import 'db_repository.dart';
import 'db_widgets.dart';
import 'db_workspace.dart';

/// Reads a number typed with Western or Arabic-Indic digits.
double? dbParseNumber(String raw) {
  const ar = '٠١٢٣٤٥٦٧٨٩';
  final b = StringBuffer();
  for (final ch
      in raw.trim().replaceAll(',', '').replaceAll('٫', '.').split('')) {
    final i = ar.indexOf(ch);
    b.write(i >= 0 ? '$i' : ch);
  }
  return double.tryParse(b.toString());
}

int _stepOfField(String key) => switch (key) {
  'name' || 'type' => 0,
  'beds' || 'baths' || 'area' || 'land' => 1,
  'gov' || 'wil' || 'coords' => 3,
  _ => 4,
};

/// Create (#70-#75) and edit (#83) share one five-step wizard. The draft lives in this state, so
/// it survives moving between steps and jumping back from the review.
class DbWizardScreen extends ConsumerStatefulWidget {
  final String? projectId;
  final int startStep;
  const DbWizardScreen({super.key, this.projectId, this.startStep = 0});
  @override
  ConsumerState<DbWizardScreen> createState() => _DbWizardScreenState();
}

class _DbWizardScreenState extends ConsumerState<DbWizardScreen> {
  final _draft = ProjectDraft();
  late int _step = widget.startStep.clamp(0, 4);
  Map<String, String> _errors = {};
  bool _busy = false;
  bool _dirty = false;
  bool _loaded = false;
  Object? _failure;
  String? _key;
  DbProject? _existing;

  final _name = TextEditingController();
  final _area = TextEditingController();
  final _land = TextEditingController();
  final _areaName = TextEditingController();
  final _lat = TextEditingController();
  final _lng = TextEditingController();

  bool get _isEdit => widget.projectId != null;

  @override
  void dispose() {
    for (final c in [_name, _area, _land, _areaName, _lat, _lng]) {
      c.dispose();
    }
    super.dispose();
  }

  void _load(DbProject p) {
    if (_loaded) return;
    _loaded = true;
    _existing = p;
    final d = p.toDraft();
    _draft
      ..id = d.id
      ..name = d.name
      ..type = d.type
      ..bedrooms = d.bedrooms
      ..bathrooms = d.bathrooms
      ..landSqm = d.landSqm
      ..areaSqm = d.areaSqm
      ..governorate = d.governorate
      ..wilayat = d.wilayat
      ..area = d.area
      ..latitude = d.latitude
      ..longitude = d.longitude;
    _name.text = d.name;
    _area.text = d.areaSqm == null ? '' : '${d.areaSqm!.round()}';
    _land.text = d.landSqm == null ? '' : '${d.landSqm!.round()}';
    _areaName.text = d.area;
    _lat.text = d.latitude?.toString() ?? '';
    _lng.text = d.longitude?.toString() ?? '';
  }

  /// Any edit invalidates a pending submission key so a changed draft is never replayed as the old one.
  void _touch([VoidCallback? fn]) => setState(() {
    fn?.call();
    _dirty = true;
    _key = null;
    _failure = null;
  });

  bool _validateStep(int s) {
    final e = _draft.validate(ProjectStep.values[s]);
    setState(() => _errors = e);
    return e.isEmpty;
  }

  void _next() {
    if (!_validateStep(_step)) return;
    setState(() => _step = (_step + 1).clamp(0, 4));
  }

  Future<bool> _confirmLeave() async {
    final f = FlowStrings.of(context);
    final r = await showAQSheet<String>(
      context,
      useRootNavigator: true,
      builder: (s) => Padding(
        padding: const EdgeInsets.fromLTRB(
          AQSpacing.gutter,
          AQSpacing.x3,
          AQSpacing.gutter,
          AQSpacing.x4,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              f.t('db.wiz.leave.t'),
              style: AQTypography.of(s, AQText.headlineSmall),
            ),
            const SizedBox(height: AQSpacing.x2),
            Text(
              f.t('db.wiz.leave.b'),
              style: AQTypography.of(s, AQText.bodyMedium, soft: true),
            ),
            const SizedBox(height: AQSpacing.x4),
            AQPrimaryButton(
              label: f.t('db.wiz.keep'),
              trailingChevron: false,
              onPressed: () => Navigator.of(s).pop('keep'),
            ),
            const SizedBox(height: AQSpacing.x2),
            AQSecondaryButton(
              label: f.t('db.wiz.discard'),
              trailingChevron: false,
              foreground: AQColors.of(s).danger,
              onPressed: () => Navigator.of(s).pop('discard'),
            ),
          ],
        ),
      ),
    );
    return r == 'discard';
  }

  Future<void> _back() async {
    if (_step > 0) {
      setState(() => _step -= 1);
      return;
    }
    if (_dirty && !await _confirmLeave()) return;
    if (mounted) aqBack(context, '/app/account/workspace/projects');
  }

  Future<void> _save({required bool submit}) async {
    // One request at a time: a second tap while the first is in flight must not send a second write.
    if (_busy) return;
    if (submit) {
      final all = _draft.validateAll();
      if (all.isNotEmpty) {
        final merged = <String, String>{for (final m in all.values) ...m};
        final first = merged.keys
            .map(_stepOfField)
            .reduce((a, b) => a < b ? a : b);
        setState(() {
          _errors = merged;
          _step = first;
        });
        return;
      }
    } else if (_draft.name.trim().length < 3) {
      setState(() {
        _errors = {'name': 'db.err.name'};
        _step = 0;
      });
      return;
    }
    setState(() {
      _busy = true;
      _failure = null;
    });
    try {
      _key ??= dbNewIdempotencyKey();
      final saved = await ref
          .read(devBuildRepositoryProvider)
          .saveProject(_draft, submit: submit, idempotencyKey: _key!);
      ref.invalidate(dbMyProjectsProvider);
      ref.invalidate(dbMyProjectProvider(saved.id));
      _dirty = false;
      if (mounted)
        context.go(
          '/workspace/projects/${saved.id}/submitted?r=${submit ? 'submitted' : 'draft'}',
        );
    } on ProjectValidationException catch (e) {
      // The server refused the content, so the next attempt is a new request, not a retry.
      _key = null;
      if (mounted) {
        setState(() {
          _errors = e.fields;
          if (e.fields.isNotEmpty)
            _step = e.fields.keys
                .map(_stepOfField)
                .reduce((a, b) => a < b ? a : b);
        });
      }
    } catch (e) {
      if (mounted) setState(() => _failure = e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ---- step bodies

  Future<void> _pickType() async {
    final f = FlowStrings.of(context);
    final r = await showDbChoiceSheet<PropertyType>(
      context,
      title: f.t('db.f.type'),
      selected: _draft.type,
      options: [for (final t in projectTypes) (t, dbTypeLabel(f, t))],
    );
    if (r != null) {
      _touch(() {
        _draft.type = r;
        _errors = {..._errors}..remove('type');
        if (!typeHasRooms(r)) {
          _draft.bedrooms = null;
          _draft.bathrooms = null;
        }
      });
    }
  }

  Future<void> _pickCount(String field) async {
    final f = FlowStrings.of(context);
    final cur = field == 'beds' ? _draft.bedrooms : _draft.bathrooms;
    final r = await showDbChoiceSheet<int>(
      context,
      title: f.t(field == 'beds' ? 'db.f.beds' : 'db.f.baths'),
      selected: cur,
      options: [for (var i = 1; i <= 12; i++) (i, VFmt.n(context, i))],
    );
    if (r != null) {
      _touch(() {
        field == 'beds' ? _draft.bedrooms = r : _draft.bathrooms = r;
        _errors = {..._errors}..remove(field);
      });
    }
  }

  Future<void> _pickGov() async {
    final f = FlowStrings.of(context);
    final r = await showDbChoiceSheet<String>(
      context,
      title: f.t('db.f.gov'),
      selected: _draft.governorate,
      options: [for (final g in omanGovernorates.keys) (g, dbGovLabel(f, g))],
    );
    if (r != null) {
      _touch(() {
        if (_draft.governorate != r) _draft.wilayat = null;
        _draft.governorate = r;
        _errors = {..._errors}..remove('gov');
      });
    }
  }

  Future<void> _pickWilayat() async {
    final f = FlowStrings.of(context);
    final g = _draft.governorate;
    if (g == null) return;
    final r = await showDbChoiceSheet<String>(
      context,
      title: f.t('db.f.wil'),
      selected: _draft.wilayat,
      options: [for (final w in omanGovernorates[g]!) (w, w)],
    );
    if (r != null) {
      _touch(() {
        _draft.wilayat = r;
        _errors = {..._errors}..remove('wil');
      });
    }
  }

  Widget _numberField({
    required String label,
    required TextEditingController ctl,
    required String errorKey,
    String? helper,
    required void Function(double?) onValue,
    bool required = false,
  }) {
    final f = FlowStrings.of(context);
    return AQTextField(
      label: required ? '$label *' : label,
      controller: ctl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      formatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9٠-٩.,٫]'))],
      helper: helper,
      error: _errors[errorKey] == null ? null : f.t(_errors[errorKey]!),
      onChanged: (v) => _touch(() {
        onValue(dbParseNumber(v));
        _errors = {..._errors}..remove(errorKey);
      }),
    );
  }

  Widget _stepBasic(FlowStrings f) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      AQTextField(
        label: '${f.t('db.f.name')} *',
        controller: _name,
        hint: f.t('db.f.name.hint'),
        error: _errors['name'] == null ? null : f.t(_errors['name']!),
        onChanged: (v) => _touch(() {
          _draft.name = v;
          _errors = {..._errors}..remove('name');
        }),
      ),
      const SizedBox(height: AQSpacing.x4),
      DbSelectField<PropertyType>(
        label: f.t('db.f.type'),
        required: true,
        valueLabel: _draft.type == null ? null : dbTypeLabel(f, _draft.type!),
        hint: f.t('db.f.type.hint'),
        error: _errors['type'],
        onTap: _pickType,
      ),
      const SizedBox(height: AQSpacing.x5),
      DbNotice(f.t('db.wiz.unsupported'), icon: 'info'),
    ],
  );

  Widget _stepDetails(FlowStrings f) {
    final t = _draft.type;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (t == null)
          DbNotice(f.t('db.wiz.pickTypeFirst'), icon: 'info')
        else ...[
          Text(
            dbTypeLabel(f, t),
            style: AQTypography.of(
              context,
              AQText.titleMedium,
              color: AQColors.of(context).accentDeep,
            ),
          ),
          const SizedBox(height: AQSpacing.x4),
        ],
        if (typeHasRooms(t)) ...[
          DbSelectField<int>(
            label: f.t('db.f.beds'),
            required: true,
            valueLabel: _draft.bedrooms == null
                ? null
                : VFmt.n(context, _draft.bedrooms!),
            hint: f.t('db.f.select'),
            error: _errors['beds'],
            onTap: () => _pickCount('beds'),
          ),
          const SizedBox(height: AQSpacing.x4),
          DbSelectField<int>(
            label: f.t('db.f.baths'),
            required: true,
            valueLabel: _draft.bathrooms == null
                ? null
                : VFmt.n(context, _draft.bathrooms!),
            hint: f.t('db.f.select'),
            error: _errors['baths'],
            onTap: () => _pickCount('baths'),
          ),
          const SizedBox(height: AQSpacing.x4),
        ],
        if (!typeIsLand(t)) ...[
          _numberField(
            label: f.t('db.f.built'),
            ctl: _area,
            errorKey: 'area',
            required: true,
            helper: f.t('db.f.sqm'),
            onValue: (v) => _draft.areaSqm = v,
          ),
          const SizedBox(height: AQSpacing.x4),
        ],
        _numberField(
          label: f.t('db.f.land'),
          ctl: _land,
          errorKey: 'land',
          required: typeIsLand(t),
          helper: f.t('db.f.sqm'),
          onValue: (v) => _draft.landSqm = v,
        ),
      ],
    );
  }

  Widget _stepMedia(FlowStrings f) {
    final c = AQColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          label: '${f.t('db.f.photos')}. ${f.t('db.wiz.media.off')}',
          excludeSemantics: true,
          child: Container(
            padding: const EdgeInsets.all(AQSpacing.x5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AQRadius.medium),
              border: Border.all(color: c.hairline),
              color: c.surface,
            ),
            child: Column(
              children: [
                AQIcon('lock', size: 26, color: c.inkFaint),
                const SizedBox(height: AQSpacing.x2),
                Text(
                  f.t('db.f.photos'),
                  style: AQTypography.of(
                    context,
                    AQText.titleSmall,
                    color: c.inkSoft,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  f.t('db.wiz.media.off'),
                  textAlign: TextAlign.center,
                  style: AQTypography.of(context, AQText.bodySmall, soft: true),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AQSpacing.x3),
        DbNotice(f.t('db.wiz.media.note'), icon: 'info'),
      ],
    );
  }

  Widget _stepLocation(FlowStrings f) {
    final g = _draft.governorate;
    final centre = g == null ? null : omanGovernorateCentre[g];
    final lat = _draft.latitude ?? centre?.$1;
    final lng = _draft.longitude ?? centre?.$2;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DbSelectField<String>(
          label: f.t('db.f.gov'),
          required: true,
          valueLabel: g == null ? null : dbGovLabel(f, g),
          hint: f.t('db.f.select'),
          error: _errors['gov'],
          onTap: _pickGov,
        ),
        const SizedBox(height: AQSpacing.x4),
        DbSelectField<String>(
          label: f.t('db.f.wil'),
          required: true,
          valueLabel: _draft.wilayat,
          hint: g == null ? f.t('db.f.gov.first') : f.t('db.f.select'),
          error: _errors['wil'],
          onTap: g == null ? null : _pickWilayat,
        ),
        const SizedBox(height: AQSpacing.x4),
        AQTextField(
          label: f.t('db.f.area'),
          controller: _areaName,
          hint: f.t('db.f.area.hint'),
          onChanged: (v) => _touch(() => _draft.area = v),
        ),
        const SizedBox(height: AQSpacing.x4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _numberField(
                label: f.t('db.f.lat'),
                ctl: _lat,
                errorKey: 'coords',
                onValue: (v) => _draft.latitude = v,
              ),
            ),
            const SizedBox(width: AQSpacing.x3),
            Expanded(
              child: _numberField(
                label: f.t('db.f.lng'),
                ctl: _lng,
                errorKey: 'coords',
                onValue: (v) => _draft.longitude = v,
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(top: AQSpacing.x1),
          child: Text(
            f.t('db.f.coords.note'),
            style: AQTypography.of(context, AQText.bodySmall, soft: true),
          ),
        ),
        if (lat != null &&
            lng != null &&
            lat >= 16 &&
            lat <= 27 &&
            lng >= 51 &&
            lng <= 60) ...[
          const SizedBox(height: AQSpacing.x4),
          ClipRRect(
            borderRadius: BorderRadius.circular(AQRadius.large),
            child: SizedBox(
              height: aqLargeText(context) ? 300 : 190,
              child: AqaratiMapView(
                key: ValueKey('$lat,$lng'),
                initialCenter: LatLng(lat, lng),
                initialZoom: _draft.latitude == null ? 8 : 14,
                interactive: false,
                borderRadius: BorderRadius.zero,
              ),
            ),
          ),
          const SizedBox(height: AQSpacing.x1),
          Text(
            f.t(_draft.latitude == null ? 'db.f.map.region' : 'db.f.map.point'),
            style: AQTypography.of(context, AQText.bodySmall, soft: true),
          ),
        ],
      ],
    );
  }

  Widget _group(FlowStrings f, int step, List<(String, String?)> rows) {
    final c = AQColors.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: AQSpacing.x3),
      padding: const EdgeInsets.all(AQSpacing.x4),
      decoration: BoxDecoration(
        color: c.surfaceRaised,
        borderRadius: BorderRadius.circular(AQRadius.medium),
        border: Border.all(color: c.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  f.t('db.step.$step'),
                  style: AQTypography.of(context, AQText.titleSmall),
                ),
              ),
              AQTextButton(
                label: f.t('common.edit'),
                color: c.accentDeep,
                onPressed: () => setState(() => _step = step),
              ),
            ],
          ),
          for (final r in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      r.$1,
                      style: AQTypography.of(
                        context,
                        AQText.bodySmall,
                        soft: true,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      r.$2 == null || r.$2!.isEmpty
                          ? f.t('db.wiz.missing')
                          : VFmt.iso(r.$2!),
                      style: AQTypography.of(
                        context,
                        AQText.bodyMedium,
                        color: r.$2 == null || r.$2!.isEmpty ? c.danger : c.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _stepReview(FlowStrings f) {
    final d = _draft;
    final t = d.type;
    String? n(num? v, [String suffix = '']) =>
        v == null ? null : '${VFmt.n(context, v.round())}$suffix';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _group(f, 0, [
          (f.t('db.f.name'), d.name.trim()),
          (f.t('db.f.type'), t == null ? null : dbTypeLabel(f, t)),
        ]),
        _group(f, 1, [
          if (typeHasRooms(t)) ...[
            (f.t('db.f.beds'), n(d.bedrooms)),
            (f.t('db.f.baths'), n(d.bathrooms)),
          ],
          if (!typeIsLand(t)) (f.t('db.f.built'), n(d.areaSqm, ' m²')),
          (
            f.t('db.f.land'),
            typeIsLand(t)
                ? n(d.landSqm, ' m²')
                : (d.landSqm == null ? '—' : n(d.landSqm, ' m²')),
          ),
        ]),
        _group(f, 2, [(f.t('db.f.photos'), f.t('db.wiz.notIncluded'))]),
        _group(f, 3, [
          (
            f.t('db.f.gov'),
            d.governorate == null ? null : dbGovLabel(f, d.governorate!),
          ),
          (f.t('db.f.wil'), d.wilayat),
          if (d.area.trim().isNotEmpty) (f.t('db.f.area'), d.area.trim()),
          if (d.latitude != null && d.longitude != null)
            (f.t('db.f.coords'), '${d.latitude}, ${d.longitude}'),
        ]),
        const SizedBox(height: AQSpacing.x2),
        DbNotice(
          f.t(
            _existing?.status == ProjectStatus.approved
                ? 'db.wiz.review.material'
                : 'db.wiz.review.note',
          ),
          icon: 'clock',
        ),
      ],
    );
  }

  Widget _header(FlowStrings f, bool canSaveDraft) {
    final c = AQColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (var i = 0; i < 5; i++) ...[
              Semantics(
                button: i < _step,
                selected: i == _step,
                label: f.t('db.wiz.stepOf', {
                  'a': VFmt.n(context, i + 1),
                  'b': VFmt.n(context, 5),
                  'n': f.t('db.step.$i'),
                }),
                excludeSemantics: true,
                child: AQPressable(
                  onTap: i < _step ? () => setState(() => _step = i) : null,
                  child: SizedBox(
                    width: AQControl.tap - 8,
                    height: AQControl.tap - 8,
                    child: Center(
                      child: AnimatedContainer(
                        duration: AQMotion.scaled(context, AQMotion.standard),
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i <= _step ? c.accent : Colors.transparent,
                          border: Border.all(
                            color: i <= _step ? c.accent : c.hairline,
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: i < _step
                              ? AQIcon('check', size: 16, color: c.onAccent)
                              : Text(
                                  VFmt.n(context, i + 1),
                                  style: AQTypography.of(
                                    context,
                                    AQText.labelMedium,
                                    color: i == _step ? c.onAccent : c.inkSoft,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (i < 4)
                Expanded(
                  child: AnimatedContainer(
                    duration: AQMotion.scaled(context, AQMotion.standard),
                    height: 2,
                    color: i < _step ? c.accent : c.hairline,
                  ),
                ),
            ],
          ],
        ),
        const SizedBox(height: AQSpacing.x3),
        Row(
          children: [
            Expanded(
              child: Semantics(
                liveRegion: true,
                child: Text(
                  f.t('db.wiz.stepOf', {
                    'a': VFmt.n(context, _step + 1),
                    'b': VFmt.n(context, 5),
                    'n': f.t('db.step.$_step'),
                  }),
                  style: AQTypography.of(
                    context,
                    AQText.labelMedium,
                    color: c.accentDeep,
                  ),
                ),
              ),
            ),
            if (canSaveDraft)
              AQTextButton(
                label: f.t('db.wiz.saveDraft'),
                color: c.accentDeep,
                onPressed: _busy ? null : () => _save(submit: false),
              ),
          ],
        ),
      ],
    );
  }

  Widget _scaffold(FlowStrings f, {required Widget body, bool ready = true}) {
    final canSaveDraft = !_isEdit || _existing?.status == ProjectStatus.draft;
    final last = _step == 4;
    final submitKey = _isEdit && _existing?.status == ProjectStatus.approved
        ? 'db.wiz.submitChanges'
        : 'db.wiz.submit';
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: AQViewingScaffold(
        title: f.t(_isEdit ? 'db.wiz.edit' : 'db.wiz.new'),
        subtitle: f.t(_isEdit ? 'db.wiz.edit.sub' : 'db.wiz.new.sub'),
        backLabel: f.t('common.back'),
        onBack: _back,
        bottom: ready
            ? AQBottomActionBar(
                // "Save & continue" wraps to two lines beside Back on the narrowest phones.
                stack: last || MediaQuery.sizeOf(context).width < 380,
                primary: last
                    ? AQPrimaryButton(
                        label: f.t(submitKey),
                        trailingChevron: false,
                        loading: _busy,
                        onPressed: _busy ? null : () => _save(submit: true),
                      )
                    : AQPrimaryButton(
                        label: f.t('db.wiz.next'),
                        trailingChevron: false,
                        onPressed: _busy ? null : _next,
                      ),
                secondary: AQBarSecondaryButton(
                  label: f.t('db.wiz.back'),
                  leadingIcon: 'chevron-left',
                  onPressed: _busy ? null : _back,
                ),
              )
            : null,
        children: [
          if (ready) ...[
            if (_existing != null) ...[
              DbStatusChip(
                status: _existing!.status,
                rawStatus: _existing!.rawStatus,
              ),
              const SizedBox(height: AQSpacing.x3),
            ],
            _header(f, canSaveDraft),
            const SizedBox(height: AQSpacing.x5),
            if (_failure != null) ...[
              DbErrorCard(
                error: _failure,
                onRetry: _busy ? null : () => _save(submit: last),
              ),
              const SizedBox(height: AQSpacing.x4),
            ],
            if (_errors.isNotEmpty && last) ...[
              AQErrorBanner(text: f.t('db.wiz.fix')),
              const SizedBox(height: AQSpacing.x4),
            ],
          ],
          body,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final f = FlowStrings.of(context);
    return DbGuard(
      developerOnly: true,
      inShell: false,
      title: f.t(_isEdit ? 'db.wiz.edit' : 'db.wiz.new'),
      backFallback: '/app/account/workspace/projects',
      builder: (context, a) {
        if (_isEdit && !_loaded) {
          final async = ref.watch(dbMyProjectProvider(widget.projectId!));
          return async.when(
            loading: () => _scaffold(
              f,
              ready: false,
              body: const DbSkeletonList(count: 2, height: 140),
            ),
            error: (e, _) => _scaffold(
              f,
              ready: false,
              body: DbErrorCard(
                error: e,
                onRetry: () =>
                    ref.invalidate(dbMyProjectProvider(widget.projectId!)),
              ),
            ),
            data: (p) {
              if (!p.status.canEdit) {
                return _scaffold(
                  f,
                  ready: false,
                  body: Column(
                    children: [
                      DbStatusChip(status: p.status, rawStatus: p.rawStatus),
                      const SizedBox(height: AQSpacing.x3),
                      DbNotice(f.t('db.proj.noEdit'), icon: 'lock'),
                    ],
                  ),
                );
              }
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && !_loaded) setState(() => _load(p));
              });
              return _scaffold(
                f,
                ready: false,
                body: const DbSkeletonList(count: 2, height: 140),
              );
            },
          );
        }
        final body = AnimatedSwitcher(
          duration: AQMotion.scaled(context, AQMotion.standard),
          switchInCurve: AQMotion.standardCurve,
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween(
                begin: const Offset(0.04, 0),
                end: Offset.zero,
              ).animate(anim),
              child: child,
            ),
          ),
          child: KeyedSubtree(
            key: ValueKey(_step),
            child: switch (_step) {
              0 => _stepBasic(f),
              1 => _stepDetails(f),
              2 => _stepMedia(f),
              3 => _stepLocation(f),
              _ => _stepReview(f),
            },
          ),
        );
        return _scaffold(f, body: body);
      },
    );
  }
}
