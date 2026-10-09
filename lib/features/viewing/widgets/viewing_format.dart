import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../domain/viewing_models.dart';

/// Locale-aware date and time text for the viewing flow. Nothing is hand-assembled
/// and no zone label is hard-coded: the zone comes from the availability model.
class VFmt {
  VFmt._();
  static String _l(BuildContext c) => Localizations.localeOf(c).languageCode;

  /// Wraps data text (names, titles) in a first-strong isolate so mixed-script strings such as
  /// "4-Bedroom Villa" keep their own order inside an Arabic line instead of reshuffling.
  static String iso(String s) => '\u2068$s\u2069';

  static String weekdayShort(BuildContext c, DateTime d) => DateFormat.E(_l(c)).format(d);
  static String weekdayLong(BuildContext c, DateTime d) => DateFormat.EEEE(_l(c)).format(d);
  static String dayNum(BuildContext c, DateTime d) => DateFormat.d(_l(c)).format(d);
  static String monthShort(BuildContext c, DateTime d) => DateFormat.MMM(_l(c)).format(d);
  static String monthYear(BuildContext c, DateTime d) => DateFormat.yMMMM(_l(c)).format(d);
  static String fullDate(BuildContext c, DateTime d) => DateFormat('EEEE, d MMMM y', _l(c)).format(d);
  static String shortDate(BuildContext c, DateTime d) => DateFormat('EEE d MMM', _l(c)).format(d);
  /// ICU puts a narrow no-break space before AM/PM that renders glued; use a plain space.
  static String time(BuildContext c, DateTime d) => DateFormat.jm(_l(c)).format(d).replaceAll(' ', ' ').replaceAll(' ', ' ');
  static String hour(BuildContext c, DateTime d) => DateFormat.j(_l(c)).format(d).replaceAll('\u202f', ' ').replaceAll('\u00a0', ' ');
  static String range(BuildContext c, ViewingSlot s) => '${time(c, s.start)} – ${time(c, s.end)}';
  static String dateTime(BuildContext c, ViewingSlot s) => '${shortDate(c, s.start)} · ${time(c, s.start)}';
  static String n(BuildContext c, int v) => NumberFormat.decimalPattern(_l(c)).format(v);
  /// Decimal number with up to [digits] fraction digits, in the reader's numerals.
  static String dec(BuildContext c, double v, {int digits = 2}) => (NumberFormat.decimalPattern(_l(c))..maximumFractionDigits = digits).format(v);
}

bool aqLargeText(BuildContext c) => MediaQuery.textScalerOf(c).scale(14) > 18.5;

/// Short phones (SE-class) and large text both need the pinned bar to stay slim.
bool aqDenseBar(BuildContext c) => aqLargeText(c) || MediaQuery.sizeOf(c).height < 700;
