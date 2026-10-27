import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/aq/aq_demo.dart';
import '../../core/aq/aq_forms.dart';
import '../../core/aq/aq_primitives.dart';
import '../../core/aq/aq_scene.dart';
import '../../core/aq/aq_tokens.dart';
import '../../core/aq/aq_typography.dart';
import '../../core/config/backend_mode.dart';
import '../../core/config/qa_faults.dart';
import '../../core/localization/flow_strings.dart';
import '../../data/api/account_api.dart'
    show ApiErrorCode, ApiException, meProvider;
import '../devbuild/db_widgets.dart' show DbErrorCard, DbNotice;
import '../viewing/screens/viewing_kit.dart' show AQViewingSkeleton;
import '../viewing/widgets/viewing_components.dart';
import '../viewing/widgets/viewing_scaffold.dart';

/// What the buyer profile holds. Phone and email are the account's identity and are verified by a
/// code or a link, so they are shown but not edited here.
class BuyerProfile {
  final String firstName, lastName;
  const BuyerProfile({this.firstName = '', this.lastName = ''});
  String get fullName => '$firstName $lastName'.trim();
}

abstract class BuyerProfileRepository {
  Future<BuyerProfile> profile();
  Future<BuyerProfile> save(BuyerProfile p);
}

class UnavailableBuyerProfileRepository implements BuyerProfileRepository {
  const UnavailableBuyerProfileRepository();
  Never _no() => throw const ApiException(ApiErrorCode.network);
  @override
  Future<BuyerProfile> profile() async => _no();
  @override
  Future<BuyerProfile> save(BuyerProfile p) async => _no();
}

/// DEMO ONLY: kept in memory, sent nowhere. Starts empty: no name is invented.
class DemoBuyerProfileRepository implements BuyerProfileRepository {
  DemoBuyerProfileRepository({
    this.latency = const Duration(milliseconds: 250),
    BuyerProfile initial = const BuyerProfile(),
  }) : _p = initial;
  final Duration latency;
  BuyerProfile _p;
  Object? debugNextError;

  Future<void> _lag() async {
    if (latency > Duration.zero) await Future<void>.delayed(latency);
    if (qaCallsFail()) throw const ApiException(ApiErrorCode.network);
    final err = debugNextError;
    if (err != null) {
      debugNextError = null;
      throw err;
    }
  }

  @override
  Future<BuyerProfile> profile() async {
    await _lag();
    return _p;
  }

  @override
  Future<BuyerProfile> save(BuyerProfile p) async {
    await _lag();
    return _p = p;
  }
}

final buyerProfileRepositoryProvider = Provider<BuyerProfileRepository>(
  (ref) => kUseDemoBackend
      ? DemoBuyerProfileRepository()
      : const UnavailableBuyerProfileRepository(),
);
final buyerProfileProvider = FutureProvider.autoDispose<BuyerProfile>(
  (ref) => ref.watch(buyerProfileRepositoryProvider).profile(),
);

/// Letters (any script), spaces, hyphens and apostrophes; 1 to 40 characters.
String? nameError(String v, String requiredKey) {
  final t = v.trim();
  if (t.isEmpty) return requiredKey;
  if (t.length > 40 ||
      !RegExp(r"^[\p{L}\p{M} '\-]+$", unicode: true).hasMatch(t)) {
    return 'pf.err.chars';
  }
  return null;
}

class BuyerProfileScreen extends ConsumerStatefulWidget {
  final bool edit;
  const BuyerProfileScreen({super.key, this.edit = false});
  @override
  ConsumerState<BuyerProfileScreen> createState() => _ProfileState();
}

class _ProfileState extends ConsumerState<BuyerProfileScreen> {
  final _first = TextEditingController();
  final _last = TextEditingController();
  bool _loaded = false, _tried = false, _saving = false, _dirty = false;
  String? _failKey;
  late BuyerProfile _orig;

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    super.dispose();
  }

  void _load(BuyerProfile p) {
    if (_loaded) return;
    _loaded = true;
    _orig = p;
    _first.text = p.firstName;
    _last.text = p.lastName;
  }

  String? get _eFirst => nameError(_first.text, 'pf.err.first');
  String? get _eLast => nameError(_last.text, 'pf.err.last');

  Future<void> _save() async {
    setState(() => _tried = true);
    if (_eFirst != null || _eLast != null || _saving) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _saving = true;
      _failKey = null;
    });
    try {
      await ref
          .read(buyerProfileRepositoryProvider)
          .save(
            BuyerProfile(
              firstName: _first.text.trim(),
              lastName: _last.text.trim(),
            ),
          );
      ref.invalidate(buyerProfileProvider);
      _dirty = false;
      if (mounted) context.go('/app/account/profile?saved=1');
    } catch (_) {
      if (mounted) setState(() => _failKey = 'pf.fail');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _leave() async {
    if (!_dirty) {
      context.go('/app/account/profile');
      return;
    }
    final f = FlowStrings.of(context);
    final yes = await showAQSheet<bool>(
      context,
      useRootNavigator: true,
      builder: (s) => Padding(
        padding: const EdgeInsets.fromLTRB(
          AQSpacing.gutter,
          AQSpacing.x2,
          AQSpacing.gutter,
          AQSpacing.x4,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(
                f.t('pf.leave.t'),
                style: AQTypography.of(s, AQText.headlineSmall),
              ),
            ),
            const SizedBox(height: AQSpacing.x2),
            Text(
              f.t('pf.leave.b'),
              style: AQTypography.of(s, AQText.bodyMedium, soft: true),
            ),
            const SizedBox(height: AQSpacing.x4),
            AQPrimaryButton(
              label: f.t('pf.leave.stay'),
              trailingChevron: false,
              onPressed: () => Navigator.of(s).pop(false),
            ),
            const SizedBox(height: AQSpacing.x2),
            AQSecondaryButton(
              label: f.t('pf.leave.yes'),
              trailingChevron: false,
              onPressed: () => Navigator.of(s).pop(true),
            ),
          ],
        ),
      ),
    );
    if (yes == true && mounted) context.go('/app/account/profile');
  }

  @override
  Widget build(BuildContext context) {
    final f = FlowStrings.of(context);
    final me = ref.watch(meProvider);
    void back() => aqBack(context, '/app/account');
    if (me.isLoading && !me.hasValue) {
      return AQViewingScaffold(
        title: f.t('pf.title'),
        backLabel: f.t('common.back'),
        onBack: back,
        children: const [AQViewingSkeleton(height: 96)],
      );
    }
    if (!me.hasValue) {
      return AQViewingScaffold(
        title: f.t('pf.title'),
        backLabel: f.t('common.back'),
        onBack: back,
        bottom: AQBottomActionBar(
          primary: AQPrimaryButton(
            label: f.t('pf.signin.cta'),
            trailingChevron: false,
            onPressed: () => context.push('/login'),
          ),
        ),
        children: [
          AQNoticeCard(icon: 'lock', title: f.t('pf.signin.t'), body: ''),
        ],
      );
    }
    return ref
        .watch(buyerProfileProvider)
        .when(
          loading: () => AQViewingScaffold(
            title: f.t('pf.title'),
            backLabel: f.t('common.back'),
            onBack: back,
            children: const [AQViewingSkeleton(height: 96)],
          ),
          error: (e, _) => AQViewingScaffold(
            title: f.t('pf.title'),
            backLabel: f.t('common.back'),
            onBack: back,
            children: [
              DbErrorCard(
                error: e,
                onRetry: () => ref.invalidate(buyerProfileProvider),
              ),
            ],
          ),
          data: (p) {
            _load(p);
            final last4 = me.valueOrNull?.phoneLast4;
            return widget.edit ? _edit(f) : _view(f, p, last4);
          },
        );
  }

  Widget _view(FlowStrings f, BuyerProfile p, String? last4) {
    final saved = GoRouterState.of(context).uri.queryParameters['saved'] == '1';
    Widget row(String k, String v) => Padding(
      padding: const EdgeInsets.symmetric(vertical: AQSpacing.x2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              k,
              style: AQTypography.of(context, AQText.bodySmall, soft: true),
            ),
          ),
          Expanded(
            child: Text(v, style: AQTypography.of(context, AQText.bodyMedium)),
          ),
        ],
      ),
    );
    return AQViewingScaffold(
      title: f.t('pf.title'),
      subtitle: f.t('pf.sub'),
      backLabel: f.t('common.back'),
      onBack: () => aqBack(context, '/app/account'),
      bottom: AQBottomActionBar(
        primary: AQPrimaryButton(
          label: f.t('pf.edit'),
          trailingChevron: false,
          onPressed: () => context.go('/app/account/profile/edit'),
        ),
      ),
      children: [
        if (saved)
          AQErrorBanner(
            tone: AQBannerTone.success,
            text: kUseDemoBackend
                ? '${f.t('pf.saved')}. ${f.t('pf.saved.demo')}'
                : f.t('pf.saved'),
          ),
        AQSurface(
          padding: const EdgeInsets.all(AQSpacing.x4),
          child: Column(
            children: [
              row(
                f.t('pf.name'),
                p.fullName.isEmpty ? f.t('pf.name.none') : p.fullName,
              ),
              if (last4 != null) row(f.t('pf.phone'), '•••• $last4'),
            ],
          ),
        ),
        const SizedBox(height: AQSpacing.x3),
        DbNotice(f.t('pf.phone.note'), icon: 'lock'),
        const SizedBox(height: AQSpacing.x4),
        AQSecondaryButton(
          label: f.t('ce.row'),
          leadingIcon: 'verified',
          trailingChevron: false,
          onPressed: () => context.push('/engagements'),
        ),
        const SizedBox(height: AQSpacing.x2),
        AQSecondaryButton(
          label: f.t('rv.row'),
          leadingIcon: 'star',
          trailingChevron: false,
          onPressed: () => context.push('/reviews'),
        ),
        const SizedBox(height: AQSpacing.x2),
        AQSecondaryButton(
          label: f.t('eb.row'),
          leadingIcon: 'home',
          trailingChevron: false,
          onPressed: () => context.push('/sell'),
        ),
        const SizedBox(height: AQSpacing.x4),
        if (kUseDemoBackend) const AQDemoNotice(),
      ],
    );
  }

  Widget _edit(FlowStrings f) {
    String? txt(String? k) => _tried && k != null ? f.t(k) : null;
    return PopScope(
      canPop: !_dirty || _saving,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) await _leave();
      },
      child: AQViewingScaffold(
        title: f.t('pf.edit.title'),
        backLabel: f.t('pf.cancel'),
        onBack: _leave,
        bottom: AQBottomActionBar(
          primary: AQPrimaryButton(
            label: f.t('pf.save'),
            trailingChevron: false,
            loading: _saving,
            onPressed: _saving ? null : _save,
          ),
          secondary: AQBarSecondaryButton(
            label: f.t('pf.cancel'),
            onPressed: _saving ? null : _leave,
          ),
        ),
        children: [
          if (_failKey != null) AQErrorBanner(text: f.t(_failKey!)),
          AQTextField(
            label: f.t('pf.first'),
            controller: _first,
            error: txt(_eFirst),
            onChanged: (_) => setState(
              () => _dirty =
                  _first.text != _orig.firstName ||
                  _last.text != _orig.lastName,
            ),
          ),
          const SizedBox(height: AQSpacing.x3),
          AQTextField(
            label: f.t('pf.last'),
            controller: _last,
            error: txt(_eLast),
            onChanged: (_) => setState(
              () => _dirty =
                  _first.text != _orig.firstName ||
                  _last.text != _orig.lastName,
            ),
          ),
          const SizedBox(height: AQSpacing.x4),
          if (kUseDemoBackend) const AQDemoNotice(),
        ],
      ),
    );
  }
}
