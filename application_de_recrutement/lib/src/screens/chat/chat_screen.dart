import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/auth_state.dart';
import '../../core/app_settings.dart';
import '../../core/translations.dart';
import '../../services/chat_service.dart';
import '../../models/chat_message.dart';
import '../../models/user.dart';
import 'dart:async';

/// Groups messages by day and returns list of (date header string?, message?).
List<dynamic> _groupMessagesByDay(List<ChatMessage> messages) {
  final result = <dynamic>[];
  DateTime? lastDate;
  for (final msg in messages) {
    final d = DateTime(msg.timestamp.year, msg.timestamp.month, msg.timestamp.day);
    if (lastDate == null || d != lastDate) {
      lastDate = d;
      result.add(d);
    }
    result.add(msg);
  }
  return result;
}

String _formatDateHeader(DateTime d, AppLanguage lang) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));
  final date = DateTime(d.year, d.month, d.day);
  if (date == today) return lang.tr('today');
  if (date == yesterday) return lang.tr('yesterday');
  return '${d.day}/${d.month}/${d.year}';
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.otherUser, this.conversationId});

  final AppUser otherUser;
  final String? conversationId;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  Timer? _timer;
  String? _loadedConversationId;

  @override
  void initState() {
    super.initState();
    _loadedConversationId = widget.conversationId;
    _loadMessages();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _loadMessages(silent: true));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages({bool silent = false}) async {
    try {
      final auth = context.read<AuthState>();
      final service = ChatService(auth);
      
      String? targetConversationId = _loadedConversationId;

      // If we don't have an ID yet, try to fetch it
      if (targetConversationId == null) {
          print('ChatScreen: No conversation ID, fetching for user ${widget.otherUser.id}');
          try {
            final conversation = await service.getConversationWithUser(widget.otherUser.id);
            if (conversation != null) {
                print('ChatScreen: Found existing conversation ${conversation.id}');
                targetConversationId = conversation.id;
                _loadedConversationId = conversation.id; // Cache it
            } else {
                print('ChatScreen: No existing conversation found with user ${widget.otherUser.id}');
            }
          } catch (e) {
            print('ChatScreen: Error fetching conversation with user: $e');
          }
      }
      
      if (targetConversationId != null) {
        final messages = await service.getMessages(targetConversationId);
        if (mounted) {
          setState(() {
            _messages = messages;
            if (!silent) _isLoading = false;
          });
          if (!silent) _scrollToBottom();
        }
      } else {
        if (mounted && !silent) {
          setState(() {
            _messages = [];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted && !silent) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    _messageController.clear();
    
    // Add optimistic message
    final auth = context.read<AuthState>();
    final tempMessage = ChatMessage(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        sender: auth.userId!,
        receiver: widget.otherUser.id,
        content: content,
        timestamp: DateTime.now(),
        conversationId: _loadedConversationId ?? 'temp',
    );
    
    setState(() {
        _messages.add(tempMessage);
    });
    _scrollToBottom();

    print('ChatScreen: Attempting to send message to ${widget.otherUser.id}');
    try {
      final service = ChatService(auth);
      final sentMessage = await service.sendMessage(widget.otherUser.id, content);
      
      print('ChatScreen: Message sent successfully');
      
      // If we didn't have a conversation ID before, we do now
      if (_loadedConversationId == null) {
          setState(() {
              _loadedConversationId = sentMessage.conversationId;
          });
          print('ChatScreen: Set new conversation ID: $_loadedConversationId');
      }

      // Replace temp message or refresh
      // For simplicity, we just reload silently which matches original behavior
      // but ideally we'd replace the temp message in the list
      _loadMessages(silent: true);
      
    } catch (e) {
       print('ChatScreen: Error sending message: $e');
       setState(() {
           _messages.removeWhere((m) => m.id == tempMessage.id);
       });
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthState>();
    final lang = context.watch<AppSettings>().language;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : null,
      appBar: AppBar(
        title: Text(widget.otherUser.name),
        backgroundColor: isDark ? const Color(0xFF0F172A) : null,
        elevation: 1,
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Builder(
                    builder: (context) {
                      final grouped = _groupMessagesByDay(_messages);
                      return ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: grouped.length,
                        itemBuilder: (context, index) {
                          final item = grouped[index];
                          if (item is DateTime) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.white12 : Colors.grey[300],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    _formatDateHeader(item, lang),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? Colors.white70 : Colors.grey[700],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }
                          final msg = item as ChatMessage;
                          final isMe = msg.sender == auth.userId;
                          return Align(
                            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: isMe ? Colors.blueAccent : (isDark ? const Color(0xFF1E293B) : Colors.grey[200]),
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(12),
                                  topRight: const Radius.circular(12),
                                  bottomLeft: isMe ? const Radius.circular(12) : Radius.zero,
                                  bottomRight: isMe ? Radius.zero : const Radius.circular(12),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    msg.content,
                                    style: TextStyle(
                                      color: isMe ? Colors.white : (isDark ? Colors.white : Colors.black87),
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (msg.isRead && isMe)
                                        Padding(
                                          padding: const EdgeInsets.only(right: 4),
                                          child: Icon(Icons.done_all, size: 14, color: Colors.white70),
                                        ),
                                      Text(
                                        '${msg.timestamp.hour}:${msg.timestamp.minute.toString().padLeft(2, '0')}',
                                        style: TextStyle(
                                          color: isMe ? Colors.white70 : Colors.grey,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: lang.tr('write_message') ?? 'Écrire un message...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                      fillColor: isDark ? const Color(0xFF0F172A) : Colors.grey[100],
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    style: TextStyle(color: isDark ? Colors.white : Colors.black),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Colors.blueAccent,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
