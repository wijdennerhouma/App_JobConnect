import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/auth_state.dart';
import '../core/api_config.dart';
import 'api_client.dart';
import '../models/chat_message.dart';
import '../models/conversation.dart';

class ChatService {
  ChatService(this.auth);

  final AuthState auth;

  ApiClient get _client => ApiClient(ApiConfig.baseUrl, token: auth.token);

  Future<ChatMessage> sendMessage(String receiverId, String content) async {
    print('ChatService: sendMessage called. Receiver: $receiverId, Content: $content');
    try {
      final res = await _client.post('/chat/send', {
        'receiverId': receiverId,
        'content': content,
      });
      print('ChatService: sendMessage response status: ${res.statusCode}');
      
      if (res.statusCode == 201) {
          final data = jsonDecode(res.body);
          return ChatMessage.fromJson(data);
      } else {
        throw Exception('Impossible d\'envoyer le message (${res.statusCode})');
      }
    } catch (e) {
      print('ChatService: sendMessage error: $e');
      rethrow;
    }
  }

  Future<List<Conversation>> getConversations() async {
    final res = await _client.get('/chat/conversations');
    if (res.statusCode == 200) {
      final List<dynamic> data = jsonDecode(res.body);
      return data.map((json) => Conversation.fromJson(json)).toList();
    }
    throw Exception('Impossible de charger les conversations');
  }

  Future<List<ChatMessage>> getMessages(String conversationId) async {
    final res = await _client.get('/chat/messages/$conversationId');
    if (res.statusCode == 200) {
      final List<dynamic> data = jsonDecode(res.body);
      return data.map((json) => ChatMessage.fromJson(json)).toList();
    }
    throw Exception('Impossible de charger les messages');
  }

  Future<Conversation?> getConversationWithUser(String otherUserId) async {
    try {
      print('ChatService: getConversationWithUser calling /chat/conversation/user/$otherUserId');
      final res = await _client.get('/chat/conversation/user/$otherUserId');
      print('ChatService: getConversationWithUser status ${res.statusCode}');
      if (res.statusCode == 200) {
        print('ChatService: getConversationWithUser body: ${res.body}');
        if (res.body.isEmpty) return null;
        final data = jsonDecode(res.body);
        return Conversation.fromJson(data);
      }
      return null;
    } catch (e) {
      print('ChatService: getConversationWithUser error: $e');
      return null;
    }
  }
  Future<Conversation?> getById(String conversationId) async {
    // Fetch all since backend might not expose single fetch
    final conversations = await getConversations();
    try {
      return conversations.firstWhere((c) => c.id == conversationId);
    } catch (_) {
      return null;
    }
  }
}
