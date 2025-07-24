

class Conversation {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime lastMessageAt;
  final List<ChatMessage> messages;

  Conversation({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.lastMessageAt,
    required this.messages,
  });

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'lastMessageAt': lastMessageAt.millisecondsSinceEpoch,
      'messages': messages.map((msg) => msg.toJson()).toList(),
    };
  }

  // Create from JSON
  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'],
      title: json['title'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt']),
      lastMessageAt: DateTime.fromMillisecondsSinceEpoch(json['lastMessageAt']),
      messages: (json['messages'] as List)
          .map((msgJson) => ChatMessage.fromJson(msgJson))
          .toList(),
    );
  }

  // Create a copy with updated messages
  Conversation copyWith({
    String? id,
    String? title,
    DateTime? createdAt,
    DateTime? lastMessageAt,
    List<ChatMessage>? messages,
  }) {
    return Conversation(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      messages: messages ?? this.messages,
    );
  }

  // Generate title from first user message
  static String generateTitle(List<ChatMessage> messages) {
    final firstUserMessage = messages
        .where((msg) => msg.isUser)
        .firstOrNull;
    
    if (firstUserMessage != null) {
      String title = firstUserMessage.text;
      if (title.length > 30) {
        title = title.substring(0, 30) + '...';
      }
      return title;
    }
    
    return 'Cuộc trò chuyện mới';
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String? eventType;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.eventType,
  });

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'isUser': isUser,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'eventType': eventType,
    };
  }

  // Create from JSON
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      text: json['text'],
      isUser: json['isUser'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
      eventType: json['eventType'],
    );
  }
} 