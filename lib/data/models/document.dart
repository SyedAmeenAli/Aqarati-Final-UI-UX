import 'enums.dart';

class Document {
  final String id;
  final String title;
  final String? fileUrl;
  final VerificationStatus status;
  final DateTime uploadedAt;

  const Document({
    required this.id,
    required this.title,
    this.fileUrl,
    required this.status,
    required this.uploadedAt,
  });
}
