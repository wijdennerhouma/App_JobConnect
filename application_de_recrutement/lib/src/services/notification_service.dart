import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:convert';
import '../models/app_notification.dart';
import '../core/api_config.dart';
import '../core/auth_state.dart';
import '../screens/notifications/notification_handler_screen.dart';

class NotificationService extends ChangeNotifier {
  final AuthState auth;
  final GlobalKey<NavigatorState>? navigatorKey;
  List<AppNotification> _notifications = [];
  int _unreadCount = 0;

  NotificationService(this.auth, [this.navigatorKey]);

  List<AppNotification> get notifications => _notifications;
  int get unreadCount => _unreadCount;

  // Initialize FCM
  Future<void> init() async {
    if (auth.token == null) return;

    final messaging = FirebaseMessaging.instance;
    
    // Request permission
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');

      final token = await messaging.getToken();
      if (token != null) {
        print('FCM Token: $token');
        await _updateServerToken(token);
      }

      // Message reçu en premier plan → rafraîchir la liste
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('Got a message whilst in the foreground!');
        if (message.notification != null) fetchNotifications();
      });

      // Clic sur une notification (app en arrière-plan ou fermée) → aller à la page cible
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
      final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        Future.delayed(const Duration(milliseconds: 500), () => _handleNotificationTap(initialMessage));
      }
    }
  }

  void _handleNotificationTap(RemoteMessage message) {
    final type = message.data['type']?.toString();
    final relatedId = message.data['relatedId']?.toString();
    if (type == null || type.isEmpty || relatedId == null || relatedId.isEmpty) return;
    navigatorKey?.currentState?.push(
      MaterialPageRoute(
        builder: (_) => NotificationHandlerScreen(type: type, relatedId: relatedId),
      ),
    );
  }

  Future<void> _updateServerToken(String token) async {
    try {
      // We need an endpoint to update user. For now assuming we might add it to userService
      // Or we can just use a raw http call here if avoiding full service overhead
      final url = Uri.parse('${ApiConfig.baseUrl}/auth/fcm-token'); 
      // Note: You might need to add this endpoint to AuthController in backend
      // But for now let's assume we can add it or reuse update profile.
      // Actually per plan I said I'd add it to auth/user controller.
      // Let's assume PUT /users/fcm-token exists as per plan
    
       /* 
       // Implementation pending backend endpoint creation
       await http.put(
         Uri.parse('${ApiConfig.baseUrl}/users/fcm-token'),
         headers: {
           'Content-Type': 'application/json',
           'Authorization': 'Bearer ${auth.token}',
         },
         body: jsonEncode({'fcmToken': token}),
       );
       */
    } catch (e) {
      print('Error updating FCM token: $e');
    }
  }

  Future<void> fetchNotifications() async {
    if (auth.token == null) return;

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/notifications'),
        headers: {
          'Authorization': 'Bearer ${auth.token}',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _notifications = data.map((json) => AppNotification.fromJson(json)).toList();
        _unreadCount = _notifications.where((n) => !n.isRead).length;
        notifyListeners();
      }
    } catch (e) {
      print('Error fetching notifications: $e');
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/notifications/$id/read'),
        headers: {
          'Authorization': 'Bearer ${auth.token}',
        },
      );

      if (response.statusCode == 200) {
        final index = _notifications.indexWhere((n) => n.id == id);
        if (index != -1) {
          // We can just reload or manually update local state
          fetchNotifications(); 
        }
      }
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }
}
