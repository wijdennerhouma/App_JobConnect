import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/notification_service.dart';
import '../../services/job_service.dart';
import '../../services/application_service.dart';
import '../../services/chat_service.dart';
import '../../models/app_notification.dart';
import '../../models/job.dart';
import '../../models/user.dart';
import '../../models/app_application.dart';
import '../../core/auth_state.dart';
import '../../core/app_settings.dart';
import '../../core/translations.dart';
import '../entreprise/job_applicants_screen.dart';
import '../chat/chat_screen.dart';
import '../employee/widgets/application_details_sheet.dart';

class NotificationListScreen extends StatefulWidget {
  const NotificationListScreen({super.key});

  @override
  State<NotificationListScreen> createState() => _NotificationListScreenState();
}

class _NotificationListScreenState extends State<NotificationListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationService>().fetchNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final notificationService = context.watch<NotificationService>();
    final notifications = notificationService.notifications;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.watch<AppSettings>().language.tr('notifications')),
      ),
      body: notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.notifications_none_rounded,
                      size: 80,
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    context.watch<AppSettings>().language.tr('no_notifications') ?? 'Aucune notification',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.watch<AppSettings>().language.tr('notifications_subtitle') ?? 'Vous êtes à jour !',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return _buildNotificationItem(context, notification);
              },
            ),
    );
  }

  Widget _buildNotificationItem(BuildContext context, AppNotification notification) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Determine color based on type
    final Color typeColor = _getColorForType(notification.type);
    
    final readBgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final unreadBgColor = isDark ? const Color(0xFF0F172A).withOpacity(0.5) : Colors.blue.withOpacity(0.05); // Use darker or tinted for unread in dark mode if desired, or lighter. User asked to distinguish.
    // Actually, usually unread is standout.
    // Let's use a subtle blue tint for unread in dark mode too:
    final unreadDarkBg = const Color(0xFF1E293B).withOpacity(0.8); // slight diff
    // Or just use the same logic as light mode but with dark base.
    
    // User complaint: "en mode sombre je ne veut pas voire blan" -> "In dark mode I don't want to see white".
    // Current code: `color: notification.isRead ? Colors.white : ...` -> This explicitly sets white.
    
    final bgColor = notification.isRead 
        ? (isDark ? const Color(0xFF1E293B) : Colors.white) 
        : (isDark ? const Color(0xFF334155) : Colors.blue.withOpacity(0.05));

    final titleColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final bodyColor = isDark ? Colors.grey[300] : Colors.grey[600];
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: notification.isRead 
              ? (isDark ? Colors.white10 : Colors.grey.withOpacity(0.1)) 
              : typeColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            if (!notification.isRead) {
              context.read<NotificationService>().markAsRead(notification.id);
            }
            _handleNotificationTap(context, notification);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getIconForType(notification.type),
                    color: typeColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              _getNotificationTitle(notification, context.watch<AppSettings>().language),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: notification.isRead ? FontWeight.w600 : FontWeight.bold,
                                color: titleColor,
                              ),
                            ),
                          ),
                          if (!notification.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _getNotificationBody(notification, context.watch<AppSettings>().language),
                        style: TextStyle(
                          fontSize: 14,
                          color: bodyColor,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        DateFormat('dd/MM/yyyy HH:mm').format(notification.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[400],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'application_new':
        return Colors.green;
      case 'application_status':
        return Colors.orange;
      case 'new_message':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'application_new':
        return Icons.work;
      case 'application_status':
        return Icons.info;
      case 'new_message':
        return Icons.chat;
      default:
        return Icons.notifications;
    }
  }

  String _getNotificationTitle(AppNotification notification, AppLanguage lang) {
    if (notification.type == 'new_message') {
      return lang.tr('notification_new_message') ?? notification.title;
    } else if (notification.type == 'application_new') {
      return lang.tr('notification_application_new') ?? notification.title;
    } else if (notification.type == 'application_status') {
      return lang.tr('notification_application_status') ?? notification.title;
    }
    return notification.title;
  }

  String _getNotificationBody(AppNotification notification, AppLanguage lang) {
    // Handle application_new translation
    if (notification.type == 'application_new') {
      // Backend format (FR): "{name} a postulé pour {jobTitle}"
      if (notification.body.contains(' a postulé pour ')) {
        final parts = notification.body.split(' a postulé pour ');
        if (parts.length >= 2) {
          final user = parts[0];
          // Join the rest in case job title has the separator (unlikely but safe)
          final job = parts.sublist(1).join(' a postulé pour ');
          
          final template = lang.tr('user_applied_for_job') ?? '{user} a postulé pour {job}';
          return template
              .replaceAll('{user}', user)
              .replaceAll('{job}', job);
        }
      }
    }

    // Handle specific new message formats to translate them
    if (notification.type == 'new_message') {
      String name = '';
      bool matchFound = false;

      // Check for backend Format 1: "Message from: Name"
      if (notification.body.startsWith('Message from: ')) {
        name = notification.body.substring('Message from: '.length);
        matchFound = true;
      }
      
      // Check for legacy/original backend Format 2: "Vous avez reçu un message de Name"
      else if (notification.body.startsWith('Vous avez reçu un message de ')) {
        name = notification.body.substring('Vous avez reçu un message de '.length);
        matchFound = true;
      }
      
      // Check for legacy backend format 3 (English): "You received a message from Name"
      else if (notification.body.startsWith('You received a message from ')) {
        name = notification.body.substring('You received a message from '.length);
         matchFound = true;
      }

      if (matchFound) {
        // Clean up common bad data patterns like "undefined"
        name = name.replaceAll('undefined', '').trim();
        
        // If name became empty or was just 'to' (common issue observed), provide fallback
        if (name.isEmpty) {
           name = lang.tr('unknown_user') ?? 'Utilisateur';
        }
        
        final prefix = lang.tr('message_from') ?? 'Message de';
        return '$prefix $name';
      }
    }
    
    // Fallback: return as is
    return notification.body;
  }

  void _handleNotificationTap(BuildContext context, AppNotification notification) async {
    await navigateToNotificationTarget(context, notification.type, notification.relatedId);
  }
}

/// Navigation partagée : clic sur une notification (liste ou FCM) → page cible.
Future<void> navigateToNotificationTarget(BuildContext context, String type, String? relatedId) async {
  if (relatedId == null || relatedId.isEmpty) return;
  final nav = Navigator.of(context);
  final auth = context.read<AuthState>();
  final jobService = JobService(auth);
  final appService = ApplicationService(auth);
  final chatService = ChatService(auth);
  final lang = context.read<AppSettings>().language;

  if (type == 'application_new') {
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
    try {
      final app = await appService.getById(relatedId);
      if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
      if (app != null) {
        Job? job = app.job;
        if (job == null && app.jobId.isNotEmpty) job = await jobService.fetchById(app.jobId);
        if (job != null) {
          nav.push(MaterialPageRoute(builder: (_) => JobApplicantsScreen(job: job!)));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(lang.tr('job_not_found') ?? 'Offre introuvable')));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(lang.tr('application_not_found_redirect') ?? 'Candidature introuvable')));
      }
    } catch (e) {
      if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${lang.tr('error_prefix') ?? 'Erreur'}: $e')));
    }
  } else if (type == 'new_message') {
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
    try {
      final conversation = await chatService.getById(relatedId);
      if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
      if (conversation != null && conversation.participants.isNotEmpty) {
        final otherUser = conversation.participants.firstWhere(
            (u) => u.id != auth.userId,
            orElse: () => conversation.participants.first,
        );
        nav.push(MaterialPageRoute(
            builder: (_) => ChatScreen(otherUser: otherUser, conversationId: relatedId),
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(lang.tr('conversation_not_found') ?? 'Conversation introuvable')));
      }
    } catch (e) {
      if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${lang.tr('error_prefix') ?? 'Erreur'}: $e')));
    }
  } else if (type == 'application_status') {
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
    try {
      final app = await appService.getById(relatedId);
      if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
      if (app != null) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          builder: (context) => DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.5,
            maxChildSize: 0.9,
            expand: false,
            builder: (context, scrollController) {
              return ApplicationDetailsSheet(app: app, scrollController: scrollController);
            },
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(lang.tr('application_not_found_redirect') ?? 'Candidature introuvable')));
      }
    } catch (e) {
      if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${lang.tr('error_prefix') ?? 'Erreur'}: $e')));
    }
  }
}
