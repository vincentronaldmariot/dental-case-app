import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'config/app_config.dart';

class PatientNotificationsScreen extends StatefulWidget {
  final String patientId;
  final String patientToken;

  const PatientNotificationsScreen({
    super.key,
    required this.patientId,
    required this.patientToken,
  });

  @override
  State<PatientNotificationsScreen> createState() =>
      _PatientNotificationsScreenState();
}

class _PatientNotificationsScreenState
    extends State<PatientNotificationsScreen> {
  List<dynamic> _notifications = [];
  bool _isLoading = true;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _loadUnreadCount();
  }

  Future<void> _loadNotifications() async {
    try {
      final response = await http.get(
        Uri.parse(
            '${AppConfig.apiBaseUrl}/patients/${widget.patientId}/notifications'),
        headers: {
          'Authorization': 'Bearer ${widget.patientToken}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final notifications = data['notifications'] ?? [];

        setState(() {
          _notifications = notifications;
        });

        final unreadInList =
            _notifications.where((n) => n['read'] == false).length;
        await _loadUnreadCount();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('Failed to load notifications: ${response.statusCode}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading notifications: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _loadUnreadCount() async {
    try {
      final response = await http.get(
        Uri.parse(
            '${AppConfig.apiBaseUrl}/patients/${widget.patientId}/notifications/unread-count'),
        headers: {
          'Authorization': 'Bearer ${widget.patientToken}',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _unreadCount = data['unreadCount'] ?? 0;
        });
      }
    } catch (e) {
      print('Error loading unread count: $e');
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      final response = await http.put(
        Uri.parse(
            '${AppConfig.apiBaseUrl}/patients/${widget.patientId}/notifications/$notificationId/read'),
        headers: {
          'Authorization': 'Bearer ${widget.patientToken}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        // Reload notifications and unread count
        await _loadNotifications();
        await _loadUnreadCount();
      }
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'appointment_rejected':
        return Colors.red;
      case 'appointment_approved':
        return Colors.green;
      case 'appointment_reminder':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'appointment_rejected':
        return Icons.cancel;
      case 'appointment_approved':
        return Icons.check_circle;
      case 'appointment_reminder':
        return Icons.schedule;
      default:
        return Icons.notifications;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF0029B2),
        elevation: 0,
        actions: [
          if (_unreadCount > 0)
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$_unreadCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              _loadNotifications();
              _loadUnreadCount();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.notifications_none,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No notifications yet',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'You\'ll see notifications here when your appointments are updated',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Test button to verify tap events work
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      child: ElevatedButton(
                        onPressed: () {
                          print('=== TEST BUTTON TAPPED ===');
                        },
                        child: const Text('Test Button - Tap Me'),
                      ),
                    ),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () async {
                          await _loadNotifications();
                          await _loadUnreadCount();
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _notifications.length,
                          itemBuilder: (context, index) {
                            final notification = _notifications[index];
                            final isUnread = !(notification['isRead'] ?? false);

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: isUnread ? 4 : 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: isUnread
                                      ? Border.all(
                                          color: _getNotificationColor(
                                              notification.type),
                                          width: 2,
                                        )
                                      : null,
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () {
                                      print('=== INKWELL TAP DETECTED ===');
                                      print(
                                          'Notification ID: ${notification['id']}');
                                      // Mark as read when tapped
                                      if (isUnread) {
                                        _markAsRead(
                                            notification['id'].toString());
                                      }
                                    },
                                    borderRadius: BorderRadius.circular(12),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: _getNotificationColor(
                                                      notification.type)
                                                  .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Icon(
                                              _getNotificationIcon(
                                                  notification['type']),
                                              color: _getNotificationColor(
                                                  notification['type']),
                                              size: 24,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        notification['title'],
                                                        style: TextStyle(
                                                          fontWeight: isUnread
                                                              ? FontWeight.bold
                                                              : FontWeight.w600,
                                                          fontSize: 16,
                                                          color: isUnread
                                                              ? Colors.black
                                                              : Colors
                                                                  .grey[700],
                                                        ),
                                                      ),
                                                    ),
                                                    if (isUnread)
                                                      Container(
                                                        width: 8,
                                                        height: 8,
                                                        decoration:
                                                            BoxDecoration(
                                                          color:
                                                              _getNotificationColor(
                                                                  notification[
                                                                      'type']),
                                                          shape:
                                                              BoxShape.circle,
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  notification['message'],
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  _formatDate(DateTime.parse(
                                                      notification[
                                                          'createdAt'])),
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[500],
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
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }
}
