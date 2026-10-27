import 'package:flutter/material.dart';

import '../../features/viewing/domain/viewing_presentation.dart' show AQTone;
import '../../features/viewing/widgets/viewing_components.dart'
    show aqToneColors;
import 'aq_primitives.dart';
import 'aq_tokens.dart';
import 'aq_typography.dart';

/// One status pill for every record type (listings, leads, requests, moderation). Same shape and
/// weight as the viewing and project status chips: icon plus text, never colour alone.
class AQStatusPill extends StatelessWidget {
  final String label;
  final AQTone tone;
  final String icon;
  final bool dense;
  const AQStatusPill({
    super.key,
    required this.label,
    required this.tone,
    this.icon = 'info',
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = AQColors.of(context);
    final (fg, bg) = aqToneColors(c, tone);
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: EdgeInsetsDirectional.fromSTEB(
            dense ? 8 : 10,
            dense ? 4 : 6,
            dense ? 10 : 12,
            dense ? 4 : 6,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AQIcon(icon, size: dense ? 14 : 16, color: fg),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: AQTypography.of(
                    context,
                    dense ? AQText.labelSmall : AQText.labelMedium,
                    color: fg,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
