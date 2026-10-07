import 'package:flutter/foundation.dart';

/// Viewing lifecycle exactly as the product architecture defines it.
/// "Reschedule" is not a lifecycle state: it is a host offer layered on a
/// requested / confirmed viewing (see [Viewing.rescheduleOffered]).
enum ViewingStatus { requested, confirmed, declined, cancelled, completed }

enum SlotState { available, limited, unavailable }

/// How much of a day is bookable, as reported by the availability model.
enum DayLoad { open, limited, none }

enum ViewingPeriod { morning, afternoon, evening }

/// A host-local wall-clock window. [start] carries no time zone: the zone
/// belongs to the [ViewingAvailability] that produced it.
@immutable
class ViewingSlot {
  final DateTime start;
  final int minutes;
  const ViewingSlot(this.start, {this.minutes = 30});

  DateTime get end => start.add(Duration(minutes: minutes));
  DateTime get day => DateTime(start.year, start.month, start.day);
  ViewingPeriod get period => start.hour < 12
      ? ViewingPeriod.morning
      : start.hour < 17
          ? ViewingPeriod.afternoon
          : ViewingPeriod.evening;

  @override
  bool operator ==(Object other) => other is ViewingSlot && other.start == start && other.minutes == minutes;
  @override
  int get hashCode => Object.hash(start, minutes);
}

@immutable
class SlotInfo {
  final ViewingSlot slot;
  final SlotState state;
  const SlotInfo(this.slot, this.state);
  bool get bookable => state != SlotState.unavailable;
}

@immutable
class AvailabilityDay {
  final DateTime date;
  final DayLoad load;
  final List<SlotInfo> slots;
  const AvailabilityDay(this.date, this.load, this.slots);

  int get freeCount => slots.where((s) => s.bookable).length;
  bool get bookable => load != DayLoad.none && freeCount > 0;
  List<SlotInfo> inPeriod(ViewingPeriod p) => slots.where((s) => s.slot.period == p).toList();
}

@immutable
class ViewingAvailability {
  /// Host-local offset from UTC, supplied by the model (never assumed).
  final int utcOffsetMinutes;
  final String zoneCity;
  final List<AvailabilityDay> days;
  const ViewingAvailability({required this.utcOffsetMinutes, required this.zoneCity, required this.days});

  String get zoneLabel {
    final sign = utcOffsetMinutes < 0 ? '-' : '+';
    final abs = utcOffsetMinutes.abs();
    final h = abs ~/ 60;
    final m = abs % 60;
    return 'GMT$sign$h${m == 0 ? '' : ':${m.toString().padLeft(2, '0')}'}';
  }

  AvailabilityDay? dayOf(DateTime d) {
    for (final x in days) {
      if (x.date.year == d.year && x.date.month == d.month && x.date.day == d.day) return x;
    }
    return null;
  }

  /// The day a picker should open on: the first fully open day, else the first with any slot.
  AvailabilityDay? get firstBookable {
    for (final x in days) {
      if (x.bookable && x.load == DayLoad.open) return x;
    }
    for (final x in days) {
      if (x.bookable) return x;
    }
    return null;
  }
}

@immutable
class ViewingHost {
  final String id;
  final String name;
  final String agency;
  final bool verified;
  final double? rating;
  final int? reviewCount;
  const ViewingHost({required this.id, required this.name, required this.agency, this.verified = false, this.rating, this.reviewCount});

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}

@immutable
class Viewing {
  final String id;
  final String propertyId;
  final ViewingHost host;
  final ViewingSlot slot;
  final ViewingStatus status;
  final DateTime createdAt;
  /// Host-offered alternatives (empty unless the host proposed new times).
  final List<ViewingSlot> suggestions;
  /// Only set when the host supplied one. Never invented.
  final String? declineReason;
  final bool cancelledByHost;
  final bool reviewed;

  const Viewing({
    required this.id,
    required this.propertyId,
    required this.host,
    required this.slot,
    required this.status,
    required this.createdAt,
    this.suggestions = const [],
    this.declineReason,
    this.cancelledByHost = false,
    this.reviewed = false,
  });

  bool get rescheduleOffered => suggestions.isNotEmpty && (status == ViewingStatus.requested || status == ViewingStatus.confirmed);
  bool get isActive => status == ViewingStatus.requested || status == ViewingStatus.confirmed;
  bool get reviewEligible => status == ViewingStatus.completed && !reviewed;

  Viewing copyWith({ViewingSlot? slot, ViewingStatus? status, List<ViewingSlot>? suggestions, String? declineReason, bool? cancelledByHost, bool? reviewed}) => Viewing(
        id: id,
        propertyId: propertyId,
        host: host,
        slot: slot ?? this.slot,
        status: status ?? this.status,
        createdAt: createdAt,
        suggestions: suggestions ?? this.suggestions,
        declineReason: declineReason ?? this.declineReason,
        cancelledByHost: cancelledByHost ?? this.cancelledByHost,
        reviewed: reviewed ?? this.reviewed,
      );
}

/// The chosen slot was taken between selection and request.
class SlotTakenException implements Exception {
  const SlotTakenException();
}

/// Any other failure of a viewing call. UI maps it to calm copy; never shown raw.
class ViewingFailure implements Exception {
  final bool network;
  const ViewingFailure({this.network = false});
}
