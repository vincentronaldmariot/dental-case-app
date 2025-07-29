import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import './welcome_screen.dart';
import './dental_survey_screen.dart';
import './appointment_booking_screen.dart';
import './emergency_center_screen.dart';

import './user_state_manager.dart';
import './services/history_service.dart';
import './services/notification_service.dart';
import './services/api_service.dart';
import './services/survey_service.dart';
import './models/appointment.dart';
import './models/patient.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // Added for jsonDecode
import 'dart:async'; // Added for Timer
import 'config/app_config.dart';

class MainAppScreen extends StatefulWidget {
  const MainAppScreen({super.key});

  @override
  State<MainAppScreen> createState() => _MainAppScreenState();
}

class _MainAppScreenState extends State<MainAppScreen> {
  late NotificationService _notificationService;

  @override
  void initState() {
    super.initState();
    _notificationService = NotificationService();
    _notificationService.addListener(_onNotificationChanged);
    _loadInitialNotifications();
  }

  @override
  void dispose() {
    _notificationService.removeListener(_onNotificationChanged);
    super.dispose();
  }

  void _onNotificationChanged() {
    setState(() {
      // This will rebuild the UI when notifications change
    });
  }

  Future<void> _loadInitialNotifications() async {
    final patientId = UserStateManager().currentPatientId;
    final token = UserStateManager().patientToken;

    if (token != null && patientId != 'guest') {
      try {
        await _notificationService.fetchNotifications(patientId, token);
      } catch (e) {
        // Silent fail for background notification loading
      }
    }
  }

  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const AppointmentsScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF0029B2),
          unselectedItemColor: Colors.grey,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today_outlined),
              activeIcon: Icon(Icons.calendar_today),
              label: 'Appointments',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Timer? _notificationCheckTimer;

  @override
  void initState() {
    super.initState();
    _fetchAndSyncAppointments();
    _checkForApprovalNotifications();

    // Set up periodic check for approval notifications every 2 minutes
    _notificationCheckTimer =
        Timer.periodic(const Duration(minutes: 2), (timer) {
      _checkForApprovalNotifications();
    });
  }

  @override
  void dispose() {
    _notificationCheckTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchAndSyncAppointments() async {
    final patientId = UserStateManager().currentPatientId;
    if (patientId != 'guest') {
      try {
        final backendAppointments = await ApiService.getAppointments(patientId);
        HistoryService().loadAppointmentsFromBackend(backendAppointments,
            patientId: patientId);
        setState(() {}); // Refresh UI after loading
      } catch (e) {
        // Show user-friendly error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  const Text('Failed to load appointments. Please try again.'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  // Check for approval notifications and refresh appointments if needed
  Future<void> _checkForApprovalNotifications() async {
    try {
      final patientId = UserStateManager().currentPatientId;
      final patientToken = UserStateManager().patientToken;

      if (patientId.isEmpty || patientToken == null || patientId == 'guest') {
        return;
      }

      final response = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/patients/$patientId/notifications'),
        headers: {
          'Authorization': 'Bearer $patientToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final notifications = data['notifications'] ?? [];

        // Check if there are any recent approval notifications
        final approvalNotifications = notifications.where((notification) {
          final type = notification['type'] ?? '';
          final createdAt = notification['created_at'];
          final isRecent = createdAt != null &&
              DateTime.parse(createdAt)
                  .isAfter(DateTime.now().subtract(const Duration(hours: 1)));
          return type == 'appointment_approved' && isRecent;
        }).toList();

        if (approvalNotifications.isNotEmpty) {
          await _fetchAndSyncAppointments();
          setState(() {}); // Refresh UI
        }
      }
    } catch (e) {
      // Silent fail for background notification checks
      // Don't show error to user for background operations
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, color: Colors.black87),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserStatusBanner(BuildContext context) {
    final userState = UserStateManager();

    if (userState.isClientLoggedIn) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF005800), Color(0xFF004400)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: const SafeArea(
          bottom: false,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.verified_user, color: Colors.white, size: 16),
              SizedBox(width: 8),
              Text(
                'AUTHENTICATED USER',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
      );
    } else if (userState.isAdminLoggedIn) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF7B1FA2), Color(0xFF4A148C)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: const SafeArea(
          bottom: false,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.admin_panel_settings,
                color: Colors.white,
                size: 18,
              ),
              SizedBox(width: 8),
              Text(
                'ADMINISTRATOR MODE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Default: no banner for unknown state
    return const SizedBox.shrink();
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.logout, color: Colors.red, size: 28),
              SizedBox(width: 12),
              Text(
                'Logout',
                style: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: const Text(
            'Are you sure you want to logout from your account?',
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                // Reset client state and logout
                UserStateManager().logoutClient();
                Navigator.of(context).pop();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => const WelcomeScreen(),
                  ),
                  (Route<dynamic> route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Logout',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRecentActivitySection() {
    final historyService = HistoryService();
    final patientId = UserStateManager().currentPatientId;
    final completedAppointments = historyService
        .getAppointmentsByStatus(AppointmentStatus.completed,
            patientId: patientId)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    final lastThree = completedAppointments.take(3).toList();
    print('Building history card for patientId=$patientId');
    print('Completed appointments: $completedAppointments');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Appointment History',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 15),
        if (lastThree.isEmpty)
          _buildEmptyActivityCard()
        else
          ...lastThree.map(
            (appointment) => _buildActivityCard(
              appointment.service,
              '',
              DateFormat('MMM dd, yyyy').format(appointment.date),
              Icons.history,
              Colors.green,
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyActivityCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.event_note, color: Colors.grey, size: 22),
          ),
          const SizedBox(width: 15),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No Recent Activity',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  ),
                ),
                Text(
                  'Book your first appointment to get started',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showNotifications(BuildContext context) async {
    final patientId = UserStateManager().currentPatientId;
    final token = UserStateManager().patientToken;

    print('🔍 _showNotifications called');
    print('🔍 Patient ID: "$patientId"');
    print('🔍 Token: ${token != null ? "Present" : "NULL"}');
    print('🔍 Is Patient Logged In: ${UserStateManager().isPatientLoggedIn}');

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You are not logged in.')),
      );
      return;
    }

    if (patientId.isEmpty || patientId == 'guest') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Patient information not available. Please log in again.')),
      );
      return;
    }

    try {
      print('🔍 Fetching notifications for patient: $patientId');
      await NotificationService().fetchNotifications(patientId, token);
      print(
          '✅ Fetched notifications: ${NotificationService().notifications.length} total');
    } catch (e) {
      print('❌ Error fetching notifications: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load notifications: $e')),
      );
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) {
          final notifications = NotificationService().notifications;
          return Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Notifications',
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      onPressed: () async {
                        final patientId = UserStateManager().currentPatientId;
                        final token = UserStateManager().patientToken;

                        print('🔍 Refresh notifications called');
                        print('🔍 Patient ID: "$patientId"');
                        print(
                            '🔍 Token: ${token != null ? "Present" : "NULL"}');

                        if (token == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('You are not logged in.'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        if (patientId.isEmpty || patientId == 'guest') {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Patient information not available. Please log in again.'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        try {
                          await NotificationService()
                              .fetchNotifications(patientId, token);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Notifications refreshed! ${NotificationService().unreadCount} unread'),
                              backgroundColor: Colors.green,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                          // Force rebuild of the modal
                          setState(() {});
                        } catch (e) {
                          print('❌ Error refreshing notifications: $e');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content:
                                  Text('Failed to refresh notifications: $e'),
                              backgroundColor: Colors.red,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.refresh, color: Color(0xFF0029B2)),
                      tooltip: 'Refresh notifications',
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final notification = notifications[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: notification.isRead
                                ? Colors.grey[200]
                                : Colors.blue[100],
                            child: Icon(
                              _getNotificationIcon(notification.type),
                              color: notification.isRead
                                  ? Colors.grey
                                  : Colors.blue,
                            ),
                          ),
                          title: Text(
                            notification.title,
                            style: TextStyle(
                              fontWeight: notification.isRead
                                  ? FontWeight.normal
                                  : FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(notification.message),
                          trailing: Text(
                            DateFormat('MMM dd').format(notification.createdAt),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          onTap: () async {
                            print('=== MODAL NOTIFICATION TAPPED ===');
                            print('Notification ID: ${notification.id}');
                            print(
                                'Notification isRead: ${notification.isRead}');
                            print('Notification title: ${notification.title}');
                            if (!notification.isRead) {
                              print(
                                  'Notification is unread, proceeding to mark as read');
                              final patientId =
                                  UserStateManager().currentPatientId;
                              final token = UserStateManager().patientToken;
                              print('Patient ID: $patientId');
                              print('Token available: ${token != null}');
                              if (token != null) {
                                try {
                                  print(
                                      'Making API call to mark notification as read');
                                  final response = await http.put(
                                    Uri.parse(
                                        '${AppConfig.apiBaseUrl}/patients/$patientId/notifications/${notification.id}/read'),
                                    headers: {
                                      'Authorization': 'Bearer $token',
                                      'Content-Type': 'application/json',
                                    },
                                  );
                                  print(
                                      'API Response Status: ${response.statusCode}');
                                  print('API Response Body: ${response.body}');
                                  if (response.statusCode == 200) {
                                    print(
                                        'API call successful, updating notification locally');
                                    // Update the notification using the service
                                    NotificationService()
                                        .markAsRead(notification.id);
                                    print(
                                        'Notification marked as read locally');
                                    print(
                                        'New unread count: ${NotificationService().unreadCount}');
                                  } else {
                                    print(
                                        'API call failed with status: ${response.statusCode}');
                                  }
                                } catch (e) {
                                  print(
                                      'Error marking notification as read: $e');
                                }
                              } else {
                                print('No token available');
                              }
                            } else {
                              print(
                                  'Notification is already read, no action needed');
                            }
                            Navigator.pop(context);
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.appointment:
        return Icons.calendar_today;
      case NotificationType.healthTip:
        return Icons.lightbulb;
      case NotificationType.treatmentUpdate:
        return Icons.medical_services;
      case NotificationType.emergency:
        return Icons.warning;
    }
  }

  Future<void> _refreshData() async {
    final patientId = UserStateManager().currentPatientId;
    final token = UserStateManager().patientToken;

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You are not logged in.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 12),
              Text('Refreshing data...'),
            ],
          ),
          duration: Duration(seconds: 2),
          backgroundColor: Color(0xFF0029B2),
        ),
      );

      // Refresh notifications
      await NotificationService().fetchNotifications(patientId, token);

      // Refresh survey status
      try {
        final surveyResult = await SurveyService().checkSurveyStatus();
        if (surveyResult['success']) {
          UserStateManager()
              .updateSurveyStatus(surveyResult['hasCompletedSurvey']);
        }
      } catch (e) {
        print('Error refreshing survey status: $e');
      }

      // Refresh appointment data
      try {
        await ApiService.checkConnectionAndSync();
      } catch (e) {
        print('Error refreshing appointments: $e');
      }

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                  'Data refreshed successfully! ${NotificationService().unreadCount} new notifications'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );

      // Force UI rebuild
      setState(() {});
    } catch (e) {
      print('Error refreshing data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to refresh data: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // User Status Banner
            SliverToBoxAdapter(child: _buildUserStatusBanner(context)),
            // Custom App Bar
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0029B2), Color(0xFF000074)],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Image.asset(
                              'assets/image/main_logo.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        const SizedBox(width: 15),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome Back!',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'How can we help you today?',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            // Refresh Button
                            IconButton(
                              onPressed: () => _refreshData(),
                              icon: const Icon(
                                Icons.refresh,
                                color: Colors.white,
                                size: 24,
                              ),
                              tooltip: 'Refresh',
                            ),
                            const SizedBox(width: 8),
                            // Notifications Button
                            Stack(
                              children: [
                                IconButton(
                                  onPressed: () => _showNotifications(context),
                                  icon: const Icon(
                                    Icons.notifications_outlined,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                                AnimatedBuilder(
                                  animation: NotificationService(),
                                  builder: (context, child) {
                                    final unreadCount =
                                        NotificationService().unreadCount;
                                    print(
                                        'AnimatedBuilder rebuilding - unread count: $unreadCount');
                                    if (unreadCount > 0) {
                                      return Positioned(
                                        right: 8,
                                        top: 8,
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: const BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                          ),
                                          constraints: const BoxConstraints(
                                            minWidth: 16,
                                            minHeight: 16,
                                          ),
                                          child: Text(
                                            '$unreadCount',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      );
                                    }
                                    return const SizedBox.shrink();
                                  },
                                ),
                              ],
                            ),
                            PopupMenuButton<String>(
                              icon: const Icon(
                                Icons.account_circle,
                                color: Colors.white,
                                size: 32,
                              ),
                              onSelected: (value) {
                                if (value == 'logout') {
                                  _showLogoutDialog(context);
                                }
                              },
                              itemBuilder: (BuildContext context) => [
                                const PopupMenuItem<String>(
                                  value: 'profile',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.person,
                                        color: Color(0xFF0029B2),
                                      ),
                                      SizedBox(width: 12),
                                      Text('My Profile'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem<String>(
                                  value: 'settings',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.settings,
                                        color: Color(0xFF0029B2),
                                      ),
                                      SizedBox(width: 12),
                                      Text('Settings'),
                                    ],
                                  ),
                                ),
                                const PopupMenuDivider(),
                                const PopupMenuItem<String>(
                                  value: 'logout',
                                  child: Row(
                                    children: [
                                      Icon(Icons.logout, color: Colors.red),
                                      SizedBox(width: 12),
                                      Text(
                                        'Logout',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Quick Actions
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 15),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing:
                          MediaQuery.of(context).size.width > 600 ? 15 : 12,
                      mainAxisSpacing:
                          MediaQuery.of(context).size.width > 600 ? 15 : 12,
                      childAspectRatio:
                          MediaQuery.of(context).size.width > 600 ? 1.0 : 1.1,
                      children: [
                        _buildQuickActionCard(
                          context,
                          'Book Appointment',
                          Icons.calendar_month,
                          const Color(0xFF0029B2),
                          () => _handleAppointmentBooking(context),
                        ),
                        _buildQuickActionCard(
                          context,
                          'Emergency',
                          Icons.local_hospital,
                          const Color(0xFFE74C3C),
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const EmergencyCenterScreen(),
                              ),
                            );
                          },
                        ),
                        _buildQuickActionCard(
                          context,
                          'Health Assessment',
                          Icons.assignment_outlined,
                          const Color(0xFF005800),
                          () async {
                            // Check if patient has already completed the survey
                            final surveyService = SurveyService();
                            final surveyStatus =
                                await surveyService.checkSurveyStatus();

                            if (surveyStatus['success'] == true &&
                                surveyStatus['hasCompletedSurvey'] == true) {
                              // Show confirmation dialog if survey already completed
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  title: const Row(
                                    children: [
                                      Icon(Icons.assignment_outlined,
                                          color: Color(0xFF005800), size: 30),
                                      SizedBox(width: 10),
                                      Text('Survey Already Completed'),
                                    ],
                                  ),
                                  content: const Text(
                                    'You have already completed the health assessment survey. Would you like to answer it again?',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(),
                                      child: const Text('Cancel',
                                          style: TextStyle(color: Colors.grey)),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const DentalSurveyScreen(),
                                          ),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFF005800),
                                        foregroundColor: Colors.white,
                                      ),
                                      child: const Text('Answer Again'),
                                    ),
                                  ],
                                ),
                              );
                            } else {
                              // Navigate directly to survey if not completed
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const DentalSurveyScreen(),
                                ),
                              );
                            }
                          },
                        ),
                        _buildQuickActionCard(
                          context,
                          'Accepted Appointments',
                          Icons.check_circle,
                          const Color(0xFF00B8D4),
                          () async {
                            final patientId =
                                UserStateManager().currentPatientId;
                            final patient = UserStateManager().currentPatient;
                            final historyService = HistoryService();
                            // Assuming 'scheduled' means approved/accepted for patients
                            final approvedAppointments =
                                historyService.getAppointmentsByStatus(
                                    AppointmentStatus.scheduled,
                                    patientId: patientId);
                            approvedAppointments
                                .sort((a, b) => b.date.compareTo(a.date));
                            final latest = approvedAppointments.isNotEmpty
                                ? approvedAppointments.first
                                : null;
                            // DEBUG PRINTS
                            print('DEBUG: patientId = '
                                ' [32m$patientId [0m');
                            print('DEBUG: patient = '
                                ' [36m$patient [0m');
                            print('DEBUG: approvedAppointments = '
                                ' [35m$approvedAppointments [0m');
                            if (latest != null) {
                              print('DEBUG: latest approved = '
                                  ' [33m$latest [0m');
                            }
                            if (latest == null || patient == null) {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  title: const Row(
                                    children: [
                                      Icon(Icons.info_outline,
                                          color: Colors.orange, size: 30),
                                      SizedBox(width: 10),
                                      Text('No Appointments'),
                                    ],
                                  ),
                                  content: const Text(
                                    'No approved appointments found.',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(),
                                      child: const Text('Close',
                                          style: TextStyle(color: Colors.grey)),
                                    ),
                                  ],
                                ),
                              );
                              return;
                            }

                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                contentPadding: EdgeInsets.zero,
                                content: Container(
                                  width: 350,
                                  constraints: BoxConstraints(
                                    maxHeight:
                                        MediaQuery.of(context).size.height *
                                            0.75,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(15),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 10,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Receipt Header
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(16),
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF00B8D4),
                                          borderRadius: BorderRadius.only(
                                            topLeft: Radius.circular(15),
                                            topRight: Radius.circular(15),
                                          ),
                                        ),
                                        child: Column(
                                          children: [
                                            const Icon(
                                              Icons.check_circle,
                                              color: Colors.white,
                                              size: 32,
                                            ),
                                            const SizedBox(height: 6),
                                            const Text(
                                              'APPOINTMENT RECEIPT',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 1.0,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Approved & Confirmed',
                                              style: TextStyle(
                                                color: Colors.white
                                                    .withOpacity(0.9),
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Receipt Content - Scrollable
                                      Expanded(
                                        child: SingleChildScrollView(
                                          padding: const EdgeInsets.all(16),
                                          child: Column(
                                            children: [
                                              // Receipt Details
                                              Container(
                                                padding:
                                                    const EdgeInsets.all(12),
                                                decoration: BoxDecoration(
                                                  color: Colors.grey[50],
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  border: Border.all(
                                                      color: Colors.grey[200]!),
                                                ),
                                                child: Column(
                                                  children: [
                                                    _buildReceiptRow(
                                                        'Patient Name',
                                                        '${patient.firstName} ${patient.lastName}'),
                                                    Divider(
                                                        height: 16,
                                                        color:
                                                            Colors.grey[300]),
                                                    _buildReceiptRow('Service',
                                                        latest.service),
                                                    Divider(
                                                        height: 16,
                                                        color:
                                                            Colors.grey[300]),
                                                    _buildReceiptRow(
                                                        'Classification',
                                                        patient.classification
                                                                .isNotEmpty
                                                            ? patient
                                                                .classification
                                                            : 'N/A'),
                                                    Divider(
                                                        height: 16,
                                                        color:
                                                            Colors.grey[300]),
                                                    _buildReceiptRow(
                                                        'ID Reference',
                                                        latest.id),
                                                    Divider(
                                                        height: 16,
                                                        color:
                                                            Colors.grey[300]),
                                                    _buildReceiptRow(
                                                        'Date',
                                                        DateFormat(
                                                                'MMM dd, yyyy')
                                                            .format(
                                                                latest.date)),
                                                    Divider(
                                                        height: 16,
                                                        color:
                                                            Colors.grey[300]),
                                                    _buildReceiptRow('Time',
                                                        latest.timeSlot),
                                                  ],
                                                ),
                                              ),

                                              const SizedBox(height: 16),

                                              // QR Code
                                              Container(
                                                padding:
                                                    const EdgeInsets.all(12),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  border: Border.all(
                                                      color: Colors.grey[200]!),
                                                ),
                                                child: Column(
                                                  children: [
                                                    Text(
                                                      'Scan for Details',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: Colors.grey[700],
                                                      ),
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              8),
                                                      decoration: BoxDecoration(
                                                        color: Colors.white,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(6),
                                                        border: Border.all(
                                                            color: Colors
                                                                .grey[300]!),
                                                      ),
                                                      child: QrImageView(
                                                        data:
                                                            'APPT:${latest.id}|${patient.firstName} ${patient.lastName}|${latest.service}|${DateFormat('yyyy-MM-dd').format(latest.date)}|${latest.timeSlot}',
                                                        version:
                                                            QrVersions.auto,
                                                        size: 100,
                                                        backgroundColor:
                                                            Colors.white,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),

                                      // Close Button
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(16),
                                        child: ElevatedButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                const Color(0xFF00B8D4),
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 10),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                          child: const Text(
                                            'Close Receipt',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Recent Activity
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: _buildRecentActivitySection(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: isSmallScreen ? 50 : 60,
              height: isSmallScreen ? 50 : 60,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: isSmallScreen ? 26 : 30),
            ),
            SizedBox(height: isSmallScreen ? 10 : 12),
            Flexible(
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard(String title, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 25),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard(
    String title,
    String subtitle,
    String date,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                ),
                Text(
                  date,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleAppointmentBooking(BuildContext context) async {
    final userState = UserStateManager();

    // For authenticated patients, check survey status from database
    if (userState.isPatientLoggedIn) {
      try {
        final surveyService = SurveyService();
        final result = await surveyService.checkSurveyStatus();

        if (result['success']) {
          final hasCompletedSurvey = result['hasCompletedSurvey'];
          userState.updateSurveyStatus(hasCompletedSurvey);

          if (hasCompletedSurvey) {
            // Patient has completed survey, allow appointment booking
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AppointmentBookingScreen(),
              ),
            );
            return;
          }
        }
      } catch (e) {
        print('Error checking survey status: $e');
        // If there's an error, fall back to local state
      }
    }

    // Check local state for other user types or fallback
    if (userState.canBookAppointment()) {
      // User has completed survey or is not a first-time user, allow appointment booking
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const AppointmentBookingScreen(),
        ),
      );
    } else {
      // First-time user who hasn't completed survey, redirect to survey
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.assignment_outlined,
                color: Color(0xFF005800),
                size: 30,
              ),
              SizedBox(width: 10),
              Text('Health Assessment Required'),
            ],
          ),
          content: const Text(
            'Before booking your first appointment, we need you to complete a quick health assessment. This helps us provide you with the best care possible.',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Later', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DentalSurveyScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF005800),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Start Assessment'),
            ),
          ],
        ),
      );
    }
  }
}

// Functional Appointments Screen
class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  final HistoryService _historyService = HistoryService();
  String _selectedTab = 'All';
  bool _isLoading = false;

  // Debug method to show current appointment state
  void _debugAppointmentState() {
    final patientId = UserStateManager().currentPatientId;
    print('🔍 === DEBUG APPOINTMENT STATE ===');
    print('Patient ID: $patientId');
    print('Selected Tab: $_selectedTab');
    print('Is Loading: $_isLoading');

    final allAppointments =
        _historyService.getAppointments(patientId: patientId);
    print('Total appointments in HistoryService: ${allAppointments.length}');

    for (int i = 0; i < allAppointments.length; i++) {
      final apt = allAppointments[i];
      print(
          '   $i: ID=${apt.id}, Service=${apt.service}, Status=${apt.status}, Date=${apt.date}');
    }

    final pendingAppointments = _historyService.getAppointmentsByStatus(
      AppointmentStatus.pending,
      patientId: patientId,
    );
    print('Pending appointments: ${pendingAppointments.length}');

    // Additional detailed debugging
    print('🔍 === DETAILED STATUS ANALYSIS ===');
    final statusCounts = <String, int>{};
    for (final apt in allAppointments) {
      final statusName = apt.status.name;
      statusCounts[statusName] = (statusCounts[statusName] ?? 0) + 1;
    }
    statusCounts.forEach((status, count) {
      print('   Status "$status": $count appointments');
    });

    // Check if there are any appointments with unexpected status values
    final unexpectedStatuses = allAppointments.where((apt) {
      return apt.status == AppointmentStatus.pending &&
          apt.service.isEmpty &&
          apt.id.isEmpty;
    }).toList();

    if (unexpectedStatuses.isNotEmpty) {
      print(
          '⚠️ Found ${unexpectedStatuses.length} appointments with unexpected pending status:');
      for (final apt in unexpectedStatuses) {
        print(
            '   - ID: "${apt.id}", Service: "${apt.service}", Status: ${apt.status}');
      }
    }

    // Check for any appointments with empty or null values that might be causing issues
    final problematicAppointments = allAppointments.where((apt) {
      return apt.id.isEmpty || apt.service.isEmpty || apt.patientId.isEmpty;
    }).toList();

    if (problematicAppointments.isNotEmpty) {
      print(
          '⚠️ Found ${problematicAppointments.length} appointments with empty values:');
      for (final apt in problematicAppointments) {
        print(
            '   - ID: "${apt.id}", PatientID: "${apt.patientId}", Service: "${apt.service}", Status: ${apt.status}');
      }
    }

    // Check if there are any appointments that don't belong to the current patient
    final wrongPatientAppointments = allAppointments.where((apt) {
      return apt.patientId != patientId;
    }).toList();

    if (wrongPatientAppointments.isNotEmpty) {
      print(
          '⚠️ Found ${wrongPatientAppointments.length} appointments for wrong patient:');
      for (final apt in wrongPatientAppointments) {
        print(
            '   - ID: "${apt.id}", PatientID: "${apt.patientId}", Service: "${apt.service}", Status: ${apt.status}');
      }
    }

    print('=== END DEBUG ===');
  }

  // Debug method to clear potentially corrupted data
  void _clearCorruptedData() {
    final patientId = UserStateManager().currentPatientId;
    print('🧹 === CLEARING POTENTIALLY CORRUPTED DATA ===');

    final allAppointments =
        _historyService.getAppointments(patientId: patientId);
    final corruptedAppointments = allAppointments.where((apt) {
      return apt.id.isEmpty ||
          apt.service.isEmpty ||
          (apt.status == AppointmentStatus.pending && apt.id.isEmpty);
    }).toList();

    if (corruptedAppointments.isNotEmpty) {
      print(
          '🗑️ Found ${corruptedAppointments.length} potentially corrupted appointments:');
      for (final apt in corruptedAppointments) {
        print(
            '   - ID: "${apt.id}", Service: "${apt.service}", Status: ${apt.status}');
      }

      // Clear all appointments for this patient and reload from backend
      _historyService.clearAppointmentsForPatient(patientId);
      print('✅ Cleared all appointments for patient $patientId');

      // Reload from backend
      _loadAppointmentsFromBackend();
    } else {
      print('✅ No corrupted appointments found');
    }

    print('=== END CLEARING ===');
  }

  // Debug method to force refresh and clear all data
  void _forceRefreshAppointments() {
    final patientId = UserStateManager().currentPatientId;
    print('🔄 === FORCE REFRESH APPOINTMENTS ===');
    print('Patient ID: $patientId');

    // Clear all appointments for this patient
    _historyService.clearAppointmentsForPatient(patientId);
    print('✅ Cleared all appointments for patient $patientId');

    // Force reload from backend
    _loadAppointmentsFromBackend();

    // Force UI refresh
    setState(() {
      _selectedTab = 'All'; // Reset to All tab
    });

    print('=== END FORCE REFRESH ===');
  }

  @override
  void initState() {
    super.initState();
    _loadAppointmentsFromBackend();
  }

  Future<void> _loadAppointmentsFromBackend() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final patientId = UserStateManager().currentPatientId;
      if (patientId != 'guest') {
        print('Loading appointments from backend for patient: $patientId');
        final backendAppointments = await ApiService.getAppointments(patientId);

        if (backendAppointments.isEmpty) {
          print(
              '📭 No appointments returned from backend, clearing existing appointments for patient $patientId');
          _historyService.clearAppointmentsForPatient(patientId);
        } else {
          _historyService.loadAppointmentsFromBackend(backendAppointments,
              patientId: patientId);
        }

        print('Loaded ${backendAppointments.length} appointments from backend');

        // Debug: Check what appointments we have after loading
        final allAppointments =
            _historyService.getAppointments(patientId: patientId);
        final pendingAppointments = _historyService.getAppointmentsByStatus(
          AppointmentStatus.pending,
          patientId: patientId,
        );
        print(
            '🔍 After loading - Total appointments: ${allAppointments.length}');
        print(
            '🔍 After loading - Pending appointments: ${pendingAppointments.length}');

        // Auto-select pending tab if there are pending appointments and no tab is selected
        if (pendingAppointments.isNotEmpty && _selectedTab == 'All') {
          print('🔍 Auto-selecting Pending tab due to pending appointments');
          _selectedTab = 'Pending';
        }

        // Force UI refresh after loading appointments
        print('🔄 Triggering setState to refresh UI...');
        setState(() {
          // This will trigger a rebuild of the tabs and appointment list
        });
        print('✅ setState completed');
      } else {
        print('No valid patient ID, skipping backend load');
      }
    } catch (e) {
      print('Error loading appointments from backend: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshAppointments() async {
    await _loadAppointmentsFromBackend();
  }

  Widget _buildUserStatusBanner(BuildContext context) {
    final userState = UserStateManager();

    if (userState.isClientLoggedIn) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 16),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF005800), Color(0xFF004400)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.verified_user, color: Colors.white, size: 12),
            SizedBox(width: 6),
            Text(
              'AUTHENTICATED USER',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Column(
          children: [
            _buildUserStatusBanner(context),
            Expanded(
              child: AppBar(
                title: const Text(
                  'My Appointments',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                backgroundColor: const Color(0xFF0029B2),
                elevation: 0,
                automaticallyImplyLeading: false,
                actions: [
                  // Sync button for testing
                  IconButton(
                    onPressed: () async {
                      final success = await ApiService.checkConnectionAndSync();
                      if (success) {
                        await _refreshAppointments();
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            success
                                ? '✅ Backend connected and appointments refreshed!'
                                : '❌ Backend unavailable, running offline',
                          ),
                          backgroundColor:
                              success ? Colors.green : Colors.orange,
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    },
                    icon: const Icon(Icons.sync, color: Colors.white, size: 24),
                    tooltip: 'Sync with backend',
                  ),
                  // Debug button to clear all appointments
                  IconButton(
                    onPressed: () {
                      _historyService.clearAllAppointments();
                      setState(() {});
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              '🗑️ All appointments cleared for debugging'),
                          backgroundColor: Colors.red,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(Icons.clear_all,
                        color: Colors.white, size: 24),
                    tooltip: 'Clear all appointments (debug)',
                  ),
                  // Debug button to clear all data
                  IconButton(
                    onPressed: () {
                      _historyService.clearAllData();
                      setState(() {});
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('🗑️ All data cleared for debugging'),
                          backgroundColor: Colors.red,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(Icons.delete_forever,
                        color: Colors.white, size: 24),
                    tooltip: 'Clear all data (debug)',
                  ),
                  // Debug button to show appointment state
                  IconButton(
                    onPressed: () {
                      _debugAppointmentState();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('🔍 Check console for debug info'),
                          backgroundColor: Colors.blue,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(Icons.bug_report,
                        color: Colors.white, size: 24),
                    tooltip: 'Debug appointment state',
                  ),
                  // Debug button to clear corrupted data
                  IconButton(
                    onPressed: () {
                      _clearCorruptedData();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('🧹 Clearing corrupted data...'),
                          backgroundColor: Colors.orange,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(Icons.cleaning_services,
                        color: Colors.white, size: 24),
                    tooltip: 'Clear corrupted data',
                  ),
                  // Debug button to clear all pending appointments
                  IconButton(
                    onPressed: () {
                      _historyService.clearAllPendingAppointments();
                      setState(() {});
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('⏳ All pending appointments cleared'),
                          backgroundColor: Colors.purple,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(Icons.pending_actions,
                        color: Colors.white, size: 24),
                    tooltip: 'Clear all pending appointments',
                  ),
                  // Debug button to force refresh appointments
                  IconButton(
                    onPressed: () {
                      _forceRefreshAppointments();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('🔄 Force refreshing appointments...'),
                          backgroundColor: Colors.purple,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(Icons.refresh,
                        color: Colors.white, size: 24),
                    tooltip: 'Force refresh appointments',
                  ),
                  IconButton(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const AppointmentBookingScreen(),
                        ),
                      );
                      // Refresh appointments after booking
                      await _refreshAppointments();
                      // Force UI refresh to show new tabs if needed
                      setState(() {});
                    },
                    icon: const Icon(Icons.add, color: Colors.white, size: 28),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Tab Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF0029B2), Color(0xFF000074)],
              ),
            ),
            child: Row(
              children: _buildConditionalTabs(),
            ),
          ),

          // Appointments List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Color(0xFF0029B2)),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Loading appointments...',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _refreshAppointments,
                    color: const Color(0xFF0029B2),
                    child: _buildAppointmentsList(),
                  ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildConditionalTabs() {
    // Debug the current state when building tabs
    print('🕐 === BUILDING TABS AT ${DateTime.now()} ===');
    _debugAppointmentState();

    final patientId = UserStateManager().currentPatientId;
    final allAppointments =
        _historyService.getAppointments(patientId: patientId);
    final pendingAppointments = _historyService.getAppointmentsByStatus(
      AppointmentStatus.pending,
      patientId: patientId,
    );
    final scheduledAppointments = _historyService.getAppointmentsByStatus(
      AppointmentStatus.scheduled,
      patientId: patientId,
    );
    final completedAppointments = _historyService.getAppointmentsByStatus(
      AppointmentStatus.completed,
      patientId: patientId,
    );
    final cancelledAppointments = _historyService.getAppointmentsByStatus(
      AppointmentStatus.cancelled,
      patientId: patientId,
    );

    print('🔍 Building tabs:');
    print('   All appointments: ${allAppointments.length}');
    print('   Pending appointments: ${pendingAppointments.length}');
    print('   Scheduled appointments: ${scheduledAppointments.length}');
    print('   Completed appointments: ${completedAppointments.length}');
    print('   Cancelled appointments: ${cancelledAppointments.length}');

    // Debug: Show details of pending appointments
    if (pendingAppointments.isNotEmpty) {
      print('   📋 Pending appointment details:');
      for (int i = 0; i < pendingAppointments.length; i++) {
        final apt = pendingAppointments[i];
        print(
            '      $i: ID=${apt.id}, Service=${apt.service}, Status=${apt.status}, Date=${apt.date}');
      }
    }

    List<Widget> tabs = [];

    // Always show "All" tab
    tabs.add(_buildTab('All'));

    // Show "Pending" tab if there are pending appointments
    if (pendingAppointments.isNotEmpty) {
      tabs.add(_buildTab('Pending'));
      print(
          '   ✅ Added Pending tab (${pendingAppointments.length} pending appointments)');
      // Additional debug: show details of pending appointments
      for (int i = 0; i < pendingAppointments.length; i++) {
        final apt = pendingAppointments[i];
        print(
            '      Pending $i: ID="${apt.id}", Service="${apt.service}", Status=${apt.status}');
      }
    } else {
      print('   ❌ No pending appointments, skipping Pending tab');
      print(
          '   🔍 pendingAppointments.isNotEmpty = ${pendingAppointments.isNotEmpty}');
      print('   🔍 pendingAppointments.length = ${pendingAppointments.length}');
    }

    // Show "Scheduled" tab if there are scheduled appointments
    if (scheduledAppointments.isNotEmpty) {
      tabs.add(_buildTab('Scheduled'));
      print('   ✅ Added Scheduled tab');
    }

    // Show "Completed" tab if there are completed appointments
    if (completedAppointments.isNotEmpty) {
      tabs.add(_buildTab('Completed'));
      print('   ✅ Added Completed tab');
    }

    // Show "Cancelled" tab if there are cancelled appointments
    if (cancelledAppointments.isNotEmpty) {
      tabs.add(_buildTab('Cancelled'));
      print('   ✅ Added Cancelled tab');
    }

    print('   📊 Total tabs built: ${tabs.length}');
    return tabs;
  }

  Widget _buildTab(String title) {
    final isSelected = _selectedTab == title;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          print('🔍 Tab "$title" selected');
          setState(() => _selectedTab = title);
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? const Color(0xFF0029B2) : Colors.white70,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppointmentsList() {
    List<dynamic> appointments;
    final patientId = UserStateManager().currentPatientId;

    switch (_selectedTab) {
      case 'Pending':
        appointments = _historyService.getAppointmentsByStatus(
          AppointmentStatus.pending,
          patientId: patientId,
        );
        print(
            'Found ${appointments.length} pending appointments for patient $patientId');
        break;
      case 'Scheduled':
        appointments = _historyService.getAppointmentsByStatus(
          AppointmentStatus.scheduled,
          patientId: patientId,
        );
        print(
            'Found ${appointments.length} scheduled appointments for patient $patientId');
        break;
      case 'Completed':
        appointments = _historyService.getAppointmentsByStatus(
          AppointmentStatus.completed,
          patientId: patientId,
        );
        break;
      case 'Cancelled':
        appointments = _historyService.getAppointmentsByStatus(
          AppointmentStatus.cancelled,
          patientId: patientId,
        );
        break;
      default:
        appointments = _historyService.getAppointments(patientId: patientId);
        print(
            'Found ${appointments.length} total appointments for patient $patientId');
    }

    if (appointments.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: appointments.length,
      itemBuilder: (context, index) {
        final appointment = appointments[index];
        return _buildAppointmentCard(appointment);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No ${_selectedTab.toLowerCase()} appointments',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your appointments will appear here',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AppointmentBookingScreen(),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Book Appointment'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0029B2),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard(dynamic appointment) {
    final statusColor = _getStatusColor(appointment.status);
    final isUpcoming = appointment.date.isAfter(DateTime.now());

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showAppointmentDetails(appointment),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      appointment.service,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      _getStatusDisplayName(appointment.status),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('MMM dd, yyyy').format(appointment.date),
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    appointment.timeSlot,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
              if (appointment.notes != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.note, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          appointment.notes!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _getStatusDisplayName(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.pending:
        return 'Pending Review';
      case AppointmentStatus.scheduled:
        return 'Scheduled';
      case AppointmentStatus.completed:
        return 'Completed';
      case AppointmentStatus.cancelled:
        return 'Cancelled';
      case AppointmentStatus.missed:
        return 'Missed';
      case AppointmentStatus.rescheduled:
        return 'Rescheduled';
      default:
        return 'Unknown';
    }
  }

  Color _getStatusColor(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.pending:
        return const Color(0xFFFF9800);
      case AppointmentStatus.scheduled:
        return const Color(0xFF0029B2);
      case AppointmentStatus.completed:
        return const Color(0xFF005800);
      case AppointmentStatus.cancelled:
        return const Color(0xFFE74C3C);
      case AppointmentStatus.missed:
        return const Color(0xFFFF6B35);
      case AppointmentStatus.rescheduled:
        return const Color(0xFF7B1FA2);
      default:
        return const Color(0xFF666666);
    }
  }

  void _showAppointmentDetails(dynamic appointment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height *
            (MediaQuery.of(context).size.width < 600 ? 0.8 : 0.7),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0029B2), Color(0xFF000074)],
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Appointment Details',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow('Service', appointment.service),
                    _buildDetailRow(
                      'Date',
                      DateFormat('EEEE, MMM dd, yyyy').format(appointment.date),
                    ),
                    _buildDetailRow('Time', appointment.timeSlot),
                    _buildDetailRow(
                      'Status',
                      _getStatusDisplayName(appointment.status),
                    ),
                    if (appointment.notes != null)
                      _buildDetailRow('Notes', appointment.notes!),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 16, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _surveyData;
  bool _isLoadingSurvey = false;

  @override
  void initState() {
    super.initState();
    _loadSurveyStatus();
  }

  Future<void> _loadSurveyStatus() async {
    setState(() => _isLoadingSurvey = true);
    try {
      final surveyData = await ApiService.getDentalSurvey(
        UserStateManager().currentPatientId,
      );
      setState(() {
        _surveyData = surveyData;
        UserStateManager().updateSurveyStatus(surveyData != null);
      });
    } catch (e) {
      print('Error loading survey status: $e');
    } finally {
      setState(() => _isLoadingSurvey = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF0029B2),
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: () async {
              setState(() => _isLoadingSurvey = true);
              try {
                await _loadSurveyStatus();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Profile data refreshed!'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 2),
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to refresh: $e'),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 2),
                  ),
                );
              } finally {
                setState(() => _isLoadingSurvey = false);
              }
            },
            icon: const Icon(Icons.refresh, color: Colors.white, size: 24),
            tooltip: 'Refresh profile data',
          ),
        ],
      ),
      body: _buildProfileContent(),
    );
  }

  Widget _buildProfileContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSurveyStatusCard(),
          const SizedBox(height: 20),
          _buildAccountActionsCard(),
        ],
      ),
    );
  }

  Widget _buildSurveyStatusCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.assignment,
                  color: Color(0xFF0029B2),
                  size: 24,
                ),
                SizedBox(width: 10),
                Text(
                  'Dental Health Assessment',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            if (_isLoadingSurvey)
              const Center(child: CircularProgressIndicator())
            else if (_surveyData != null) ...[
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Assessment Completed',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Last updated: ${_formatDate(_surveyData!['completed_at'])}',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 15),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          _showRetakeSurveyDialog();
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text('Update Assessment'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF0029B2),
                          side: const BorderSide(color: Color(0xFF0029B2)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.warning, color: Colors.orange, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Assessment Required',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Complete your dental health assessment to enable appointment booking and get personalized care.',
                      style: TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                    const SizedBox(height: 15),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const DentalSurveyScreen(),
                            ),
                          ).then((_) => _loadSurveyStatus());
                        },
                        icon: const Icon(Icons.assignment),
                        label: const Text('Complete Assessment'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAccountActionsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Account Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 15),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout'),
              subtitle: const Text('Sign out of your account'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _showLogoutDialog(),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.logout, color: Colors.red, size: 28),
              SizedBox(width: 12),
              Text(
                'Logout',
                style: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: const Text(
            'Are you sure you want to logout from your account?',
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                UserStateManager().logoutClient();
                Navigator.of(context).pop();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => const WelcomeScreen(),
                  ),
                  (Route<dynamic> route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Logout',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showRetakeSurveyDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.assignment, color: Colors.orange, size: 28),
              SizedBox(width: 12),
              Text(
                'Retake Assessment',
                style: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: const Text(
            'Do you want to answer the self-assessment survey again? This will replace your current assessment data.',
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DentalSurveyScreen(),
                  ),
                ).then((_) => _loadSurveyStatus());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Yes, Retake Survey',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return 'Unknown';
    }
  }
}
