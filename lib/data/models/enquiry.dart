enum EnquiryTargetType { property, project, service }

class Enquiry {
  final String id;
  final EnquiryTargetType targetType;
  final String targetId;
  final String message;
  final DateTime createdAt;

  const Enquiry({
    required this.id,
    required this.targetType,
    required this.targetId,
    required this.message,
    required this.createdAt,
  });
}
