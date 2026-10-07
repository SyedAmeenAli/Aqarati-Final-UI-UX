import 'enums.dart';

class BusinessVerification {
  final VerificationStatus status;
  final DateTime? verifiedAt;

  const BusinessVerification({required this.status, this.verifiedAt});

  bool get isVerified => status == VerificationStatus.verified;
}

class Business {
  final String id;
  final String name;
  final List<BusinessCategory> categories;
  final String locationLabel;
  final String description;
  final String? logoUrl;
  final List<String> galleryUrls;
  final BusinessVerification verification;
  final String serviceArea;
  final double? rating;
  final int? reviewCount;

  const Business({
    required this.id,
    required this.name,
    required this.categories,
    required this.locationLabel,
    this.description = '',
    this.logoUrl,
    this.galleryUrls = const [],
    required this.verification,
    this.serviceArea = '',
    this.rating,
    this.reviewCount,
  });
}
