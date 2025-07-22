import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class NotificationService extends ChangeNotifier {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

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
    try {
      print('🔍 Fetching notifications for patient: "$patientId"');
      print('🔍 Patient ID length: ${patientId.length}');
      print('🔍 Patient ID is empty: ${patientId.isEmpty}');
      print('🔍 Using token: ${token.substring(0, 20)}...');

      if (patientId.isEmpty || patientId == 'guest') {
        throw Exception('Invalid patient ID: $patientId');
      }

      final response = await http.get(
        Uri.parse(
            'http://localhost:3000/api/patients/$patientId/notifications'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('🔍 Response status code: ${response.statusCode}');
      print('🔍 Response headers: ${response.headers}');
      print('🔍 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Backend response: $data');
        print('✅ Notifications count: ${data['notifications']?.length ?? 0}');
        _notifications.clear();
        for (var n in data['notifications']) {
          _notifications.add(AppNotification(
            id: n['id'].toString(),
            title: n['title'],
            message: n['message'],
            type: NotificationType
                .appointment, // You can map backend type if needed
            isRead: n['isRead'],
            createdAt: DateTime.parse(n['createdAt']),
          ));
        }
        notifyListeners();
      } else {
        print('❌ Error response: ${response.statusCode} - ${response.body}');
        throw Exception(
            'Failed to fetch notifications: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ Exception in fetchNotifications: $e');
      throw Exception('Failed to fetch notifications: $e');
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
