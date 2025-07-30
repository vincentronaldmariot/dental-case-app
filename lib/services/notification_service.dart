import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';

class NotificationService extends ChangeNotifier {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // Use centralized configuration instead of hardcoded localhost
  static String get baseUrl => AppConfig.apiBaseUrl;

  final List<AppNotification> _notifications = [];

  List<AppNotification> get notifications => List.unmodifiable(_notifications);

  void initializeSampleData() {
    if (_notifications.isNotEmpty) return;

    // Removed static notifications. Only real notifications will be shown.
    // _notifications.addAll([
    //   AppNotification(
    //     id: 'notif_1',
    //     title: 'Appointment Reminder',
    //     message: 'Your cleaning appointment is tomorrow at 10:00 AM',
    //     type: NotificationType.appointment,
    //     isRead: false,
    //     createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    //   ),
    //   AppNotification(
    //     id: 'notif_2',
    //     title: 'Health Tip',
    //     message: 'Remember to floss daily for optimal oral health',
    //     type: NotificationType.healthTip,
    //     isRead: false,
    //     createdAt: DateTime.now().subtract(const Duration(days: 1)),
    //   ),
    //   AppNotification(
    //     id: 'notif_3',
    //     title: 'Treatment Update',
    //     message: 'Your root canal treatment is 80% complete',
    //     type: NotificationType.treatmentUpdate,
    //     isRead: true,
    //     createdAt: DateTime.now().subtract(const Duration(days: 3)),
    //   ),
    // ]);
  }

  void addNotification(AppNotification notification) {
    _notifications.insert(0, notification);
  }

  void markAsRead(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      notifyListeners();
    }
  }

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  List<AppNotification> getUnreadNotifications() {
    return _notifications.where((n) => !n.isRead).toList();
  }

  Future<void> fetchNotifications(String patientId, String token) async {
    if (patientId.isEmpty || patientId == 'null' || patientId == 'undefined') {
      print('⚠️ Invalid patient ID: "$patientId"');
      throw Exception('Invalid patient ID: $patientId');
    }

    if (token.isEmpty || token == 'null' || token == 'undefined') {
      print('⚠️ Invalid token: "$token"');
      throw Exception('Invalid token: $token');
    }

    try {
      final response = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/patients/$patientId/notifications'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('📋 Raw notification response: $data');

        final notifications = data['notifications'] ?? [];
        print('📋 Found ${notifications.length} notifications');

        _notifications.clear();
        for (var n in notifications) {
          try {
            _notifications.add(AppNotification(
              id: n['id']?.toString() ?? '',
              title: n['title']?.toString() ?? '',
              message: n['message']?.toString() ?? '',
              type: NotificationType.appointment,
              isRead: n['isRead'] == true || n['read'] == true,
              createdAt: n['createdAt'] != null
                  ? DateTime.parse(n['createdAt'].toString())
                  : n['created_at'] != null
                      ? DateTime.parse(n['created_at'].toString())
                      : DateTime.now(),
            ));
          } catch (e) {
            print('⚠️ Error parsing notification: $e');
            print('⚠️ Notification data: $n');
            // Skip invalid notifications
            continue;
          }
        }
        notifyListeners();
      } else {
        print('❌ Failed to fetch notifications: ${response.statusCode}');
        print('❌ Response body: ${response.body}');
        throw Exception(
          'Failed to fetch notifications: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('❌ Exception in fetchNotifications: $e');
      // Don't throw the exception, just log it and continue with empty notifications
      _notifications.clear();
      notifyListeners();
    }
  }
}

enum NotificationType { appointment, healthTip, treatmentUpdate, emergency }

class AppNotification {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final bool isRead;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
  });

  AppNotification copyWith({
    String? id,
    String? title,
    String? message,
    NotificationType? type,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
