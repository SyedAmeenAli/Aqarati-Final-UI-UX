import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/aq/aq_forms.dart';
import '../../core/aq/aq_primitives.dart';
import '../../core/aq/aq_tokens.dart';
import '../../core/localization/flow_strings.dart';
import '../../data/models/enums.dart';
import '../../data/models/money.dart';
import '../../data/models/property.dart';
import '../../data/repositories/app_state_providers.dart';
import '../viewing/widgets/viewing_components.dart';
import '../viewing/widgets/viewing_format.dart';
import '../viewing/widgets/viewing_scaffold.dart';
import 'enquiry_screen.dart' show EnquirySavedPage;

/// Make an offer on a listing. Like enquiries, offers are only kept on this device: there is no
/// offer service, and the result page says so.
class MakeOfferScreen extends ConsumerStatefulWidget {
  final Property property;
  const MakeOfferScreen({super.key, required this.property});

  @override
  ConsumerState<MakeOfferScreen> createState() => _MakeOfferScreenState();
}

class _MakeOfferScreenState extends ConsumerState<MakeOfferScreen> {
  final _price = TextEditingController();
  bool _agreed = false;
  bool _tried = false;
  double? _savedAmount;

  @override
  void dispose() {
    _price.dispose();
    super.dispose();
  }

  double? get _amount {
    final v = double.tryParse(_price.text.replaceAll(',', '').trim());
    return v != null && v > 0 ? v : null;
  }

  void _submit() {
    setState(() => _tried = true);
    final amount = _amount;
    if (amount == null || !_agreed) return;
    ref
        .read(offersProvider.notifier)
        .update(
          (state) => [
            ...state,
            PropertyOffer(
              id: DateTime.now().microsecondsSinceEpoch.toString(),
              propertyId: widget.property.id,
              propertyTitle: widget.property.title,
              offerPrice: Money(amount),
              status: QuoteStatus.pending,
              createdAt: DateTime.now(),
            ),
          ],
        );
    setState(() => _savedAmount = amount);
  }

  @override
  Widget build(BuildContext context) {
    final f = FlowStrings.of(context);
    final saved = _savedAmount;
    if (saved != null) {
      return EnquirySavedPage(
        property: widget.property,
        titleKey: 'off.done.title',
        subKey: 'off.done.sub',
        warnKey: 'off.done.warn',
        args: {
          'amount': Money(saved).formatted,
          'p': VFmt.iso(widget.property.title),
        },
      );
    }
    return AQViewingScaffold(
      title: f.t('off.title'),
      subtitle: f.t('off.sub', {'price': widget.property.priceLabel}),
      backLabel: f.t('common.back'),
      onBack: () => Navigator.of(context).maybePop(),
      bottom: AQBottomActionBar(
        footnote: f.t('off.note'),
        primary: AQPrimaryButton(
          label: f.t('off.save'),
          trailingChevron: false,
          onPressed: _submit,
        ),
      ),
      children: [
        AQViewingPropertySummary(
          property: widget.property,
          density: AQViewingDensity.compact,
        ),
        const SizedBox(height: AQSpacing.x5),
        AQTextField(
          label: f.t('off.field'),
          controller: _price,
          keyboardType: const TextInputType.numberWithOptions(decimal: false),
          formatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9,]')),
            LengthLimitingTextInputFormatter(12),
          ],
          prefix: const Text('OMR'),
          error: _tried && _amount == null ? f.t('off.err') : null,
          valid: _amount != null,
          action: TextInputAction.done,
          onChanged: (_) => setState(() {}),
        ),
        AQCheckRow(
          value: _agreed,
          label: f.t('off.ack'),
          error: _tried && !_agreed ? f.t('off.ack.err') : null,
          onChanged: (v) => setState(() => _agreed = v),
        ),
      ],
    );
  }
}
