import 'package:flutter/material.dart';
import 'patient_notifications_screen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class PatientDashboardWithNotifications extends StatefulWidget {
  final String patientId;
  final String patientToken;

  const PatientDashboardWithNotifications({
    super.key,
    required this.patientId,
    required this.patientToken,
  });

  @override
  State<PatientDashboardWithNotifications> createState() =>
      _PatientDashboardWithNotificationsState();
}

class _PatientDashboardWithNotificationsState
    extends State<PatientDashboardWithNotifications> {
  int _unreadNotifications = 0;
  bool _isLoadingNotifications = true;

  @override
  void initState() {
    super.initState();
    _loadUnreadNotifications();
  }

  Future<void> _loadUnreadNotifications() async {
    try {
      print('🔍 Loading unread notifications for patient: ${widget.patientId}');
      print('🔍 Using token: ${widget.patientToken.substring(0, 20)}...');

      final response = await http.get(
        Uri.parse(
            'http://localhost:3000/api/patients/${widget.patientId}/notifications/unread-count'),
        headers: {
          'Authorization': 'Bearer ${widget.patientToken}',
          'Content-Type': 'application/json',
        },
      );

      print('🔍 Unread notifications response status: ${response.statusCode}');
      print('🔍 Unread notifications response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _unreadNotifications = data['unreadCount'] ?? 0;
          _isLoadingNotifications = false;
        });
        print('✅ Unread notifications count: $_unreadNotifications');
      } else {
        print(
            '❌ Error loading unread notifications: ${response.statusCode} - ${response.body}');
        setState(() {
          _isLoadingNotifications = false;
        });
      }
    } catch (e) {
      print('❌ Exception loading unread notifications: $e');
      setState(() {
        _isLoadingNotifications = false;
      });
    }
  }

  void _navigateToNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PatientNotificationsScreen(
          patientId: widget.patientId,
          patientToken: widget.patientToken,
        ),
      ),
    ).then((_) {
      // Reload unread count when returning from notifications screen
      _loadUnreadNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Patient Dashboard',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF0029B2),
        elevation: 0,
        actions: [
          // Notification Button with Badge
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications, color: Colors.white),
                onPressed: _navigateToNotifications,
              ),
              if (_unreadNotifications > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      _unreadNotifications > 99
                          ? '99+'
                          : _unreadNotifications.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadUnreadNotifications,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.person,
                            size: 32, color: Color(0xFF0029B2)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Welcome back!',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0029B2),
                                ),
                              ),
                              Text(
                                'Patient ID: ${widget.patientId.substring(0, 8)}...',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Quick Actions
                    const Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0029B2),
                      ),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: _buildQuickActionCard(
                            'Book Appointment',
                            Icons.calendar_today,
                            Colors.blue,
                            () {
                              // Navigate to appointment booking
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Navigate to appointment booking')),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildQuickActionCard(
                            'View History',
                            Icons.history,
                            Colors.green,
                            () {
                              // Navigate to treatment history
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('Navigate to treatment history')),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Notifications Section
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: InkWell(
                onTap: _navigateToNotifications,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _unreadNotifications > 0
                              ? Colors.red.withOpacity(0.1)
                              : Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.notifications,
                          color: _unreadNotifications > 0
                              ? Colors.red
                              : Colors.grey,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'Notifications',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (_unreadNotifications > 0) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '$_unreadNotifications new',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _isLoadingNotifications
                                  ? 'Loading...'
                                  : _unreadNotifications > 0
                                      ? 'You have $_unreadNotifications unread notification${_unreadNotifications == 1 ? '' : 's'}'
                                      : 'No new notifications',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.grey[400],
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Recent Appointments Section
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Recent Appointments',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0029B2),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Placeholder for appointments
                    Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.event_note,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No recent appointments',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () {
                              // Navigate to appointments
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Navigate to appointments')),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0029B2),
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('View All Appointments'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
