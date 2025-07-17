import 'package:flutter/material.dart';
// import 'services/database_service.dart';
import 'models/patient.dart';
import 'models/appointment.dart';
import 'models/treatment_record.dart';
import 'models/emergency_record.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  // final _dbService = DatabaseService();
  final _searchController = TextEditingController();

  late TabController _tabController;

  List<Patient> _patients = [];
  List<dynamic> _patientsWithHistory = []; // New: Comprehensive patient history
  List<Appointment> _appointments = [];
  List<TreatmentRecord> _treatmentRecords = [];
  List<EmergencyRecord> _emergencyRecords = [];
  Map<String, int> _dashboardStats = {};
  List<dynamic> _pendingAppointmentsWithSurvey = [];

  bool _isLoading = false;
  String _searchQuery = '';
  String _rejectionReason = '';
  String _approvalNotes = '';

  // Date and time change variables
  DateTime? _selectedNewDate;
  String? _selectedNewTimeSlot;
  bool _isUpdatingDateTime = false;

  // Service change variables
  String? _selectedNewService;
  bool _isUpdatingService = false;

  // Available time slots
  final List<String> _timeSlots = [
    '09:00 AM',
    '10:00 AM',
    '11:00 AM',
    '02:00 PM',
    '03:00 PM',
    '04:00 PM',
  ];

  // Available services
  final List<String> _availableServices = [
    'General Checkup',
    'Teeth Cleaning',
    'Orthodontics',
    'Cosmetic Dentistry',
    'Root Canal',
    'Tooth Extraction',
    'Dental Implants',
    'Teeth Whitening',
  ];

  bool _isLoadingPatients = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadData();
    _fetchPendingAppointmentsWithSurvey();
    _tabController.addListener(() {
      if (_tabController.index == 1) {
        // Patients tab - load comprehensive patient history
        _loadPatientHistory();
      } else if (_tabController.index == 2) {
        // Appointments tab - load pending appointments
        _fetchPendingAppointmentsWithSurvey();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    print('🚀 _loadData() called');
    setState(() => _isLoading = true);

    try {
      // TODO: Replace with dynamic token from admin login
      const adminToken =
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6ImJlNTBjOTAxLTdlZWQtNDIyOC05NzExLTk5OWIwOGEwZTcyZCIsInVzZXJuYW1lIjoiYWRtaW4iLCJ0eXBlIjoiYWRtaW4iLCJpYXQiOjE3NTI2MTAwMDIsImV4cCI6MTc1MzIxNDgwMn0.qqcSLZmigRJVFWGAhnonMMbV3PAlFx3ZxrY8tIky_jc';

      print('📡 Making API call to: http://localhost:3000/api/admin/dashboard');

      // Fetch dashboard data from backend
      final response = await http.get(
        Uri.parse('http://localhost:3000/api/admin/dashboard'),
        headers: {
          'Authorization': 'Bearer $adminToken',
          'Content-Type': 'application/json',
        },
      );

      print('📊 Dashboard API response status: ${response.statusCode}');
      print('📊 Dashboard API response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final stats = data['stats'];

        print('📊 Parsed stats: $stats');

        setState(() {
          _patients = []; // Placeholder for now
          _appointments = []; // Placeholder for now
          _treatmentRecords = []; // Placeholder for now
          _emergencyRecords = []; // Placeholder for now
          _dashboardStats = {
            'total_patients': stats['totalPatients'] ?? 0,
            'scheduled': stats['appointments']?['scheduled'] ?? 0,
            'pending': stats['appointments']?['pending'] ?? 0,
            'rejected': stats['appointments']?['rejected'] ?? 0,
            'active_emergencies': stats['emergencies']?['active'] ?? 0,
            'todays_appointments':
                stats['todaysAppointments'] ?? 0, // <-- Use backend key
          };
        });

        print('📊 Dashboard stats loaded: $_dashboardStats');
      } else {
        throw Exception(
            'Failed to load dashboard data: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error loading dashboard data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading data: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadPatientHistory() async {
    setState(() => _isLoadingPatients = true);

    try {
      // TODO: Replace with dynamic token from admin login
      const adminToken =
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6ImJlNTBjOTAxLTdlZWQtNDIyOC05NzExLTk5OWIwOGEwZTcyZCIsInVzZXJuYW1lIjoiYWRtaW4iLCJ0eXBlIjoiYWRtaW4iLCJpYXQiOjE3NTI2MTAwMDIsImV4cCI6MTc1MzIxNDgwMn0.qqcSLZmigRJVFWGAhnonMMbV3PAlFx3ZxrY8tIky_jc';

      final response = await http.get(
        Uri.parse('http://localhost:3000/api/admin/patients/history'),
        headers: {
          'Authorization': 'Bearer $adminToken',
          'Content-Type': 'application/json',
        },
      );

      print('📊 Patient History API response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _patientsWithHistory = data['patients'] ?? [];
        });
        print('📊 Loaded ${_patientsWithHistory.length} patients with history');
      } else {
        throw Exception(
            'Failed to load patient history: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error loading patient history: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading patient history: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoadingPatients = false);
    }
  }

  Future<void> _searchPatientHistory(String query) async {
    setState(() => _isLoadingPatients = true);

    try {
      const adminToken =
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6ImJlNTBjOTAxLTdlZWQtNDIyOC05NzExLTk5OWIwOGEwZTcyZCIsInVzZXJuYW1lIjoiYWRtaW4iLCJ0eXBlIjoiYWRtaW4iLCJpYXQiOjE3NTI2MTAwMDIsImV4cCI6MTc1MzIxNDgwMn0.qqcSLZmigRJVFWGAhnonMMbV3PAlFx3ZxrY8tIky_jc';

      final response = await http.get(
        Uri.parse(
            'http://localhost:3000/api/admin/patients/history?search=$query'),
        headers: {
          'Authorization': 'Bearer $adminToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _patientsWithHistory = data['patients'] ?? [];
        });
      } else {
        throw Exception('Failed to search patients: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error searching patients: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error searching patients: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoadingPatients = false);
    }
  }

  Future<void> _searchPatients(String query) async {
    setState(() => _searchQuery = query);

    if (query.isEmpty) {
      _loadData();
      return;
    }

    try {
      // final searchResults = await _dbService.searchPatients(query);
      setState(() {
        _patients = []; // Placeholder
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Search failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Date and time change methods
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedNewDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedNewDate) {
      setState(() {
        _selectedNewDate = picked;
      });
    }
  }

  void _selectTimeSlot(String timeSlot) {
    setState(() {
      _selectedNewTimeSlot = timeSlot;
    });
  }

  void _selectService(String service) {
    setState(() {
      _selectedNewService = service;
    });
  }

  Future<void> _updateAppointmentDateTime(dynamic appointment) async {
    if (_selectedNewDate == null || _selectedNewTimeSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select both date and time'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isUpdatingDateTime = true;
    });

    try {
      // TODO: Replace with dynamic token from admin login
      const adminToken =
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6ImJlNTBjOTAxLTdlZWQtNDIyOC05NzExLTk5OWIwOGEwZTcyZCIsInVzZXJuYW1lIjoiYWRtaW4iLCJ0eXBlIjoiYWRtaW4iLCJpYXQiOjE3NTI2MTAwMDIsImV4cCI6MTc1MzIxNDgwMn0.qqcSLZmigRJVFWGAhnonMMbV3PAlFx3ZxrY8tIky_jc';

      final response = await http.put(
        Uri.parse(
            'http://localhost:3000/api/admin/update-appointment-datetime'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $adminToken',
        },
        body: jsonEncode({
          'appointmentId': appointment['appointment_id'],
          'newDate': _selectedNewDate!.toIso8601String().split('T')[0],
          'newTimeSlot': _selectedNewTimeSlot,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appointment date and time updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        // Update local appointment object and refresh UI
        setState(() {
          appointment['booking_date'] = _selectedNewDate?.toIso8601String();
          appointment['appointment_date'] = _selectedNewDate?.toIso8601String();
          appointment['time_slot'] = _selectedNewTimeSlot;
        });
        await _fetchPendingAppointmentsWithSurvey();
        await _refreshAppointmentById(appointment);
        // Do NOT close the dialog
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to update appointment');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating appointment: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isUpdatingDateTime = false;
      });
    }
  }

  Future<void> _updateAppointmentService(dynamic appointment) async {
    if (_selectedNewService == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a service'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isUpdatingService = true;
    });

    try {
      // TODO: Replace with dynamic token from admin login
      const adminToken =
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6ImJlNTBjOTAxLTdlZWQtNDIyOC05NzExLTk5OWIwOGEwZTcyZCIsInVzZXJuYW1lIjoiYWRtaW4iLCJ0eXBlIjoiYWRtaW4iLCJpYXQiOjE3NTI2MTAwMDIsImV4cCI6MTc1MzIxNDgwMn0.qqcSLZmigRJVFWGAhnonMMbV3PAlFx3ZxrY8tIky_jc';

      final response = await http.put(
        Uri.parse('http://localhost:3000/api/admin/update-appointment-service'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $adminToken',
        },
        body: jsonEncode({
          'appointmentId': appointment['appointment_id'],
          'newService': _selectedNewService,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appointment service updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        // Update local appointment object and refresh UI
        setState(() {
          appointment['service'] = _selectedNewService;
        });
        await _fetchPendingAppointmentsWithSurvey();
        await _refreshAppointmentById(appointment);
        // Do NOT close the dialog
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(
            errorData['error'] ?? 'Failed to update appointment service');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating appointment service: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isUpdatingService = false;
      });
    }
  }

  Future<void> _fetchPendingAppointmentsWithSurvey() async {
    try {
      // TODO: Replace with dynamic token from admin login
      const adminToken =
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6ImJlNTBjOTAxLTdlZWQtNDIyOC05NzExLTk5OWIwOGEwZTcyZCIsInVzZXJuYW1lIjoiYWRtaW4iLCJ0eXBlIjoiYWRtaW4iLCJpYXQiOjE3NTI2MTAwMDIsImV4cCI6MTc1MzIxNDgwMn0.qqcSLZmigRJVFWGAhnonMMbV3PAlFx3ZxrY8tIky_jc';

      print(
          'Making API call to: http://localhost:3000/api/admin/pending-appointments');
      print('Using token: ${adminToken.substring(0, 20)}...');

      final response = await http.get(
        Uri.parse('http://localhost:3000/api/admin/pending-appointments'),
        headers: {
          'Authorization': 'Bearer $adminToken',
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('Response data type: ${responseData.runtimeType}');

        if (responseData is List) {
          // API returns array directly
          setState(() {
            _pendingAppointmentsWithSurvey = responseData;
          });
          print(
              'Pending appointments count: ${_pendingAppointmentsWithSurvey.length}');
        } else if (responseData is Map &&
            responseData.containsKey('pendingAppointments')) {
          // API returns object with pendingAppointments key
          setState(() {
            _pendingAppointmentsWithSurvey =
                responseData['pendingAppointments'] ?? [];
          });
          print(
              'Pending appointments count: ${_pendingAppointmentsWithSurvey.length}');
        } else {
          print('Unexpected response format');
          setState(() {
            _pendingAppointmentsWithSurvey = [];
          });
        }
      } else {
        throw Exception(
            'Failed to load pending appointments: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in _fetchPendingAppointmentsWithSurvey: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching pending appointments: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF0029B2),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadData,
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Dashboard'),
            Tab(text: 'Patients'),
            Tab(text: 'Appointments'),
            Tab(text: 'Treatments'),
            Tab(text: 'Emergencies'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildDashboardTab(),
                _buildPatientsTab(),
                _buildAppointmentsTab(),
                _buildTreatmentsTab(),
                _buildEmergenciesTab(),
              ],
            ),
    );
  }

  Widget _buildDashboardTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'System Overview',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF000074),
            ),
          ),
          const SizedBox(height: 20),

          // Statistics Cards
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.5,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: [
              _buildStatCard(
                'Total Patients',
                _dashboardStats['total_patients']?.toString() ?? '0',
                Icons.people,
                Colors.blue,
              ),
              _buildStatCard(
                'Scheduled Appointments',
                _dashboardStats['scheduled']?.toString() ?? '0',
                Icons.schedule,
                Colors.green,
              ),
              _buildStatCard(
                'Active Emergencies',
                _dashboardStats['active_emergencies']?.toString() ?? '0',
                Icons.emergency,
                Colors.red,
              ),
              _buildStatCard(
                "Today's Appointments",
                _dashboardStats['todays_appointments']?.toString() ?? '0',
                Icons.today,
                Colors.orange,
              ),
            ],
          ),

          const SizedBox(height: 30),

          // Recent Activities
          const Text(
            'Recent Activities',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF000074),
            ),
          ),
          const SizedBox(height: 16),

          _buildRecentActivities(),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 32),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivities() {
    // Get recent patients and appointments
    final recentPatients = _patients.take(3).toList();
    final recentAppointments = _appointments.take(3).toList();

    return Column(
      children: [
        ...recentPatients.map(
          (patient) => _buildActivityCard(
            'New Patient Registered',
            patient.fullName,
            Icons.person_add,
            Colors.blue,
            patient.createdAt,
          ),
        ),
        ...recentAppointments.map(
          (appointment) => _buildActivityCard(
            'New Appointment',
            appointment.service,
            Icons.calendar_today,
            Colors.green,
            appointment.createdAt,
          ),
        ),
      ],
    );
  }

  Widget _buildActivityCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    DateTime time,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: Text(
          _formatDateTime(time),
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildPatientsTab() {
    return Column(
      children: [
        // Header with search and refresh
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText:
                        'Search patients by name, email, or serial number...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (query) {
                    if (query.isEmpty) {
                      _loadPatientHistory();
                    } else {
                      _searchPatientHistory(query);
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: _loadPatientHistory,
                icon: _isLoadingPatients
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                tooltip: 'Refresh patient history',
              ),
            ],
          ),
        ),

        // Patients List
        Expanded(
          child: _isLoadingPatients
              ? const Center(child: CircularProgressIndicator())
              : _patientsWithHistory.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_outline,
                              size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'No patients found',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _patientsWithHistory.length,
                      itemBuilder: (context, index) {
                        final patient = _patientsWithHistory[index];
                        return _buildPatientHistoryCard(patient);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildPatientHistoryCard(dynamic patient) {
    final stats = patient['stats'] ?? {};

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF0029B2).withOpacity(0.1),
          child: Text(
            (patient['firstName']?[0] ?? '') + (patient['lastName']?[0] ?? ''),
            style: const TextStyle(
              color: Color(0xFF0029B2),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          patient['fullName'] ?? 'Unknown Patient',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Email: ${patient['email'] ?? 'N/A'}'),
            Text('Phone: ${patient['phone'] ?? 'N/A'}'),
            if (patient['serialNumber']?.isNotEmpty == true)
              Text('Serial: ${patient['serialNumber']}'),
            const SizedBox(height: 8),
            // Activity summary
            Row(
              children: [
                _buildActivityChip('Appointments',
                    stats['totalAppointments'] ?? 0, Colors.blue),
                const SizedBox(width: 8),
                _buildActivityChip('Emergencies',
                    stats['totalEmergencyRecords'] ?? 0, Colors.red),
                const SizedBox(width: 8),
                _buildActivityChip(
                    'Treatments', stats['totalTreatments'] ?? 0, Colors.green),
              ],
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Patient Details Section
                _buildHistorySectionHeader('Patient Information', Icons.person),
                _buildPatientDetailRow(
                    'Classification', patient['classification'] ?? 'N/A'),
                if (patient['otherClassification']?.isNotEmpty == true)
                  _buildPatientDetailRow(
                      'Other Classification', patient['otherClassification']),
                _buildPatientDetailRow(
                    'Unit Assignment', patient['unitAssignment'] ?? 'N/A'),
                _buildPatientDetailRow(
                    'Address', patient['address'] ?? 'Not provided'),
                _buildPatientDetailRow('Emergency Contact',
                    patient['emergencyContact'] ?? 'Not provided'),
                _buildPatientDetailRow('Emergency Phone',
                    patient['emergencyPhone'] ?? 'Not provided'),
                if (patient['medicalHistory']?.isNotEmpty == true)
                  _buildPatientDetailRow(
                      'Medical History', patient['medicalHistory']),
                if (patient['allergies']?.isNotEmpty == true)
                  _buildPatientDetailRow('Allergies', patient['allergies']),
                _buildPatientDetailRow('Registered',
                    _formatDateTime(DateTime.parse(patient['createdAt']))),

                const SizedBox(height: 20),

                // Appointments Section
                if ((patient['appointments'] as List?)?.isNotEmpty == true) ...[
                  _buildHistorySectionHeader(
                      'Appointments (${patient['appointments'].length})',
                      Icons.calendar_today),
                  const SizedBox(height: 8),
                  ...(patient['appointments'] as List)
                      .map((apt) => _buildAppointmentItem(apt))
                      .toList(),
                  const SizedBox(height: 16),
                ],

                // Survey Section
                if (patient['survey'] != null) ...[
                  _buildHistorySectionHeader('Dental Survey', Icons.assignment),
                  const SizedBox(height: 8),
                  _buildSurveyItem(patient['survey']),
                  const SizedBox(height: 16),
                ],

                // Emergency Records Section
                if ((patient['emergencyRecords'] as List?)?.isNotEmpty ==
                    true) ...[
                  _buildHistorySectionHeader(
                      'Emergency Records (${patient['emergencyRecords'].length})',
                      Icons.emergency),
                  const SizedBox(height: 8),
                  ...(patient['emergencyRecords'] as List)
                      .map((emergency) => _buildEmergencyItem(emergency))
                      .toList(),
                  const SizedBox(height: 16),
                ],

                // Treatment Records Section
                if ((patient['treatmentRecords'] as List?)?.isNotEmpty ==
                    true) ...[
                  _buildHistorySectionHeader(
                      'Treatment History (${patient['treatmentRecords'].length})',
                      Icons.medical_services),
                  const SizedBox(height: 8),
                  ...(patient['treatmentRecords'] as List)
                      .map((treatment) => _buildTreatmentItem(treatment))
                      .toList(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        '$label: $count',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildHistorySectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF0029B2), size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0029B2),
          ),
        ),
      ],
    );
  }

  Widget _buildAppointmentItem(dynamic appointment) {
    final status = appointment['status'] ?? 'unknown';
    Color statusColor;
    switch (status) {
      case 'pending':
        statusColor = Colors.orange;
        break;
      case 'scheduled':
        statusColor = Colors.blue;
        break;
      case 'completed':
        statusColor = Colors.green;
        break;
      case 'rejected':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                appointment['service'] ?? 'N/A',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('Date: ${_formatHistoryDate(appointment['appointmentDate'])}'),
          Text('Time: ${appointment['timeSlot'] ?? 'N/A'}'),
          if (appointment['doctorName']?.isNotEmpty == true)
            Text('Doctor: ${appointment['doctorName']}'),
          if (appointment['notes']?.isNotEmpty == true)
            Text('Notes: ${appointment['notes']}'),
        ],
      ),
    );
  }

  Widget _buildSurveyItem(dynamic survey) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Survey Completed',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.blue[700],
            ),
          ),
          const SizedBox(height: 4),
          Text(
              'Completed: ${_formatDateTime(DateTime.parse(survey['completedAt']))}'),
          if (survey['surveyData'] != null) ...[
            const SizedBox(height: 8),
            Text(
              'Survey Data:',
              style: TextStyle(
                  fontWeight: FontWeight.w600, color: Colors.blue[700]),
            ),
            Text(survey['surveyData'].toString()),
          ],
        ],
      ),
    );
  }

  Widget _buildEmergencyItem(dynamic emergency) {
    final urgency = emergency['urgencyLevel'] ?? 'unknown';
    Color urgencyColor;
    switch (urgency) {
      case 'high':
        urgencyColor = Colors.red;
        break;
      case 'medium':
        urgencyColor = Colors.orange;
        break;
      case 'low':
        urgencyColor = Colors.green;
        break;
      default:
        urgencyColor = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pain Level: ${emergency['painLevel'] ?? 'N/A'}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: urgencyColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  urgency.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: urgencyColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('Symptoms: ${emergency['symptoms'] ?? 'N/A'}'),
          Text('Status: ${emergency['status'] ?? 'N/A'}'),
          Text(
              'Created: ${_formatDateTime(DateTime.parse(emergency['createdAt']))}'),
        ],
      ),
    );
  }

  Widget _buildTreatmentItem(dynamic treatment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            treatment['treatmentType'] ?? 'N/A',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text('Description: ${treatment['description'] ?? 'N/A'}'),
          Text('Date: ${_formatHistoryDate(treatment['datePerformed'])}'),
          if (treatment['doctorName']?.isNotEmpty == true)
            Text('Doctor: ${treatment['doctorName']}'),
          if (treatment['notes']?.isNotEmpty == true)
            Text('Notes: ${treatment['notes']}'),
        ],
      ),
    );
  }

  String _formatHistoryDate(dynamic date) {
    if (date == null) return 'N/A';
    try {
      final dateTime = DateTime.parse(date.toString());
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } catch (e) {
      return 'Invalid date';
    }
  }

  Widget _buildPatientCard(Patient patient) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF0029B2).withOpacity(0.1),
          child: Text(
            patient.firstName[0] + patient.lastName[0],
            style: const TextStyle(
              color: Color(0xFF0029B2),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          patient.fullName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Email: ${patient.email}'),
            Text('Phone: ${patient.phone}'),
            if (patient.serialNumber.isNotEmpty)
              Text('Serial: ${patient.serialNumber}'),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPatientDetailRow(
                  'Classification',
                  patient.classification,
                ),
                if (patient.otherClassification.isNotEmpty)
                  _buildPatientDetailRow(
                    'Other Classification',
                    patient.otherClassification,
                  ),
                _buildPatientDetailRow(
                  'Unit Assignment',
                  patient.unitAssignment,
                ),
                _buildPatientDetailRow('Address', patient.address),
                _buildPatientDetailRow(
                  'Emergency Contact',
                  patient.emergencyContact,
                ),
                _buildPatientDetailRow(
                  'Emergency Phone',
                  patient.emergencyPhone,
                ),
                if (patient.medicalHistory.isNotEmpty)
                  _buildPatientDetailRow(
                    'Medical History',
                    patient.medicalHistory,
                  ),
                if (patient.allergies.isNotEmpty)
                  _buildPatientDetailRow('Allergies', patient.allergies),
                _buildPatientDetailRow(
                  'Registered',
                  _formatDateTime(patient.createdAt),
                ),

                const SizedBox(height: 16),

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _viewPatientSurvey(patient),
                      icon: const Icon(Icons.assignment),
                      label: const Text('View Survey'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0029B2),
                        foregroundColor: Colors.white,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _viewPatientAppointments(patient),
                      icon: const Icon(Icons.calendar_today),
                      label: const Text('Appointments'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF000074),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? 'Not provided' : value,
              style: TextStyle(
                color: value.isEmpty ? Colors.grey : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentsTab() {
    // Use the new pending appointments with survey data
    final pendingAppointments = _pendingAppointmentsWithSurvey;
    final otherAppointments = _appointments
        .where((apt) => apt.status != AppointmentStatus.pending)
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pending Appointments Section
          if (pendingAppointments.isNotEmpty) ...[
            Row(
              children: [
                Icon(Icons.pending_actions, color: Colors.orange, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Pending Appointments (${pendingAppointments.length})',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'These appointments require review and approval',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 16),
            ...pendingAppointments.map(
              (appt) => _buildPendingAppointmentWithSurveyCard(appt),
            ),
            const SizedBox(height: 24),
          ],

          // Other Appointments Section
          if (otherAppointments.isNotEmpty) ...[
            const Text(
              'All Appointments',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF000074),
              ),
            ),
            const SizedBox(height: 16),
            ...otherAppointments.map(
              (appointment) => _buildAppointmentCard(appointment),
            ),
          ],

          // Empty State
          if (_appointments.isEmpty) ...[
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_note, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No appointments found',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAppointmentCard(Appointment appointment) {
    Color statusColor;
    switch (appointment.status) {
      case AppointmentStatus.pending:
        statusColor = Colors.orange;
        break;
      case AppointmentStatus.scheduled:
        statusColor = Colors.blue;
        break;
      case AppointmentStatus.completed:
        statusColor = Colors.green;
        break;
      case AppointmentStatus.cancelled:
        statusColor = Colors.red;
        break;
      case AppointmentStatus.missed:
        statusColor = Colors.orange;
        break;
      case AppointmentStatus.rescheduled:
        statusColor = Colors.purple;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  appointment.service,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
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
                  ),
                  child: Text(
                    appointment.status.displayName,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Patient ID: ${appointment.patientId}'),
            Text('Date: ${_formatDate(appointment.date)}'),
            Text('Time: ${appointment.timeSlot}'),
            Text('Doctor: ${appointment.doctorName}'),
            if (appointment.notes != null && appointment.notes!.isNotEmpty)
              Text('Notes: ${appointment.notes}'),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingAppointmentWithSurveyCard(dynamic appt) {
    final survey = appt['survey_data'];
    String name =
        '${appt['first_name'] ?? ''} ${appt['last_name'] ?? ''}'.trim();
    String email = appt['email'] ?? '';
    String header = (name.isNotEmpty || email.isNotEmpty)
        ? '$name${name.isNotEmpty && email.isNotEmpty ? ' - ' : ''}$email'
        : '';
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (header.isNotEmpty)
              Text(
                header,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            const SizedBox(height: 8),
            Text('Appointment ID: ${appt['appointment_id']}'),
            Text('Date: ${_formatDateDisplay(appt['booking_date'])}'),
            Text('Status: ${appt['status']}'),
            const SizedBox(height: 8),
            if (survey != null) ...[
              const Text('Self-Assessment Survey:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              if (survey['patient_info'] != null) ...[
                Text('Name: ${survey['patient_info']['name']}'),
                Text('Contact: ${survey['patient_info']['contact_number']}'),
              ],
              if (survey['tooth_conditions'] != null) ...[
                Text('Tooth Conditions:'),
                ...survey['tooth_conditions']
                    .entries
                    .where((entry) => entry.value == true)
                    .map<Widget>((entry) => Text(
                        '  • ${entry.key.replaceAll('_', ' ').toUpperCase()}'))
                    .toList(),
              ],
            ] else ...[
              const Text('No survey data available',
                  style: TextStyle(color: Colors.grey)),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => _showPatientData(appt),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Proceed'),
                ),
                ElevatedButton(
                  onPressed: () => _rejectAppointment(appt),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Reject'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _approveAppointment(dynamic appointment) async {
    try {
      print('Approving appointment: ${appointment['appointment_id']}');

      // Show confirmation dialog
      bool? confirmed = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Approve Appointment'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Are you sure you want to approve this appointment?'),
                const SizedBox(height: 16),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  onChanged: (value) {
                    // Store the notes
                    _approvalNotes = value;
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Approve'),
              ),
            ],
          );
        },
      );

      if (confirmed == true) {
        // Call the approve API endpoint
        const adminToken =
            'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6ImJlNTBjOTAxLTdlZWQtNDIyOC05NzExLTk5OWIwOGEwZTcyZCIsInVzZXJuYW1lIjoiYWRtaW4iLCJ0eXBlIjoiYWRtaW4iLCJpYXQiOjE3NTI2MTAwMDIsImV4cCI6MTc1MzIxNDgwMn0.qqcSLZmigRJVFWGAhnonMMbV3PAlFx3ZxrY8tIky_jc';

        final response = await http.post(
          Uri.parse(
              'http://localhost:3000/api/admin/appointments/${appointment['appointment_id']}/approve'),
          headers: {
            'Authorization': 'Bearer $adminToken',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'notes': _approvalNotes,
          }),
        );

        print('Approve response status: ${response.statusCode}');
        print('Approve response body: ${response.body}');

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Appointment approved successfully'),
              backgroundColor: Colors.green,
            ),
          );
          _fetchPendingAppointmentsWithSurvey(); // Reload pending appointments
          await _loadData(); // Refresh dashboard stats
        } else {
          throw Exception(
              'Failed to approve appointment: ${response.statusCode}');
        }
      }
    } catch (e) {
      print('Error approving appointment: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to approve appointment: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _rejectAppointment(dynamic appointment) async {
    try {
      print('Rejecting appointment: ${appointment['appointment_id']}');

      // Show confirmation dialog
      bool? confirmed = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Reject Appointment'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Are you sure you want to reject this appointment?'),
                const SizedBox(height: 16),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Reason for rejection (optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  onChanged: (value) {
                    // Store the reason
                    _rejectionReason = value;
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Reject'),
              ),
            ],
          );
        },
      );

      if (confirmed == true) {
        // Call the reject API endpoint
        const adminToken =
            'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6ImJlNTBjOTAxLTdlZWQtNDIyOC05NzExLTk5OWIwOGEwZTcyZCIsInVzZXJuYW1lIjoiYWRtaW4iLCJ0eXBlIjoiYWRtaW4iLCJpYXQiOjE3NTI2MTAwMDIsImV4cCI6MTc1MzIxNDgwMn0.qqcSLZmigRJVFWGAhnonMMbV3PAlFx3ZxrY8tIky_jc';

        final response = await http.post(
          Uri.parse(
              'http://localhost:3000/api/admin/appointments/${appointment['appointment_id']}/reject'),
          headers: {
            'Authorization': 'Bearer $adminToken',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'reason': _rejectionReason,
          }),
        );

        print('Reject response status: ${response.statusCode}');
        print('Reject response body: ${response.body}');

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Appointment rejected successfully'),
              backgroundColor: Colors.green,
            ),
          );
          _fetchPendingAppointmentsWithSurvey(); // Reload pending appointments
        } else {
          throw Exception(
              'Failed to reject appointment: ${response.statusCode}');
        }
      }
    } catch (e) {
      print('Error rejecting appointment: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to reject appointment: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildTreatmentsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _treatmentRecords.length,
      itemBuilder: (context, index) {
        final record = _treatmentRecords[index];
        return _buildTreatmentCard(record);
      },
    );
  }

  Widget _buildTreatmentCard(TreatmentRecord record) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              record.treatmentType,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Patient ID: ${record.patientId}'),
            Text('Date: ${_formatDate(record.treatmentDate)}'),
            Text('Doctor: ${record.doctorName}'),
            Text('Description: ${record.description}'),
            if (record.procedures.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                'Procedures:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              ...record.procedures.map(
                (procedure) => Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Text('• $procedure'),
                ),
              ),
            ],
            if (record.prescription != null && record.prescription!.isNotEmpty)
              Text('Prescription: ${record.prescription}'),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergenciesTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _emergencyRecords.length,
      itemBuilder: (context, index) {
        final record = _emergencyRecords[index];
        return _buildEmergencyCard(record);
      },
    );
  }

  Widget _buildEmergencyCard(EmergencyRecord record) {
    Color priorityColor;
    switch (record.priority) {
      case EmergencyPriority.immediate:
        priorityColor = Colors.red;
        break;
      case EmergencyPriority.urgent:
        priorityColor = Colors.orange;
        break;
      case EmergencyPriority.standard:
        priorityColor = Colors.blue;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  record.emergencyTypeDisplay,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: priorityColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    record.priorityDisplay,
                    style: TextStyle(
                      color: priorityColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Patient ID: ${record.patientId}'),
            Text('Reported: ${_formatDateTime(record.reportedAt)}'),
            Text('Pain Level: ${record.painLevel}/10'),
            Text('Status: ${record.statusDisplay}'),
            Text('Description: ${record.description}'),
            if (record.location != null) Text('Location: ${record.location}'),
            if (record.handledBy != null)
              Text('Handled By: ${record.handledBy}'),
          ],
        ),
      ),
    );
  }

  void _viewPatientSurvey(Patient patient) async {
    try {
      // final survey = await _dbService.getDentalSurvey(patient.id!);
      // if (survey != null) {
      //   _showSurveyDialog(patient, survey);
      // } else {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     const SnackBar(
      //       content: Text('No survey found for this patient'),
      //       backgroundColor: Colors.orange,
      //     ),
      //   );
      // }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading survey: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _viewPatientAppointments(Patient patient) async {
    try {
      // final appointments = await _dbService.getAppointments(
      //   patientId: patient.id!,
      // );
      // _showAppointmentsDialog(patient, appointments);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading appointments: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showSurveyDialog(Patient patient, Map<String, dynamic> survey) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${patient.fullName} - Survey Results'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Completed: ${_formatDateTime(DateTime.parse(survey['completed_at']))}',
              ),
              const SizedBox(height: 16),
              const Text(
                'Survey Data:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(survey['survey_data'].toString()),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAppointmentsDialog(
    Patient patient,
    List<Appointment> appointments,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${patient.fullName} - Appointments'),
        content: SizedBox(
          width: double.maxFinite,
          child: appointments.isEmpty
              ? const Text('No appointments found')
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: appointments.length,
                  itemBuilder: (context, index) {
                    final appointment = appointments[index];
                    return ListTile(
                      title: Text(appointment.service),
                      subtitle: Text(
                        '${_formatDate(appointment.date)} - ${appointment.timeSlot}',
                      ),
                      trailing: Text(appointment.status.displayName),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${_formatDate(dateTime)} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDateDisplay(dynamic date) {
    if (date == null) return 'N/A';
    if (date is DateTime) return _formatDate(date);
    try {
      final dt = DateTime.parse(date.toString());
      // Convert to local timezone to avoid date shifting
      final localDt = dt.toLocal();
      return _formatDate(localDt);
    } catch (_) {
      return date.toString();
    }
  }

  void _showPatientData(dynamic appointment) async {
    try {
      print(
          'Showing patient data for appointment: ${appointment['appointment_id']}');

      // Show patient data dialog with booking and survey information
      _showPatientDataDialog(appointment);
    } catch (e) {
      print('Error showing patient data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading patient data: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showPatientDataDialog(dynamic appointment) {
    // Reset date, time, and service selection when opening dialog
    setState(() {
      _selectedNewDate = null;
      _selectedNewTimeSlot = null;
      _selectedNewService = null;
    });

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  const Icon(Icons.person, color: Color(0xFF0029B2), size: 30),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Patient Data & Assessment',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0029B2),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 10),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date and Time Change Section - MOVED TO TOP
                      _buildSectionHeader('🕒 Change Date & Time', Icons.edit),
                      const SizedBox(height: 10),
                      _buildDateTimeChangeCard(appointment),

                      const SizedBox(height: 20),

                      // Service Change Section - NEW
                      _buildSectionHeader(
                          '🦷 Change Service', Icons.medical_services),
                      const SizedBox(height: 10),
                      _buildServiceChangeCard(appointment),

                      const SizedBox(height: 20),

                      // Booking Information Section
                      _buildSectionHeader(
                          '📅 Booking Information', Icons.calendar_today),
                      const SizedBox(height: 10),
                      _buildInfoCard([
                        _buildInfoRow('Appointment ID',
                            appointment['appointment_id'] ?? 'N/A'),
                        _buildInfoRow(
                            'Service', appointment['service'] ?? 'N/A'),
                        _buildInfoRow(
                            'Date',
                            _formatDateDisplay(appointment['booking_date'] ??
                                appointment['appointment_date'])),
                        _buildInfoRow(
                            'Time Slot', appointment['time_slot'] ?? 'N/A'),
                        _buildInfoRow('Status', appointment['status'] ?? 'N/A'),
                      ]),

                      const SizedBox(height: 20),

                      // Self-Assessment Survey Section
                      _buildSectionHeader(
                          '📋 Self-Assessment Survey (1-8)', Icons.assignment),
                      const SizedBox(height: 10),
                      _buildSurveyDataCard(appointment['survey_data']),

                      const SizedBox(height: 20),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _approveAppointment(appointment),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 15),
                              ),
                              child: const Text('Approve Appointment'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _rejectAppointment(appointment),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 15),
                              ),
                              child: const Text('Reject Appointment'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF0029B2), size: 24),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0029B2),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimeChangeCard(dynamic appointment) {
    String updateButtonLabel;
    if (_selectedNewDate != null && _selectedNewTimeSlot != null) {
      updateButtonLabel = 'Update to '
          '${_selectedNewDate!.day}/${_selectedNewDate!.month}/${_selectedNewDate!.year} at $_selectedNewTimeSlot';
    } else {
      updateButtonLabel = 'Update Date & Time';
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current Appointment Info
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Current Appointment:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Date: ${_formatDateDisplay(appointment['booking_date'] ?? appointment['appointment_date'])}',
                  style: const TextStyle(color: Colors.black54, fontSize: 13),
                ),
                Text(
                  'Time: ${appointment['time_slot'] ?? 'N/A'}',
                  style: const TextStyle(color: Colors.black54, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),

          // New Date and Time Selection
          const Text(
            'Change to:',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.black87,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'New Date:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _selectDate(context),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade300),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              color: Colors.blue.shade600,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _selectedNewDate != null
                                  ? '${_selectedNewDate!.day}/${_selectedNewDate!.month}/${_selectedNewDate!.year}'
                                  : 'Select Date',
                              style: TextStyle(
                                color: _selectedNewDate != null
                                    ? Colors.black87
                                    : Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'New Time:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade300),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedNewTimeSlot,
                          hint: const Text(
                            'Select Time',
                            style: TextStyle(color: Colors.grey),
                          ),
                          isExpanded: true,
                          items: _timeSlots.map((String timeSlot) {
                            return DropdownMenuItem<String>(
                              value: timeSlot,
                              child: Text(
                                timeSlot,
                                style: const TextStyle(color: Colors.black87),
                              ),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              _selectTimeSlot(newValue);
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),

          // Update Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isUpdatingDateTime
                  ? null
                  : () => _updateAppointmentDateTime(appointment),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isUpdatingDateTime
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        SizedBox(width: 8),
                        Text('Updating...'),
                      ],
                    )
                  : Text(
                      updateButtonLabel,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceChangeCard(dynamic appointment) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current Service Info
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Current Service:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Service: ${appointment['service'] ?? 'N/A'}',
                  style: const TextStyle(color: Colors.black54, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),

          // New Service Selection
          const Text(
            'Change to:',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.black87,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade300),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedNewService,
                hint: const Text(
                  'Select New Service',
                  style: TextStyle(color: Colors.grey),
                ),
                isExpanded: true,
                items: _availableServices.map((String service) {
                  return DropdownMenuItem<String>(
                    value: service,
                    child: Text(
                      service,
                      style: const TextStyle(color: Colors.black87),
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    _selectService(newValue);
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 15),

          // Update Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isUpdatingService
                  ? null
                  : () => _updateAppointmentService(appointment),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isUpdatingService
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        SizedBox(width: 8),
                        Text('Updating...'),
                      ],
                    )
                  : const Text(
                      'Update Service',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSurveyDataCard(dynamic surveyData) {
    if (surveyData == null) {
      return _buildInfoCard([
        const Text(
          'No survey data available',
          style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
        ),
      ]);
    }

    List<Widget> surveyItems = [];

    // Parse survey data - it might be a string or already parsed
    Map<String, dynamic> parsedData = {};
    if (surveyData is String) {
      try {
        parsedData = jsonDecode(surveyData);
      } catch (e) {
        parsedData = {'raw_data': surveyData};
      }
    } else if (surveyData is Map) {
      parsedData = Map<String, dynamic>.from(surveyData);
    }

    // Display Patient Information
    if (parsedData['patient_info'] != null) {
      surveyItems.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Patient Information:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              _buildInfoRow('Name',
                  parsedData['patient_info']['name']?.toString() ?? 'N/A'),
              _buildInfoRow(
                  'Serial Number',
                  parsedData['patient_info']['serial_number']?.toString() ??
                      'N/A'),
              _buildInfoRow(
                  'Unit Assignment',
                  parsedData['patient_info']['unit_assignment']?.toString() ??
                      'N/A'),
              _buildInfoRow(
                  'Contact Number',
                  parsedData['patient_info']['contact_number']?.toString() ??
                      'N/A'),
              _buildInfoRow('Email',
                  parsedData['patient_info']['email']?.toString() ?? 'N/A'),
              _buildInfoRow(
                  'Classification',
                  parsedData['patient_info']['classification']?.toString() ??
                      'N/A'),
              if (parsedData['patient_info']['other_classification']
                      ?.toString()
                      .isNotEmpty ==
                  true)
                _buildInfoRow(
                    'Other Classification',
                    parsedData['patient_info']['other_classification']
                            ?.toString() ??
                        'N/A'),
              _buildInfoRow(
                  'Last Dental Visit',
                  parsedData['patient_info']['last_visit']?.toString() ??
                      'N/A'),
            ],
          ),
        ),
      );
    }

    // Display Tooth Conditions
    if (parsedData['tooth_conditions'] != null) {
      surveyItems.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tooth Conditions:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              _buildConditionRow('Decayed Tooth',
                  parsedData['tooth_conditions']['decayed_tooth']),
              _buildConditionRow('Worn Down Tooth',
                  parsedData['tooth_conditions']['worn_down_tooth']),
              _buildConditionRow('Impacted Tooth',
                  parsedData['tooth_conditions']['impacted_tooth']),
            ],
          ),
        ),
      );
    }

    // Display Tartar Level
    if (parsedData['tartar_level'] != null) {
      surveyItems.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tartar Level:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Text(
                  parsedData['tartar_level'].toString(),
                  style: const TextStyle(color: Colors.black54),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Display Tooth Sensitivity
    if (parsedData['tooth_sensitive'] != null) {
      surveyItems.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tooth Sensitivity:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              _buildConditionRow(
                  'Sensitive to hot/cold', parsedData['tooth_sensitive']),
            ],
          ),
        ),
      );
    }

    // Display Damaged Fillings
    if (parsedData['damaged_fillings'] != null) {
      surveyItems.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Damaged Fillings:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              _buildConditionRow('Broken Tooth',
                  parsedData['damaged_fillings']['broken_tooth']),
              _buildConditionRow('Broken Pasta',
                  parsedData['damaged_fillings']['broken_pasta']),
            ],
          ),
        ),
      );
    }

    // Display Missing Teeth (if data exists from previous surveys)
    if (parsedData['has_missing_teeth'] != null) {
      surveyItems.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Missing Teeth:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              _buildConditionRow(
                  'Has missing teeth', parsedData['has_missing_teeth']),
            ],
          ),
        ),
      );
    }

    return _buildInfoCard(surveyItems);
  }

  Widget _buildConditionRow(String label, dynamic value) {
    String displayValue = 'Not answered';
    Color textColor = Colors.grey;

    if (value == true) {
      displayValue = 'Yes';
      textColor = Colors.green;
    } else if (value == false) {
      displayValue = 'No';
      textColor = Colors.red;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              displayValue,
              style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListRow(String label, List<dynamic> items) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label:',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Text(
              items.join(', '),
              style: const TextStyle(color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshAppointmentById(dynamic appointment) async {
    try {
      // TODO: Replace with dynamic token from admin login if needed
      const adminToken =
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6ImJlNTBjOTAxLTdlZWQtNDIyOC05NzExLTk5OWIwOGEwZTcyZCIsInVzZXJuYW1lIjoiYWRtaW4iLCJ0eXBlIjoiYWRtaW4iLCJpYXQiOjE3NTI2MTAwMDIsImV4cCI6MTc1MzIxNDgwMn0.qqcSLZmigRJVFWGAhnonMMbV3PAlFx3ZxrY8tIky_jc';
      final response = await http.get(
        Uri.parse(
            'http://localhost:3000/api/admin/appointment/${appointment['appointment_id']}'),
        headers: {
          'Authorization': 'Bearer $adminToken',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          appointment.clear();
          appointment.addAll(data['appointment'] ?? data);
        });
      }
    } catch (e) {
      print('Error refreshing appointment: $e');
    }
  }
}
