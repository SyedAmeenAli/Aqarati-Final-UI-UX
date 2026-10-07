import 'enquiry.dart';

class Message {
  final String id;
  final String conversationId;
  final String senderId;
  final String text;
  final DateTime sentAt;
  final bool isMine;

  const Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.text,
    required this.sentAt,
    required this.isMine,
  });
}

/// A conversation is always contextual — tied to a property, project,
/// service, enquiry, quote, booking or payment. Never a bare DM.
class Conversation {
  final String id;
  final String counterpartName;
  final String? counterpartAvatarUrl;
  final EnquiryTargetType contextType;
  final String contextTitle; // e.g. "4-Bedroom Villa in Al Mouj"
  final String lastMessagePreview;
  final DateTime lastMessageAt;
  final bool unread;

  const Conversation({
    required this.id,
    required this.counterpartName,
    this.counterpartAvatarUrl,
    required this.contextType,
    required this.contextTitle,
    required this.lastMessagePreview,
    required this.lastMessageAt,
    this.unread = false,
  });
}
