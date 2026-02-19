import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/auth_state.dart';
import '../../core/app_settings.dart';
import '../../core/translations.dart';
import '../../core/api_config.dart';
import '../../services/chat_service.dart';
import '../../models/conversation.dart';
import 'chat_screen.dart';

class ConversationListScreen extends StatefulWidget {
  const ConversationListScreen({super.key});

  @override
  State<ConversationListScreen> createState() => _ConversationListScreenState();
}

class _ConversationListScreenState extends State<ConversationListScreen> {
  Future<List<Conversation>>? _future;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  void _loadConversations() {
    final auth = context.read<AuthState>();
    final service = ChatService(auth);
    setState(() {
      _future = service.getConversations();
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<AppSettings>().language;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = context.read<AuthState>();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : null,
      appBar: AppBar(
        title: Text(lang.tr('messages') ?? 'Messages'),
        backgroundColor: isDark ? const Color(0xFF0F172A) : null,
        elevation: 1,
      ),
      body: FutureBuilder<List<Conversation>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
             // return Center(child: Text('Error: ${snapshot.error}'));
             return Center(child: Text(lang.tr('no_conversations') ?? 'Aucune conversation'));
          }
          
          final conversations = snapshot.data ?? [];
          if (conversations.isEmpty) {
            return Center(child: Text(lang.tr('no_conversations') ?? 'Aucune conversation'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: conversations.length,
            separatorBuilder: (context, index) => isDark ? const Divider(color: Colors.white10) : const Divider(),
            itemBuilder: (context, index) {
              final conversation = conversations[index];
              final otherUser = conversation.getOtherParticipant(auth.userId!);
              
              if (otherUser == null) {
                  return ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person_off)),
                      title: const Text('Utilisateur inconnu'),
                      subtitle: Text(conversation.lastMessage),
                  );
              }

              return ListTile(
                onTap: () async {
                   await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        otherUser: otherUser,
                        conversationId: conversation.id,
                      ),
                    ),
                  );
                  _loadConversations(); // Refresh on return
                },
                leading: CircleAvatar(
                  backgroundImage: otherUser.avatar != null && otherUser.avatar!.isNotEmpty
                      ? NetworkImage('${ApiConfig.baseUrl}/uploads/avatars/${otherUser.avatar}')
                      : null,
                  child: otherUser.avatar == null || otherUser.avatar!.isEmpty
                      ? Text(otherUser.name.isNotEmpty ? otherUser.name[0].toUpperCase() : '?')
                      : null,
                ),
                title: Text(
                  otherUser.name,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  conversation.lastMessage,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: isDark ? const TextStyle(color: Colors.white60) : null,
                ),
                trailing: Text(
                  '${conversation.lastMessageDate.day}/${conversation.lastMessageDate.month}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
