import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/auth_state.dart';
import 'notification_list_screen.dart';

/// Écran intermédiaire affiché au clic sur une notification FCM (tray).
/// Lance la navigation vers la page cible puis se retire de la pile.
class NotificationHandlerScreen extends StatefulWidget {
  const NotificationHandlerScreen({
    super.key,
    required this.type,
    required this.relatedId,
  });

  final String type;
  final String relatedId;

  @override
  State<NotificationHandlerScreen> createState() => _NotificationHandlerScreenState();
}

class _NotificationHandlerScreenState extends State<NotificationHandlerScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _navigateAndPop());
  }

  Future<void> _navigateAndPop() async {
    if (!mounted) return;
    final auth = context.read<AuthState>();
    if (auth.userId == null) {
      if (mounted) Navigator.of(context).pop();
      return;
    }
    await navigateToNotificationTarget(context, widget.type, widget.relatedId);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
