import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/aq/aq_auth_scaffold.dart';
import '../../core/aq/aq_primitives.dart';
import '../../core/aq/aq_scene.dart';
import '../../core/aq/aq_tokens.dart';
import '../../core/localization/flow_strings.dart';
import '../viewing/widgets/viewing_format.dart' show aqLargeText;

/// What a User to Shop customer says they are looking for. Kept on this device only (prototype);
/// it re-orders the services on Home and sets the Buy / Rent default. The four primary Home
/// actions never depend on it.
enum Interest {
  buy('home'),
  rent('calendar'),
  sell('verified'),
  development('development'),
  architecture('architecture'),
  interior('interior'),
  construction('construction'),
  maintenance('shield'),
  loan('area');

  final String icon;
  const Interest(this.icon);
}

const kInterestsKey = 'aq.interests';

final interestsProvider = StateProvider<Set<Interest>>((_) => <Interest>{});

/// "What are you looking for?" Optional: Skip leaves everything as it was.
class InterestsScreen extends ConsumerStatefulWidget {
  const InterestsScreen({super.key});
  @override
  ConsumerState<InterestsScreen> createState() => _InterestsScreenState();
}

class _InterestsScreenState extends ConsumerState<InterestsScreen> {
  late final Set<Interest> _picked = {...ref.read(interestsProvider)};

  void _toggle(Interest i) {
    AQHaptics.selection();
    setState(() => _picked.contains(i) ? _picked.remove(i) : _picked.add(i));
  }

  void _done({required bool save}) {
    if (save) ref.read(interestsProvider.notifier).state = {..._picked};
    context.go('/app/home');
  }

  @override
  Widget build(BuildContext context) {
    final f = FlowStrings.of(context);
    Widget tile(Interest i) => AQChoiceTile(
      icon: i.icon,
      title: f.t('int.${i.name}'),
      description: f.t('int.${i.name}.s'),
      selected: _picked.contains(i),
      onTap: () => _toggle(i),
    );
    const all = Interest.values;
    final rows = <Widget>[];
    if (aqLargeText(context)) {
      for (final i in all) {
        rows
          ..add(tile(i))
          ..add(const SizedBox(height: AQSpacing.x3));
      }
    } else {
      for (var i = 0; i < all.length; i += 2) {
        rows
          ..add(
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: tile(all[i])),
                  const SizedBox(width: AQSpacing.x3),
                  Expanded(
                    child: i + 1 < all.length
                        ? tile(all[i + 1])
                        : const SizedBox(),
                  ),
                ],
              ),
            ),
          )
          ..add(const SizedBox(height: AQSpacing.x3));
      }
    }
    return AQAuthScaffold(
      showBack: false,
      title: f.t('int.title'),
      subtitle: f.t('int.sub'),
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AQPrimaryButton(
            label: f.t('int.continue'),
            semanticsLabel: _picked.isEmpty
                ? f.t('int.continue')
                : '${f.t('int.continue')} (${_picked.length})',
            onPressed: _picked.isEmpty ? null : () => _done(save: true),
          ),
          AQTextButton(
            label: f.t('int.skip'),
            color: AQColors.of(context).inkSoft,
            onPressed: () => _done(save: false),
          ),
        ],
      ),
      children: rows,
    );
  }
}
