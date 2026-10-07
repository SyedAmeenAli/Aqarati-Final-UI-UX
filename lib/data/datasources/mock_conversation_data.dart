import '../models/enquiry.dart';
import '../models/message.dart';

final List<Conversation> mockConversations = [
  Conversation(
    id: 'c1',
    counterpartName: 'Wadi Architecture',
    contextType: EnquiryTargetType.property,
    contextTitle: '4-Bedroom Villa in Al Mouj',
    lastMessagePreview: 'Yes, the viewing is confirmed for Saturday at 4 PM.',
    lastMessageAt: DateTime.now().subtract(const Duration(hours: 3)),
    unread: true,
  ),
  Conversation(
    id: 'c2',
    counterpartName: 'Maysan Design Studio',
    contextType: EnquiryTargetType.service,
    contextTitle: 'Interior Design enquiry',
    lastMessagePreview: "We'd love to help with your living room refresh.",
    lastMessageAt: DateTime.now().subtract(const Duration(days: 1)),
  ),
];

final Map<String, List<Message>> mockMessagesByConversation = {
  'c1': [
    Message(
      id: 'm1',
      conversationId: 'c1',
      senderId: 'b1',
      text: "As-salamu alaykum, thank you for contacting AQARATI. I'd be glad to schedule an exclusive walk-through of the Al Mouj Villa this weekend.",
      sentAt: DateTime.now().subtract(const Duration(hours: 5)),
      isMine: false,
    ),
    Message(
      id: 'm2',
      conversationId: 'c1',
      senderId: 'me',
      text: 'Wa alaykum as-salam. Yes, please. Saturday afternoon around 4 PM would be ideal.',
      sentAt: DateTime.now().subtract(const Duration(hours: 4)),
      isMine: true,
    ),
    Message(
      id: 'm3',
      conversationId: 'c1',
      senderId: 'b1',
      text: 'Yes, the viewing is confirmed for Saturday at 4 PM.',
      sentAt: DateTime.now().subtract(const Duration(hours: 3)),
      isMine: false,
    ),
  ],
  'c2': [
    Message(
      id: 'm4',
      conversationId: 'c2',
      senderId: 'b3',
      text: "We'd love to help with your living room refresh.",
      sentAt: DateTime.now().subtract(const Duration(days: 1)),
      isMine: false,
    ),
  ],
};
