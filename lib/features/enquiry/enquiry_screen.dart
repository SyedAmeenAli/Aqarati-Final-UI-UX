import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/aq/aq_forms.dart';
import '../../core/aq/aq_primitives.dart';
import '../../core/aq/aq_tokens.dart';
import '../../core/aq/aq_typography.dart';
import '../../core/localization/flow_strings.dart';
import '../../data/models/property.dart';
import '../../data/repositories/app_state_providers.dart';
import '../viewing/domain/viewing_presentation.dart';
import '../viewing/widgets/viewing_components.dart';
import '../viewing/widgets/viewing_format.dart';
import '../viewing/widgets/viewing_scaffold.dart';

final _emailRe = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

/// Enquire about a listing. Nothing is delivered to the owner yet (there is no enquiry service), so
/// the result page says the enquiry is saved on this device and was not delivered.
class EnquiryScreen extends ConsumerStatefulWidget {
  final Property property;
  const EnquiryScreen({super.key, required this.property});

  @override
  ConsumerState<EnquiryScreen> createState() => _EnquiryScreenState();
}

class _EnquiryScreenState extends ConsumerState<EnquiryScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _message = TextEditingController();
  bool _tried = false;
  bool _saved = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _message.dispose();
    super.dispose();
  }

  bool get _nameOk => _name.text.trim().length >= 2;
  bool get _emailOk => _emailRe.hasMatch(_email.text.trim());
  bool get _phoneOk => RegExp(r'^\d{8}$').hasMatch(_phone.text.trim());
  bool get _contactOk => _emailOk || _phoneOk;
  bool get _messageOk => _message.text.trim().length >= 10;

  void _submit() {
    setState(() => _tried = true);
    final emailBad = _email.text.trim().isNotEmpty && !_emailOk;
    final phoneBad = _phone.text.trim().isNotEmpty && !_phoneOk;
    if (!_nameOk || !_contactOk || emailBad || phoneBad || !_messageOk) return;
    ref
        .read(enquiriesProvider.notifier)
        .update(
          (state) => [
            ...state,
            SentEnquiry(
              id: DateTime.now().microsecondsSinceEpoch.toString(),
              propertyTitle: widget.property.title,
              message: _message.text.trim(),
              sentAt: DateTime.now(),
            ),
          ],
        );
    setState(() => _saved = true);
  }

  @override
  Widget build(BuildContext context) {
    final f = FlowStrings.of(context);
    if (_saved)
      return _Saved(
        property: widget.property,
        titleKey: 'enq.done.title',
        subKey: 'enq.done.sub',
        warnKey: 'enq.done.warn',
        args: {'p': VFmt.iso(widget.property.title)},
      );
    final emailText = _email.text.trim();
    final phoneText = _phone.text.trim();
    return AQViewingScaffold(
      title: f.t('enq.title'),
      subtitle: f.t('enq.sub'),
      backLabel: f.t('common.back'),
      onBack: () => Navigator.of(context).maybePop(),
      bottom: AQBottomActionBar(
        footnote: f.t('enq.note'),
        primary: AQPrimaryButton(
          label: f.t('enq.save'),
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
          label: f.t('enq.name'),
          controller: _name,
          autofill: const [AutofillHints.name],
          error: _tried && !_nameOk ? f.t('enq.name.err') : null,
          valid: _nameOk,
          onChanged: (_) => setState(() {}),
        ),
        AQTextField(
          label: f.t('enq.email'),
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          autofill: const [AutofillHints.email],
          error: emailText.isNotEmpty && !_emailOk && _tried
              ? f.t('err.email')
              : null,
          valid: _emailOk,
          onChanged: (_) => setState(() {}),
        ),
        AQTextField(
          label: f.t('enq.phone'),
          controller: _phone,
          keyboardType: TextInputType.phone,
          autofill: const [AutofillHints.telephoneNumber],
          formatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(8),
          ],
          prefix: const Text('+968'),
          error: phoneText.isNotEmpty && !_phoneOk && _tried
              ? f.t('err.phone')
              : null,
          helper: _tried && !_contactOk ? null : f.t('enq.contact.help'),
          valid: _phoneOk,
          onChanged: (_) => setState(() {}),
        ),
        if (_tried && !_contactOk)
          Padding(
            padding: const EdgeInsets.only(bottom: AQSpacing.x4),
            child: Semantics(
              liveRegion: true,
              child: Text(
                f.t('enq.contact.err'),
                style: AQTypography.of(
                  context,
                  AQText.bodySmall,
                  color: AQColors.of(context).danger,
                ),
              ),
            ),
          ),
        AQTextField(
          label: f.t('enq.msg'),
          controller: _message,
          hint: f.t('enq.msg.hint'),
          minLines: 4,
          maxLines: 8,
          action: TextInputAction.newline,
          error: _tried && !_messageOk ? f.t('enq.msg.err') : null,
          valid: _messageOk,
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }
}

/// Result page shared by enquiry and offer: says exactly what happened and what did not.
class _Saved extends StatelessWidget {
  final Property property;
  final String titleKey, subKey, warnKey;
  final Map<String, String> args;
  const _Saved({
    required this.property,
    required this.titleKey,
    required this.subKey,
    required this.warnKey,
    required this.args,
  });

  @override
  Widget build(BuildContext context) {
    final f = FlowStrings.of(context);
    return AQViewingScaffold(
      emotional: true,
      washImage: property.imageUrls.isEmpty ? null : property.imageUrls.first,
      hero: const AQConfirmationState(icon: 'check', tone: AQTone.neutral),
      title: f.t(titleKey),
      subtitle: f.t(subKey, args),
      backLabel: f.t('common.back'),
      onBack: () => Navigator.of(context).pop(),
      bottom: AQBottomActionBar(
        primary: AQPrimaryButton(
          label: f.t('enq.back'),
          trailingChevron: false,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      children: [
        AQNoticeCard(
          icon: 'info',
          tone: AQTone.warning,
          title: f.t(warnKey),
          body: '',
        ),
      ],
    );
  }
}

/// Re-exported for the offer page so both result pages look the same.
class EnquirySavedPage extends StatelessWidget {
  final Property property;
  final String titleKey, subKey, warnKey;
  final Map<String, String> args;
  const EnquirySavedPage({
    super.key,
    required this.property,
    required this.titleKey,
    required this.subKey,
    required this.warnKey,
    this.args = const {},
  });
  @override
  Widget build(BuildContext context) => _Saved(
    property: property,
    titleKey: titleKey,
    subKey: subKey,
    warnKey: warnKey,
    args: args,
  );
}
