import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/booking.dart';
import '../models/enums.dart';
import '../models/money.dart';
import '../models/saved.dart';

/// Session-scoped app state — in-memory only (no backend yet). Actions taken
/// in one screen (save, book, offer) show up in another (Saved, My Home,
/// My Enquiries) within the same session.

final savedPropertyIdsProvider = StateProvider<Set<String>>((ref) => {});

final savedSearchesProvider = StateProvider<List<SavedSearch>>((ref) => []);
final recentSearchesProvider = StateProvider<List<String>>((ref) => ['3 Bedroom Villas', 'Muscat', 'Interior Design', 'Al Mouj']);

class PropertyOffer {
  final String id;
  final String propertyId;
  final String propertyTitle;
  final Money offerPrice;
  final QuoteStatus status;
  final Money? counterPrice;
  final DateTime createdAt;

  const PropertyOffer({
    required this.id,
    required this.propertyId,
    required this.propertyTitle,
    required this.offerPrice,
    required this.status,
    this.counterPrice,
    required this.createdAt,
  });

  PropertyOffer copyWith({QuoteStatus? status, Money? counterPrice}) => PropertyOffer(
        id: id,
        propertyId: propertyId,
        propertyTitle: propertyTitle,
        offerPrice: offerPrice,
        status: status ?? this.status,
        counterPrice: counterPrice ?? this.counterPrice,
        createdAt: createdAt,
      );
}

class SentEnquiry {
  final String id;
  final String propertyTitle;
  final String message;
  final DateTime sentAt;
  final bool replied;

  const SentEnquiry({
    required this.id,
    required this.propertyTitle,
    required this.message,
    required this.sentAt,
    this.replied = false,
  });
}

final enquiriesProvider = StateProvider<List<SentEnquiry>>((ref) => []);
final offersProvider = StateProvider<List<PropertyOffer>>((ref) => []);
final bookingsProvider = StateProvider<List<Booking>>((ref) => []);
