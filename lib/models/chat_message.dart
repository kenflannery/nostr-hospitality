/// Represents a direct private message in a conversation.
class ChatMessage {
  final String id;
  final String senderPubkey;
  final String recipientPubkey;
  final String content;
  final DateTime createdAt;
  final bool isMine;

  const ChatMessage({
    required this.id,
    required this.senderPubkey,
    required this.recipientPubkey,
    required this.content,
    required this.createdAt,
    required this.isMine,
  });

  ChatMessage copyWith({
    String? id,
    String? senderPubkey,
    String? recipientPubkey,
    String? content,
    DateTime? createdAt,
    bool? isMine,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      senderPubkey: senderPubkey ?? this.senderPubkey,
      recipientPubkey: recipientPubkey ?? this.recipientPubkey,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      isMine: isMine ?? this.isMine,
    );
  }
}

/// Represents a conversation preview with another user.
class ConversationSummary {
  final String otherPubkey;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;

  const ConversationSummary({
    required this.otherPubkey,
    required this.lastMessage,
    required this.lastMessageTime,
    this.unreadCount = 0,
  });
}
