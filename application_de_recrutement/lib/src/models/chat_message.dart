class ChatMessage {
  final String id;
  final String sender;
  final String receiver;
  final String content;
  final DateTime timestamp;
  final String conversationId;
  final bool isRead;

  ChatMessage({
    required this.id,
    required this.sender,
    required this.receiver,
    required this.content,
    required this.timestamp,
    required this.conversationId,
    this.isRead = false,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      sender: json['sender']?.toString() ?? '',
      receiver: json['receiver']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
      conversationId: json['conversationId']?.toString() ?? '',
      isRead: json['isRead'] == true,
    );
  }
}
