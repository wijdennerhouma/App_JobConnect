import 'user.dart';

class Conversation {
  final String id;
  final List<AppUser> participants;
  final String lastMessage;
  final DateTime lastMessageDate;

  Conversation({
    required this.id,
    required this.participants,
    required this.lastMessage,
    required this.lastMessageDate,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    var list = json['participants'] as List;
    List<AppUser> participantsList = list.map((i) => AppUser.fromJson(i)).toList();

    return Conversation(
      id: json['_id'],
      participants: participantsList,
      lastMessage: json['lastMessage'] ?? '',
      lastMessageDate: DateTime.parse(json['lastMessageDate']),
    );
  }
  
  AppUser? getOtherParticipant(String myUserId) {
    try {
      return participants.firstWhere((u) => u.id != myUserId);
    } catch (e) {
      return null;
    }
  }
}
