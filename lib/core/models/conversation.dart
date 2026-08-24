import 'package:tht_app/core/utils/json_x.dart';

/// One thread between a parent and a teacher, optionally about a requirement.
///
/// The server names the *other* party for whoever is asking, so nothing here
/// needs to know which side it is on.
class Conversation {
  const Conversation({
    required this.id,
    this.otherName = '',
    this.otherId,
    this.jobTitle,
    this.jobId,
    this.lastMessage = '',
    this.lastMessageAt,
    this.unreadCount = 0,
  });

  final int id;

  /// Whoever is on the far end, from the reader's point of view.
  final String otherName;

  final int? otherId;

  /// The student this thread is about, when it is tied to a requirement.
  final String? jobTitle;

  final int? jobId;

  /// Truncated to 80 characters server-side — a preview, not the message.
  final String lastMessage;

  final DateTime? lastMessageAt;
  final int unreadCount;

  bool get hasUnread => unreadCount > 0;

  factory Conversation.fromJson(Map<String, dynamic> json) => Conversation(
        id: asInt(json, 'id'),
        otherName: asString(json, 'other_name'),
        otherId: asIntOrNull(json, 'other_id'),
        jobTitle: asStringOrNull(json, 'job_title'),
        jobId: asIntOrNull(json, 'job_id'),
        lastMessage: asString(json, 'last_message'),
        lastMessageAt: asDateOrNull(json, 'last_message_time'),
        unreadCount: asInt(json, 'unread_count'),
      );
}

/// A thread opened up: the other party, and every message in order.
class ConversationThread {
  const ConversationThread({
    required this.id,
    this.otherName = '',
    this.jobTitle,
    this.messages = const [],
  });

  final int id;
  final String otherName;
  final String? jobTitle;

  /// Oldest first, as the server sends them.
  final List<Message> messages;

  factory ConversationThread.fromJson(Map<String, dynamic> json) =>
      ConversationThread(
        id: asInt(json, 'conversation_id'),
        otherName: asString(json, 'other_name'),
        jobTitle: asStringOrNull(json, 'job_title'),
        messages: asMapList(json, 'messages').map(Message.fromJson).toList(),
      );
}

class Message {
  const Message({
    required this.id,
    this.senderId,
    this.text = '',
    this.isMine = false,
    this.isRead = false,
    this.createdAt,
  });

  final int id;
  final int? senderId;
  final String text;

  /// Decided server-side against the requesting user, so the bubble side never
  /// depends on the app knowing its own user id.
  final bool isMine;

  final bool isRead;
  final DateTime? createdAt;

  factory Message.fromJson(Map<String, dynamic> json) => Message(
        id: asInt(json, 'id'),
        senderId: asIntOrNull(json, 'sender_id'),
        text: asString(json, 'text'),
        isMine: asBool(json, 'is_mine'),
        isRead: asBool(json, 'is_read'),
        createdAt: asDateOrNull(json, 'created_at'),
      );
}
