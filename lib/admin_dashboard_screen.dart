import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'models/appointment.dart';
import 'models/patient.dart';
import 'models/treatment_record.dart';
import 'models/emergency_record.dart';
import 'services/history_service.dart';
import 'services/emergency_service.dart';
import 'patient_detail_screen.dart';
import 'admin_survey_detail_screen.dart';
import 'dental_survey_simple.dart';
import 'services/api_service.dart';
import 'user_state_manager.dart';
import 'appointment_history_screen.dart';
import 'qr_scanner_screen.dart';
import 'config/app_config.dart';

class AdminDashboardScreen extends StatefulWidget {
  final int initialTabIndex;

  const AdminDashboardScreen({
    super.key,
    this.initialTabIndex = 0,
  });

  @override
  _AdminDashboardScreenState createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _patients = [];
  Map<String, dynamic> _patientMap = {};
  List<dynamic> _appointments = [];
  List<dynamic> _pendingAppointments = [];
  List<dynamic> _approvedAppointments = [];
  List<TreatmentRecord> _treatmentRecords = [];
  List<EmergencyRecord> _emergencyRecords = [];
  Map<String, dynamic> _dashboardStats = {};

  List<EmergencyRecord> get _filteredEmergencyRecords {
    return _emergencyRecords.where((record) {
      // Filter out resolved emergencies
      if (record.status == EmergencyStatus.resolved) {
        return false;
      }

      // Search by patient name
      final patientData = _patientMap[record.patientId];
      final patientName = patientData != null
          ? '${patientData['firstName'] ?? ''} ${patientData['lastName'] ?? ''}'
              .trim()
              .toLowerCase()
          : 'unknown patient';

      return _emergencySearchQuery.isEmpty ||
          patientName.contains(_emergencySearchQuery.toLowerCase()) ||
          record.emergencyTypeDisplay
              .toLowerCase()
              .contains(_emergencySearchQuery.toLowerCase()) ||
          (record.notes
                  ?.toLowerCase()
                  .contains(_emergencySearchQuery.toLowerCase()) ??
              false);
    }).toList();
  }

  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  final String _selectedNewDate = '';
  final String _selectedNewTimeSlot = '';
  String _approvalNotes = '';
  String _rejectionReason = '';
  String _appointmentSearchQuery = '';
  final TextEditingController _appointmentSearchController =
      TextEditingController();
  String _approvedSearchQuery = '';
  final TextEditingController _approvedSearchController =
      TextEditingController();

  // Emergency tab search
  String _emergencySearchQuery = '';
  final TextEditingController _emergencySearchController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);

    // Add tab change listener to refresh data when appointments tab is selected
    _tabController.addListener(() {
      if (_tabController.index == 1) {
        // Appointments tab (index 1)
        print(
            '🔄 Appointments tab selected - refreshing pending appointments...');
        _fetchPendingAppointmentsWithSurvey();
        _loadApprovedAppointments();
        setState(() {
          // Trigger UI update after data refresh
        });
      } else if (_tabController.index == 2) {
        // Approved tab (index 2)
        print('🔄 Approved tab selected - refreshing approved appointments...');
        _loadApprovedAppointments();
        setState(() {
          // Trigger UI update after data refresh
        });
      }
    });

    _loadData();

    // Set initial tab if specified
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialTabIndex >= 0 && widget.initialTabIndex < 5) {
        _tabController.animateTo(widget.initialTabIndex);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emergencySearchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Initialize emergency service
      EmergencyService().initializeSampleData();

      await Future.wait([
        _loadPatients(),
        _loadAppointments(),
        _fetchPendingAppointmentsWithSurvey(),
        _loadApprovedAppointments(),
        _loadTreatmentRecords(),
        _loadEmergencyRecords(),
        _loadDashboardStats(),
      ]);
    } catch (e) {
      print('Error loading data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadPatients() async {
    try {
      final adminToken = await _getAdminToken();
      if (adminToken == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Authentication required. Please log in again.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      final response = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/admin/patients'),
        headers: {
          'Authorization': 'Bearer $adminToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<dynamic> patients = [];

        // Handle both array and object responses for backward compatibility
        if (data is List) {
          patients = data;
        } else if (data is Map && data.containsKey('patients')) {
          patients = data['patients'] ?? [];
        } else if (data is Map) {
          // If it's a map but doesn't have 'patients' key, try to use it as a single patient
          patients = [data];
        }

        setState(() {
          _patients = patients;
        });

        print('✅ Loaded ${patients.length} patients');
      } else {
        print('❌ Failed to load patients: ${response.statusCode}');
        print('Response body: ${response.body}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to load patients: ${response.statusCode}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error loading patients: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading patients: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _loadAppointments() async {
    try {
      final adminToken = await _getAdminToken();
      if (adminToken == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Authentication required. Please log in again.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      final response = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/admin/appointments'),
        headers: {
          'Authorization': 'Bearer $adminToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<dynamic> appointments = [];

        // Handle both array and object responses for backward compatibility
        if (data is List) {
          appointments = data;
        } else if (data is Map && data.containsKey('appointments')) {
          appointments = data['appointments'] ?? [];
        } else if (data is Map) {
          // If it's a map but doesn't have 'appointments' key, try to use it as a single appointment
          appointments = [data];
        }

        setState(() {
          _appointments = appointments;
        });

        print('✅ Loaded ${appointments.length} appointments');
      } else {
        print('❌ Failed to load appointments: ${response.statusCode}');
        print('Response body: ${response.body}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('Failed to load appointments: ${response.statusCode}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error loading appointments: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading appointments: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _fetchPendingAppointmentsWithSurvey() async {
    try {
      print('🔄 Starting to fetch pending appointments...');
      print(
          '🌐 Using API URL: ${AppConfig.apiBaseUrl}/admin/appointments/pending');
      final adminToken = await _getAdminToken();
      if (adminToken == null) {
        print('❌ Admin token not available for loading pending appointments');
        return;
      }
      print('✅ Admin token available');
      print('🔑 Token preview: ${adminToken.substring(0, 20)}...');

      final response = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/admin/appointments/pending'),
        headers: {
          'Authorization': 'Bearer $adminToken',
          'Content-Type': 'application/json',
        },
      );

      print('📡 Pending appointments response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('📊 Raw response data type: ${data.runtimeType}');
        print('📊 Raw response data: ${data.toString()}');

        List<dynamic> appointments = [];

        // Handle both array and object responses for backward compatibility
        if (data is List) {
          appointments = data;
          print('📋 Using direct array response');
        } else if (data is Map && data.containsKey('pendingAppointments')) {
          appointments = data['pendingAppointments'] ?? [];
          print('📋 Using pendingAppointments from object response');
        } else if (data is Map) {
          // If it's a map but doesn't have 'pendingAppointments' key, try to use it as a single appointment
          appointments = [data];
          print('📋 Using single object as array');
        }

        print('📊 Extracted ${appointments.length} appointments from response');

        setState(() {
          _pendingAppointments = appointments;
          print(
              '🔄 setState() called - updating UI with ${appointments.length} appointments');
        });
        print('✅ Loaded ${_pendingAppointments.length} pending appointments');
        for (var appointment in _pendingAppointments) {
          print(
              '📋 Appointment: ${appointment['patientName']} - ${appointment['service']} - ${appointment['id']}');
        }
        print(
            '🎯 UI should now display ${_pendingAppointments.length} pending appointments');
      } else {
        print('❌ Failed to load pending appointments: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (e) {
      print('❌ Error loading pending appointments: $e');
    }
  }

  Future<void> _loadTreatmentRecords() async {
    setState(() {
      _treatmentRecords = HistoryService().getTreatmentRecords();
    });
  }

  Future<void> _loadApprovedAppointments() async {
    try {
      final adminToken = await _getAdminToken();
      if (adminToken == null) {
        print('❌ Admin token not available for loading approved appointments');
        return;
      }

      // Load both approved and completed appointments
      final response = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/admin/appointments/approved'),
        headers: {
          'Authorization': 'Bearer $adminToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<dynamic> appointments = [];

        // Handle both array and object responses for backward compatibility
        if (data is List) {
          appointments = data;
        } else if (data is Map && data.containsKey('approvedAppointments')) {
          appointments = data['approvedAppointments'] ?? [];
        } else if (data is Map) {
          // If it's a map but doesn't have 'approvedAppointments' key, try to use it as a single appointment
          appointments = [data];
        }

        // Also load completed appointments
        final completedResponse = await http.get(
          Uri.parse('${AppConfig.apiBaseUrl}/admin/appointments/completed'),
          headers: {
            'Authorization': 'Bearer $adminToken',
            'Content-Type': 'application/json',
          },
        );

        List<dynamic> completedAppointments = [];
        if (completedResponse.statusCode == 200) {
          final completedData = jsonDecode(completedResponse.body);
          if (completedData is List) {
            completedAppointments = completedData;
          } else if (completedData is Map &&
              completedData.containsKey('completedAppointments')) {
            completedAppointments =
                completedData['completedAppointments'] ?? [];
          } else if (completedData is Map) {
            completedAppointments = [completedData];
          }
        }

        // Combine both lists
        appointments.addAll(completedAppointments);

        setState(() {
          _approvedAppointments = appointments;
        });
        print(
            '✅ Loaded ${appointments.length - completedAppointments.length} approved appointments and ${completedAppointments.length} completed appointments');
      } else {
        print('❌ Failed to load approved appointments: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (e) {
      print('❌ Error loading approved appointments: $e');
    }
  }

  Future<void> _loadEmergencyRecords() async {
    try {
      final adminToken = await _getAdminToken();
      if (adminToken == null) {
        print('❌ Admin token not available');
        return;
      }

      // Try the new emergency-records endpoint first
      var response = await http.get(
        Uri.parse(
            '${AppConfig.apiBaseUrl}/admin/emergency-records?exclude_resolved=true'),
        headers: {
          'Authorization': 'Bearer $adminToken',
          'Content-Type': 'application/json',
        },
      );

      // If that fails, try the alternative endpoint
      if (response.statusCode != 200) {
        response = await http.get(
          Uri.parse(
              '${AppConfig.apiBaseUrl}/admin/emergency?exclude_resolved=true'),
          headers: {
            'Authorization': 'Bearer $adminToken',
            'Content-Type': 'application/json',
          },
        );
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<dynamic> emergencyData = [];

        // Handle both array and object responses for backward compatibility
        if (data is List) {
          emergencyData = data;
        } else if (data is Map && data.containsKey('emergencyRecords')) {
          emergencyData = data['emergencyRecords'] ?? [];
        } else if (data is Map) {
          // If it's a map but doesn't have 'emergencyRecords' key, try to use it as a single record
          emergencyData = [data];
        }

        setState(() {
          _emergencyRecords = emergencyData.map((record) {
            return EmergencyRecord(
              id: record['id'].toString(),
              patientId: record['patientId'] ?? '',
              reportedAt: DateTime.parse(record['reportedAt']),
              type: _parseEmergencyType(record['emergencyType']),
              priority: _parseEmergencyPriority(record['priority']),
              status: _parseEmergencyStatus(record['status']),
              description: record['description'] ?? '',
              painLevel: record['painLevel'] ?? 0,
              symptoms: List<String>.from(record['symptoms'] ?? []),
              location: record['location'],
              dutyRelated: record['dutyRelated'] ?? false,
              unitCommand: record['unitCommand'],
              handledBy: record['handledBy'],
              firstAidProvided: record['firstAidProvided'],
              resolvedAt: record['resolvedAt'] != null
                  ? DateTime.parse(record['resolvedAt'])
                  : null,
              resolution: record['resolution'],
              followUpRequired: record['followUpRequired'],
              emergencyContact: record['emergencyContact'],
              notes: record['notes'],
            );
          }).toList();
        });

        print(
            '✅ Loaded ${_emergencyRecords.length} emergency records from backend');
      } else {
        print(
            '❌ Failed to load emergency records: ${response.statusCode} - ${response.body}');
        // Fallback to local data if backend fails
        setState(() {
          _emergencyRecords = List.from(EmergencyService().emergencyRecords);
        });
      }
    } catch (e) {
      print('❌ Error loading emergency records: $e');
      // Fallback to local data if there's an error
      setState(() {
        _emergencyRecords = List.from(EmergencyService().emergencyRecords);
      });
    }
  }

  EmergencyType _parseEmergencyType(String? type) {
    switch (type?.toLowerCase()) {
      case 'severe_toothache':
      case 'severetoothache':
        return EmergencyType.severeToothache;
      case 'knocked_out_tooth':
      case 'knockedouttooth':
        return EmergencyType.knockedOutTooth;
      case 'broken_tooth':
      case 'brokentooth':
        return EmergencyType.brokenTooth;
      case 'dental_trauma':
      case 'dentaltrauma':
        return EmergencyType.dentalTrauma;
      case 'abscess':
        return EmergencyType.abscess;
      case 'excessive_bleeding':
      case 'excessivebleeding':
        return EmergencyType.excessiveBleeding;
      case 'lost_filling':
      case 'lostfilling':
        return EmergencyType.lostFilling;
      case 'lost_crown':
      case 'lostcrown':
        return EmergencyType.lostCrown;
      case 'orthodontic_emergency':
      case 'orthodonticemergency':
        return EmergencyType.orthodonticEmergency;
      default:
        return EmergencyType.other;
    }
  }

  EmergencyPriority _parseEmergencyPriority(String? priority) {
    switch (priority?.toLowerCase()) {
      case 'immediate':
        return EmergencyPriority.immediate;
      case 'urgent':
        return EmergencyPriority.urgent;
      case 'standard':
        return EmergencyPriority.standard;
      default:
        return EmergencyPriority.standard;
    }
  }

  EmergencyStatus _parseEmergencyStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'reported':
        return EmergencyStatus.reported;
      case 'triaged':
        return EmergencyStatus.triaged;
      case 'in_progress':
      case 'inprogress':
        return EmergencyStatus.inProgress;
      case 'resolved':
        return EmergencyStatus.resolved;
      case 'referred':
        return EmergencyStatus.referred;
      default:
        return EmergencyStatus.reported;
    }
  }

  Future<void> _loadDashboardStats() async {
    try {
      final adminToken = await _getAdminToken();
      if (adminToken == null) {
        print('❌ Admin token not available for dashboard stats');
        return;
      }

      final response = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/admin/dashboard'),
        headers: {
          'Authorization': 'Bearer $adminToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _dashboardStats = data['stats'] ?? {};
        });
        print('✅ Loaded dashboard stats');
      } else {
        print('❌ Failed to load dashboard stats: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error loading dashboard stats: $e');
    }
  }

  void _showProceedDialog(dynamic appointment, [dynamic survey]) async {
    print('Opening appointment details dialog for: ${appointment['id']}');

    final id = appointment is Appointment ? appointment.id : appointment['id'];
    String service = appointment is Appointment
        ? appointment.service
        : appointment['service'] ?? 'N/A';
    dynamic date = appointment is Appointment
        ? appointment.date
        : appointment['appointmentDate'];
    String timeSlot = appointment is Appointment
        ? appointment.timeSlot
        : appointment['timeSlot'] ?? 'N/A';
    final status =
        appointment is Appointment ? appointment.status : appointment['status'];
    final patientName = appointment is Appointment
        ? (appointment.patientId ?? '')
        : (appointment['patientName'] ?? 'N/A');
    final patientEmail = appointment is Appointment
        ? ''
        : (appointment['patientEmail'] ?? 'N/A');
    final patientPhone = appointment is Appointment
        ? ''
        : (appointment['patientPhone'] ?? 'N/A');
    final notes =
        appointment is Appointment ? appointment.notes : appointment['notes'];

    final effectiveSurvey = survey ??
        ((appointment is Map && (appointment).containsKey('surveyData'))
            ? (appointment)['surveyData']
            : null);

    // Format date for display
    String formattedDate = _formatDate(date);
    DateTime? parsedDate;
    if (date != null) {
      try {
        if (date is String) {
          parsedDate = DateTime.parse(date);
        } else if (date is DateTime) {
          parsedDate = date;
        }
      } catch (e) {
        // Keep formattedDate as set by _formatDate
      }
    }

    bool isEditing = false;
    String localService = service;
    DateTime? localDate = parsedDate;
    String localTimeSlot = timeSlot;
    final appointmentId = id; // Make id accessible in the dialog scope

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Row(
                children: [
                  const Icon(Icons.medical_services, color: Color(0xFF0029B2)),
                  const SizedBox(width: 8),
                  const Text('Appointment Details'),
                  const Spacer(),
                  IconButton(
                    icon: Icon(isEditing ? Icons.save : Icons.edit),
                    onPressed: () {
                      setState(() {
                        isEditing = !isEditing;
                      });
                    },
                    tooltip: isEditing ? 'Save Changes' : 'Edit Appointment',
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Patient Information Section
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.person, color: Color(0xFF0029B2)),
                              SizedBox(width: 8),
                              Text('Patient Information',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Color(0xFF0029B2))),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _buildInfoRow(
                              'Name', patientName, Icons.person_outline),
                          _buildInfoRow('Email', patientEmail, Icons.email),
                          _buildInfoRow('Phone', patientPhone, Icons.phone),
                          _buildInfoRow(
                              'Classification',
                              appointment['patient_classification'] ?? 'N/A',
                              Icons.category),
                          _buildInfoRow(
                              'Unit Assignment',
                              appointment['patient_unit_assignment'] ?? 'N/A',
                              Icons.location_on),
                          _buildInfoRow(
                              'Serial Number',
                              appointment['patient_serial_number'] ?? 'N/A',
                              Icons.badge),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Appointment Information Section
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
                          const Row(
                            children: [
                              Icon(Icons.calendar_today,
                                  color: Color(0xFF0029B2)),
                              SizedBox(width: 8),
                              Text('Appointment Information',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Color(0xFF0029B2))),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (isEditing) ...[
                            // Editable fields
                            DropdownButtonFormField<String>(
                              value:
                                  localService.isNotEmpty ? localService : null,
                              decoration: const InputDecoration(
                                labelText: 'Service',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.medical_services),
                              ),
                              items: [
                                'General Checkup',
                                'Teeth Cleaning',
                                'Orthodontics',
                                'Cosmetic Dentistry',
                                'Root Canal',
                                'Tooth Extraction',
                                'Dental Implants',
                                'Teeth Whitening',
                                'Cavity Filling',
                                'Dental Crown',
                                'Emergency Treatment'
                              ].map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                setState(() {
                                  localService = newValue ?? localService;
                                });
                              },
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: () async {
                                      final DateTime? picked =
                                          await showDatePicker(
                                        context: context,
                                        initialDate:
                                            localDate ?? DateTime.now(),
                                        firstDate: DateTime.now(),
                                        lastDate: DateTime.now()
                                            .add(const Duration(days: 365)),
                                        builder: (context, child) {
                                          return Theme(
                                            data: Theme.of(context).copyWith(
                                              colorScheme:
                                                  const ColorScheme.light(
                                                primary: Color(0xFF0029B2),
                                                onPrimary: Colors.white,
                                                onSurface: Colors.black,
                                              ),
                                            ),
                                            child: child!,
                                          );
                                        },
                                      );
                                      if (picked != null) {
                                        setState(() {
                                          localDate = picked;
                                        });
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 16),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                            color: Colors.grey.shade400),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.calendar_today,
                                              color: Color(0xFF0029B2)),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              localDate != null
                                                  ? '${localDate!.year}-${localDate!.month.toString().padLeft(2, '0')}-${localDate!.day.toString().padLeft(2, '0')}'
                                                  : 'Select Date',
                                              style: TextStyle(
                                                color: localDate != null
                                                    ? Colors.black
                                                    : Colors.grey.shade600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: InkWell(
                                    onTap: () async {
                                      final TimeOfDay? picked =
                                          await showTimePicker(
                                        context: context,
                                        initialTime:
                                            _parseTimeSlot(localTimeSlot),
                                        builder: (context, child) {
                                          return Theme(
                                            data: Theme.of(context).copyWith(
                                              colorScheme:
                                                  const ColorScheme.light(
                                                primary: Color(0xFF0029B2),
                                                onPrimary: Colors.white,
                                                onSurface: Colors.black,
                                              ),
                                            ),
                                            child: child!,
                                          );
                                        },
                                      );
                                      if (picked != null) {
                                        setState(() {
                                          localTimeSlot =
                                              '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                                        });
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 16),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                            color: Colors.grey.shade400),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.access_time,
                                              color: Color(0xFF0029B2)),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              localTimeSlot.isNotEmpty
                                                  ? localTimeSlot
                                                  : 'Select Time',
                                              style: TextStyle(
                                                color: localTimeSlot.isNotEmpty
                                                    ? Colors.black
                                                    : Colors.grey.shade600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ] else ...[
                            // Read-only fields
                            _buildInfoRow('Service', localService,
                                Icons.medical_services),
                            _buildInfoRow(
                                'Date', formattedDate, Icons.calendar_today),
                            _buildInfoRow(
                                'Time', localTimeSlot, Icons.access_time),
                          ],
                          _buildInfoRow('Status', status, Icons.info),
                          if (notes != null && notes.toString().isNotEmpty)
                            _buildInfoRow(
                                'Notes', notes.toString(), Icons.note),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Survey Data Section
                    if (effectiveSurvey != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.quiz, color: Colors.green),
                                SizedBox(width: 8),
                                Text('Patient Self-Assessment Survey',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.green)),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // 1. Patient Information
                            if (effectiveSurvey['patient_info'] != null) ...[
                              Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border:
                                      Border.all(color: Colors.blue.shade200),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(Icons.person,
                                            color: Color(0xFF0029B2)),
                                        SizedBox(width: 8),
                                        Text('1. Patient Information',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                color: Color(0xFF0029B2))),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    if ((effectiveSurvey['patient_info']
                                                ['name'] ??
                                            '')
                                        .isNotEmpty)
                                      _buildInfoRow(
                                          'Name',
                                          effectiveSurvey['patient_info']
                                              ['name']),
                                    if ((effectiveSurvey['patient_info']
                                                ['contact_number'] ??
                                            '')
                                        .isNotEmpty)
                                      _buildInfoRow(
                                          'Contact',
                                          effectiveSurvey['patient_info']
                                              ['contact_number']),
                                    if ((effectiveSurvey['patient_info']
                                                ['email'] ??
                                            '')
                                        .isNotEmpty)
                                      _buildInfoRow(
                                          'Email',
                                          effectiveSurvey['patient_info']
                                              ['email']),
                                    if ((effectiveSurvey['patient_info']
                                                ['serial_number'] ??
                                            '')
                                        .isNotEmpty)
                                      _buildInfoRow(
                                          'Serial Number',
                                          effectiveSurvey['patient_info']
                                              ['serial_number']),
                                    if ((effectiveSurvey['patient_info']
                                                ['unit_assignment'] ??
                                            '')
                                        .isNotEmpty)
                                      _buildInfoRow(
                                          'Unit Assignment',
                                          effectiveSurvey['patient_info']
                                              ['unit_assignment']),
                                    if ((effectiveSurvey['patient_info']
                                                ['classification'] ??
                                            '')
                                        .isNotEmpty)
                                      _buildInfoRow(
                                          'Classification',
                                          effectiveSurvey['patient_info']
                                              ['classification']),
                                    if ((effectiveSurvey['patient_info']
                                                ['other_classification'] ??
                                            '')
                                        .isNotEmpty)
                                      _buildInfoRow(
                                          'Other Classification',
                                          effectiveSurvey['patient_info']
                                              ['other_classification']),
                                    if ((effectiveSurvey['patient_info']
                                                ['last_visit'] ??
                                            '')
                                        .isNotEmpty)
                                      _buildInfoRow(
                                          'Last Dental Visit',
                                          effectiveSurvey['patient_info']
                                              ['last_visit']),
                                    if ((effectiveSurvey['patient_info']
                                                ['emergency_contact'] ??
                                            '')
                                        .isNotEmpty)
                                      _buildInfoRow(
                                          'Emergency Contact',
                                          effectiveSurvey['patient_info']
                                              ['emergency_contact']),
                                    if ((effectiveSurvey['patient_info']
                                                ['emergency_phone'] ??
                                            '')
                                        .isNotEmpty)
                                      _buildInfoRow(
                                          'Emergency Phone',
                                          effectiveSurvey['patient_info']
                                              ['emergency_phone']),
                                  ],
                                ),
                              ),
                            ],

                            // 2. Tooth Conditions
                            if (effectiveSurvey['tooth_conditions'] !=
                                null) ...[
                              Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                  border:
                                      Border.all(color: Colors.grey.shade300),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(Icons.medical_services,
                                            color: Color(0xFF0029B2)),
                                        SizedBox(width: 8),
                                        Text('2. Tooth Conditions',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                color: Color(0xFF0029B2))),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    ...effectiveSurvey['tooth_conditions']
                                        .entries
                                        .where((entry) => entry.value == true)
                                        .map<Widget>((entry) => Padding(
                                              padding: const EdgeInsets.only(
                                                  left: 16, top: 4),
                                              child: Row(
                                                children: [
                                                  const Icon(
                                                      Icons.fiber_manual_record,
                                                      size: 8,
                                                      color: Color(0xFF0029B2)),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Text(
                                                      entry.key
                                                          .replaceAll('_', ' ')
                                                          .toUpperCase(),
                                                      style: const TextStyle(
                                                          fontSize: 14),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ))
                                        .toList(),
                                  ],
                                ),
                              ),
                            ],

                            // 3. Damaged Fillings
                            if (effectiveSurvey['damaged_fillings'] !=
                                null) ...[
                              Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border:
                                      Border.all(color: Colors.blue.shade200),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(Icons.build,
                                            color: Color(0xFF0029B2)),
                                        SizedBox(width: 8),
                                        Text('3. Damaged Fillings',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                color: Color(0xFF0029B2))),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    ...effectiveSurvey['damaged_fillings']
                                        .entries
                                        .where((entry) => entry.value == true)
                                        .map<Widget>((entry) => Padding(
                                              padding: const EdgeInsets.only(
                                                  left: 16, top: 4),
                                              child: Row(
                                                children: [
                                                  const Icon(
                                                      Icons.fiber_manual_record,
                                                      size: 8,
                                                      color: Color(0xFF0029B2)),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Text(
                                                      entry.key
                                                          .replaceAll('_', ' ')
                                                          .toUpperCase(),
                                                      style: const TextStyle(
                                                          fontSize: 14),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ))
                                        .toList(),
                                  ],
                                ),
                              ),
                            ],

                            // 4. Other Dental Information
                            Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(Icons.info,
                                          color: Color(0xFF0029B2)),
                                      SizedBox(width: 8),
                                      Text('4. Other Dental Information',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: Color(0xFF0029B2))),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  if (effectiveSurvey['tartar_level'] != null)
                                    _buildInfoRow('Tartar Level',
                                        effectiveSurvey['tartar_level']),
                                  if (effectiveSurvey['tooth_sensitive'] !=
                                      null)
                                    _buildInfoRow(
                                        'Tooth Sensitivity',
                                        effectiveSurvey['tooth_sensitive'] ==
                                                true
                                            ? 'Yes'
                                            : 'No'),
                                  if (effectiveSurvey['tooth_pain'] != null)
                                    _buildInfoRow(
                                        'Tooth Pain',
                                        effectiveSurvey['tooth_pain'] == true
                                            ? 'Yes'
                                            : 'No'),
                                  if (effectiveSurvey['need_dentures'] != null)
                                    _buildInfoRow(
                                        'Need Dentures',
                                        effectiveSurvey['need_dentures'] == true
                                            ? 'Yes'
                                            : 'No'),
                                  if (effectiveSurvey['has_missing_teeth'] !=
                                      null)
                                    _buildInfoRow(
                                        'Has Missing/Extracted Teeth',
                                        effectiveSurvey['has_missing_teeth'] ==
                                                true
                                            ? 'Yes'
                                            : 'No'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
                if (isEditing) ...[
                  ElevatedButton(
                    onPressed: () async {
                      // Save changes to appointment
                      await _updateAppointment(appointmentId, localService,
                          localDate, localTimeSlot);
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Save Changes'),
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _approveAppointment(dynamic appointment) async {
    try {
      print('✅ Approving appointment: ${appointment['id']}');
      print('📋 Patient: ${appointment['patientName']}');
      print('🦷 Service: ${appointment['service']}');
      bool? confirmed = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Approve Appointment'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                    'Are you sure you want to approve this appointment?'),
                const SizedBox(height: 16),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  onChanged: (value) {
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
        final adminToken = await _getAdminToken();
        if (adminToken == null) {
          throw Exception(
              'Admin token not available for approving appointment');
        }

        final response = await http.post(
          Uri.parse(
              '${AppConfig.apiBaseUrl}/admin/appointments/${appointment['id']}/approve'),
          headers: {
            'Authorization': 'Bearer $adminToken',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'notes': _approvalNotes,
          }),
        );
        print('📊 Approve response status: ${response.statusCode}');
        print('📊 Approve response body: ${response.body}');
        if (response.statusCode == 200) {
          print('✅ Appointment approved successfully!');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Appointment approved successfully - Redirecting to Approved'),
                backgroundColor: Colors.green),
          );

          // Clear approval notes
          _approvalNotes = '';

          // Immediately remove the approved appointment from pending list
          setState(() {
            _pendingAppointments
                .removeWhere((apt) => apt['id'] == appointment['id']);
          });

          // Refresh data and switch tabs
          await _refreshAfterApproval();

          final treatmentRecord = TreatmentRecord(
            id: 'tr_${DateTime.now().millisecondsSinceEpoch}',
            patientId: appointment['patientId'] ?? '',
            appointmentId: appointment['id'] ?? '',
            treatmentType: appointment['service'] ?? 'General Treatment',
            description:
                'Treatment for ${appointment['service'] ?? 'General Treatment'}',
            treatmentDate:
                DateTime.tryParse(appointment['appointmentDate'] ?? '') ??
                    DateTime.now(),
            procedures: [],
            notes: _approvalNotes.isNotEmpty ? _approvalNotes : null,
            prescription: null,
          );
          HistoryService().addTreatmentRecord(treatmentRecord);
          setState(() {
            _treatmentRecords = HistoryService().getTreatmentRecords();
          });
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

  Future<void> _markAppointmentCompleted(dynamic appointment) async {
    try {
      print(
          '✅ Marking appointment as completed: ${appointment['appointmentId']}');
      print('📋 Patient: ${appointment['patientName']}');
      print('🦷 Service: ${appointment['service']}');

      bool? confirmed = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Mark Appointment Complete'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                    'Are you sure you want to mark this appointment as completed?'),
                const SizedBox(height: 16),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Treatment notes (optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  onChanged: (value) {
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
                child: const Text('Mark Complete'),
              ),
            ],
          );
        },
      );

      if (confirmed == true) {
        final adminToken = await _getAdminToken();
        if (adminToken == null) {
          throw Exception(
              'Admin token not available for marking appointment complete');
        }

        final response = await http.put(
          Uri.parse(
              '${AppConfig.apiBaseUrl}/admin/appointments/${appointment['appointmentId']}/status'),
          headers: {
            'Authorization': 'Bearer $adminToken',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'status': 'completed',
            'notes': _approvalNotes,
          }),
        );

        print('📊 Complete response status: ${response.statusCode}');
        print('📊 Complete response body: ${response.body}');

        if (response.statusCode == 200) {
          print('✅ Appointment marked as completed successfully!');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Appointment marked as completed'),
              backgroundColor: Colors.green,
            ),
          );
          // Refresh only the approved appointments list
          await _loadApprovedAppointments();
          // Also refresh pending appointments in case there are any updates
          await _fetchPendingAppointmentsWithSurvey();
        } else {
          throw Exception(
              'Failed to mark appointment as completed: ${response.statusCode}');
        }
      }
    } catch (e) {
      print('Error marking appointment as completed: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Failed to mark appointment as completed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _cancelAppointment(dynamic appointment) async {
    try {
      print('❌ Cancelling appointment: ${appointment['appointmentId']}');
      print('📋 Patient: ${appointment['patientName']}');
      print('🦷 Service: ${appointment['service']}');

      // Show dialog to get cancellation note
      String? cancellationNote;
      bool? confirmed = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Cancel Appointment'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Are you sure you want to cancel this appointment?'),
                const SizedBox(height: 16),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Cancellation Note (Optional)',
                    hintText: 'Enter reason for cancellation...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  onChanged: (value) {
                    cancellationNote = value;
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
                child: const Text('Confirm Cancel'),
              ),
            ],
          );
        },
      );

      if (confirmed == true) {
        final adminToken = await _getAdminToken();
        if (adminToken == null) {
          throw Exception(
              'Admin token not available for cancelling appointment');
        }

        final response = await http.post(
          Uri.parse(
              '${AppConfig.apiBaseUrl}/admin/appointments/${appointment['appointmentId']}/cancel'),
          headers: {
            'Authorization': 'Bearer $adminToken',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'note': cancellationNote ?? ''}),
        );

        print('📊 Cancel response status: ${response.statusCode}');
        print('📊 Cancel response body: ${response.body}');

        if (response.statusCode == 200) {
          print('✅ Appointment cancelled successfully!');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Appointment cancelled and patient notified'),
              backgroundColor: Colors.green,
            ),
          );
          // Refresh the approved appointments list
          await _loadApprovedAppointments();
        } else {
          throw Exception(
              'Failed to cancel appointment: ${response.statusCode}');
        }
      }
    } catch (e) {
      print('Error cancelling appointment: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to cancel appointment: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _refreshAfterApproval() async {
    try {
      print('🔄 Refreshing data after approval...');

      // Small delay to ensure backend has processed the status change
      await Future.delayed(const Duration(milliseconds: 500));

      // Refresh pending appointments first
      await _fetchPendingAppointmentsWithSurvey();

      // Refresh approved appointments
      await _loadApprovedAppointments();

      // Force a setState to update the UI immediately
      setState(() {
        // This will trigger a rebuild of the UI
      });

      // Switch to Approved tab after data is refreshed
      if (_tabController.length > 2) {
        _tabController.animateTo(2); // Switch to Approved tab
      }

      print('✅ Data refresh completed');
    } catch (e) {
      print('❌ Error refreshing data after approval: $e');
    }
  }

  Future<void> _refreshAfterRejection() async {
    try {
      print('🔄 Refreshing data after rejection...');

      // Small delay to ensure backend has processed the status change
      await Future.delayed(const Duration(milliseconds: 500));

      // Refresh pending appointments
      await _fetchPendingAppointmentsWithSurvey();

      // Refresh all data
      await _loadData();

      print('✅ Data refresh completed after rejection');
    } catch (e) {
      print('❌ Error refreshing data after rejection: $e');
    }
  }

  Future<void> _rejectAppointment(dynamic appointment) async {
    try {
      print('❌ Rejecting appointment: ${appointment['id']}');
      print('📋 Patient: ${appointment['patientName']}');
      print('🦷 Service: ${appointment['service']}');
      bool? confirmed = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Reject Appointment'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Are you sure you want to reject this appointment?'),
                const SizedBox(height: 16),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Reason for rejection (optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  onChanged: (value) {
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
        final adminToken = await _getAdminToken();
        if (adminToken == null) {
          throw Exception(
              'Admin token not available for rejecting appointment');
        }

        final response = await http.post(
          Uri.parse(
              '${AppConfig.apiBaseUrl}/admin/appointments/${appointment['id']}/reject'),
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
                backgroundColor: Colors.orange),
          );

          // Clear rejection reason
          _rejectionReason = '';

          // Immediately remove the rejected appointment from pending list
          setState(() {
            _pendingAppointments
                .removeWhere((apt) => apt['id'] == appointment['id']);
          });

          // Refresh data after rejection
          await _refreshAfterRejection();
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

  Future<void> _updateAppointment(String appointmentId, String service,
      DateTime? date, String timeSlot) async {
    try {
      print('🔄 Updating appointment: $appointmentId');
      print('📋 New service: $service');
      print('📅 New date: $date');
      print('⏰ New time: $timeSlot');

      final adminToken = await _getAdminToken();
      if (adminToken == null) {
        throw Exception('Admin token not available for updating appointment');
      }

      final response = await http.put(
        Uri.parse(
            '${AppConfig.apiBaseUrl}/admin/appointments/$appointmentId/update'),
        headers: {
          'Authorization': 'Bearer $adminToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'service': service,
          'date': date != null
              ? '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}'
              : null,
          'time_slot': timeSlot,
        }),
      );

      print('📊 Update response status: ${response.statusCode}');
      print('📊 Update response body: ${response.body}');

      if (response.statusCode == 200) {
        print('✅ Appointment updated successfully!');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appointment updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _fetchPendingAppointmentsWithSurvey();
        await _loadData();
      } else {
        throw Exception('Failed to update appointment: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error updating appointment: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update appointment: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildDashboardTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // QR Scanner Card
          Card(
            elevation: 4,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const QRScannerScreen(),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0029B2), Color(0xFF001B8A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.qr_code_scanner,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'QR Code Scanner',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Scan patient QR codes and appointment receipts',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Dashboard Overview',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Total Patients',
                          _patients.length.toString(),
                          Icons.people,
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          'Total Appointments',
                          _appointments.length.toString(),
                          Icons.calendar_today,
                          Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Pending Appointments',
                          _pendingAppointments.length.toString(),
                          Icons.pending,
                          Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          "Today's Appointments",
                          (_dashboardStats['todaysAppointments'] ?? 0)
                              .toString(),
                          Icons.today,
                          Colors.purple,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Approved Appointments',
                          _approvedAppointments
                              .where((app) => app['status'] == 'approved')
                              .length
                              .toString(),
                          Icons.medical_services,
                          Colors.teal,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          'Emergency Records',
                          (_dashboardStats['totalEmergencyRecords'] ?? 0)
                              .toString(),
                          Icons.emergency,
                          Colors.red,
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
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, [IconData? icon]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 8),
          ],
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  TimeOfDay _parseTimeSlot(String timeSlot) {
    try {
      if (timeSlot.isEmpty) return const TimeOfDay(hour: 9, minute: 0);

      // Handle different time formats
      if (timeSlot.contains(':')) {
        final parts = timeSlot.split(':');
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        return TimeOfDay(hour: hour, minute: minute);
      } else if (timeSlot.contains(' ')) {
        // Handle "9:00 AM" format
        final parts = timeSlot.split(' ');
        final timePart = parts[0];
        final ampm = parts[1].toUpperCase();
        final timeParts = timePart.split(':');
        int hour = int.parse(timeParts[0]);
        final minute = int.parse(timeParts[1]);

        if (ampm == 'PM' && hour != 12) hour += 12;
        if (ampm == 'AM' && hour == 12) hour = 0;

        return TimeOfDay(hour: hour, minute: minute);
      }
    } catch (e) {
      print('Error parsing time slot: $timeSlot - $e');
    }

    return const TimeOfDay(hour: 9, minute: 0);
  }

  Widget _buildPatientsTab() {
    final filteredPatients = _patients.where((patient) {
      final name = (patient['fullName'] ??
              '${patient['firstName'] ?? ''} ${patient['lastName'] ?? ''}')
          .toLowerCase();
      final email = (patient['email'] ?? '').toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || email.contains(query);
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search patients by name or email...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredPatients.length,
            itemBuilder: (context, index) {
              final patient = filteredPatients[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ExpansionTile(
                  title: Text(
                    patient['fullName'] ??
                        '${patient['firstName'] ?? ''} ${patient['lastName'] ?? ''}'
                            .trim(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(patient['email'] ?? 'No email'),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow('Classification',
                              patient['classification'] ?? 'none'),
                          _buildInfoRow(
                              'Serial Number',
                              (patient['serialNumber'] ?? '')
                                      .toString()
                                      .isNotEmpty
                                  ? patient['serialNumber']
                                  : 'none'),
                          _buildInfoRow(
                              'Unit Assignment',
                              (patient['unitAssignment'] ?? '')
                                      .toString()
                                      .isNotEmpty
                                  ? patient['unitAssignment']
                                  : 'none'),
                          _buildInfoRow('Number', patient['phone'] ?? 'none'),
                          _buildInfoRow('Email', patient['email'] ?? 'none'),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      PatientDetailScreen(patient: patient),
                                ),
                              );
                            },
                            icon: const Icon(Icons.history, size: 16),
                            label: const Text('Details'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              textStyle: const TextStyle(fontSize: 14),
                            ),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: () {
                              _showSurveyDetailsDialog(context, patient['id']);
                            },
                            icon: const Icon(Icons.assignment, size: 16),
                            label: const Text('Survey Details'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              textStyle: const TextStyle(fontSize: 14),
                            ),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: () async {
                              final patientId =
                                  patient['id'] ?? patient['patientId'];
                              print(
                                  'Appointment History button pressed for patientId: $patientId');
                              if (patientId == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('No patient ID found!')),
                                );
                                return;
                              }
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (context) => const Center(
                                    child: CircularProgressIndicator()),
                              );
                              try {
                                final appointments =
                                    await ApiService.getAppointmentsAsAdmin(
                                        patientId);
                                Navigator.of(context)
                                    .pop(); // Remove loading dialog
                                final patientWithAppointments =
                                    Map<String, dynamic>.from(patient);
                                patientWithAppointments['appointments'] =
                                    appointments;
                                print(
                                    'Navigating to AppointmentHistoryScreen with ${appointments.length} appointments');
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        AppointmentHistoryScreen(
                                            patient: patientWithAppointments),
                                  ),
                                );
                              } catch (e) {
                                Navigator.of(context)
                                    .pop(); // Remove loading dialog
                                print('Error fetching appointments: $e');
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Error'),
                                    content: Text(
                                        'Failed to load appointment history:\n$e'),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(),
                                        child: const Text('OK'),
                                      ),
                                    ],
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.event, size: 16),
                            label: const Text('Appointment History'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueGrey,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              textStyle: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAppointmentsTab() {
    final filteredAppointments = _pendingAppointments.where((app) {
      final query = _appointmentSearchQuery.toLowerCase();
      return app['patientName']?.toLowerCase().contains(query) == true ||
          app['patientEmail']?.toLowerCase().contains(query) == true ||
          app['patientClassification']?.toLowerCase().contains(query) == true;
    }).toList();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: TextField(
              controller: _appointmentSearchController,
              decoration: InputDecoration(
                hintText:
                    'Search appointments by name, email, or classification',
                prefixIcon: const Icon(Icons.search),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                suffixIcon: _appointmentSearchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _appointmentSearchQuery = '';
                            _appointmentSearchController.clear();
                          });
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() {
                  _appointmentSearchQuery = value;
                });
              },
            ),
          ),
          // Header with count and summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.pending, color: Colors.orange, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pending Appointments',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade800,
                            ),
                          ),
                          Text(
                            '${_pendingAppointments.length} appointment${_pendingAppointments.length == 1 ? '' : 's'} waiting for approval',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.orange.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () async {
                        print('🔄 Manual refresh of pending appointments...');
                        await _fetchPendingAppointmentsWithSurvey();
                        setState(() {
                          // Trigger UI update
                        });
                      },
                      icon: const Icon(Icons.refresh, color: Colors.orange),
                      tooltip: 'Refresh Pending Appointments',
                    ),
                  ],
                ),
                if (_pendingAppointments.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildSummaryItem(
                            'Today',
                            _pendingAppointments
                                .where((app) {
                                  try {
                                    final date = DateTime.parse(
                                        app['appointmentDate'] ?? '');
                                    final today = DateTime.now();
                                    return date.year == today.year &&
                                        date.month == today.month &&
                                        date.day == today.day;
                                  } catch (e) {
                                    return false;
                                  }
                                })
                                .length
                                .toString(),
                            Icons.today,
                            Colors.blue,
                          ),
                        ),
                        Expanded(
                          child: _buildSummaryItem(
                            'This Week',
                            _pendingAppointments
                                .where((app) {
                                  try {
                                    final date = DateTime.parse(
                                        app['appointmentDate'] ?? '');
                                    final now = DateTime.now();
                                    final weekStart = now.subtract(
                                        Duration(days: now.weekday - 1));
                                    final weekEnd =
                                        weekStart.add(const Duration(days: 6));
                                    return date.isAfter(weekStart.subtract(
                                            const Duration(days: 1))) &&
                                        date.isBefore(weekEnd
                                            .add(const Duration(days: 1)));
                                  } catch (e) {
                                    return false;
                                  }
                                })
                                .length
                                .toString(),
                            Icons.calendar_view_week,
                            Colors.green,
                          ),
                        ),
                        Expanded(
                          child: _buildSummaryItem(
                            'With Survey',
                            _pendingAppointments
                                .where((app) => app['hasSurveyData'] == true)
                                .length
                                .toString(),
                            Icons.assessment,
                            Colors.purple,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (filteredAppointments.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.check_circle_outline,
                      size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'No Pending Appointments',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'All appointments have been processed',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            )
          else
            ...filteredAppointments.map(
              (appointment) => Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 2,
                child: ExpansionTile(
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appointment['patientName'] ?? 'Unknown Patient',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        'Classification: ${appointment['patientClassification'] ?? 'N/A'}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      Text(
                        'ID: ${appointment['id'] ?? 'N/A'}',
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow(
                              'Date',
                              _formatDate(appointment['appointmentDate'] ??
                                  appointment['date'])),
                          _buildInfoRow(
                              'Time', appointment['timeSlot'] ?? 'Unknown'),
                          _buildInfoRow('Classification',
                              appointment['patientClassification'] ?? 'N/A'),
                          _buildInfoRow(
                              'Unit Assignment',
                              appointment['patientOtherClassification'] ??
                                  'N/A'),
                          _buildInfoRow(
                              'Serial Number',
                              appointment['patientOtherClassification'] ??
                                  'N/A'),
                          if (appointment['patientEmail'] != null)
                            _buildInfoRow('Email', appointment['patientEmail']),
                          if (appointment['patientPhone'] != null)
                            _buildInfoRow('Phone', appointment['patientPhone']),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    _showProceedDialog(appointment);
                                  },
                                  icon: const Icon(Icons.visibility, size: 16),
                                  label: const Text('View Details'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    _approveAppointment(appointment);
                                  },
                                  icon: const Icon(Icons.check, size: 16),
                                  label: const Text('Approve'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    _rejectAppointment(appointment);
                                  },
                                  icon: const Icon(Icons.close, size: 16),
                                  label: const Text('Reject'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                  ),
                                ),
                              ),
                            ],
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
    );
  }

  Widget _buildTreatmentsTab() {
    // Separate approved and completed appointments
    final approvedAppointments = _approvedAppointments
        .where((app) => app['status'] == 'approved')
        .toList();
    final completedAppointments = _approvedAppointments
        .where((app) => app['status'] == 'completed')
        .toList();

    final filteredApproved = approvedAppointments.where((app) {
      final query = _approvedSearchQuery.toLowerCase();
      return (app['patientName']?.toLowerCase().contains(query) == true) ||
          (app['service']?.toLowerCase().contains(query) == true) ||
          (app['status']?.toLowerCase().contains(query) == true);
    }).toList();
    if (approvedAppointments.isEmpty && completedAppointments.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Text(
            'No approved or completed appointments',
            style: TextStyle(
              fontSize: 20,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    } else {
      return Column(
        children: [
          // Search bar and refresh button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _approvedSearchController,
                    decoration: InputDecoration(
                      hintText: 'Search approved by name, service, or status',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      suffixIcon: _approvedSearchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                setState(() {
                                  _approvedSearchQuery = '';
                                  _approvedSearchController.clear();
                                });
                              },
                            )
                          : null,
                    ),
                    onChanged: (value) {
                      setState(() {
                        _approvedSearchQuery = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () async {
                    print('🔄 Manual refresh of approved appointments...');
                    await _loadApprovedAppointments();
                    setState(() {
                      // Trigger UI update
                    });
                  },
                  icon: const Icon(Icons.refresh, color: Colors.teal),
                  tooltip: 'Refresh Approved Appointments',
                ),
              ],
            ),
          ),
          Expanded(
            child: filteredApproved.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Text(
                        'No approved appointments',
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredApproved.length,
                    itemBuilder: (context, index) {
                      final appointment = filteredApproved[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        elevation: 2,
                        child: ExpansionTile(
                          title: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.check_circle,
                                color: Colors.teal),
                            title: Text(appointment['patientName'] ??
                                'Unknown Patient'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    'Service: ${appointment['service'] ?? 'N/A'}'),
                                Text(
                                    'Date: ${_formatDate(appointment['appointmentDate'])}'),
                                Text(
                                    'Time: ${appointment['timeSlot'] ?? 'N/A'}'),
                                Text(
                                    'Status: ${appointment['status'] ?? 'N/A'}'),
                              ],
                            ),
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () async {
                                      final confirmed = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title:
                                              const Text('Mark as Completed'),
                                          content: const Text(
                                              'Are you sure you want to mark this appointment as completed?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.of(context)
                                                      .pop(false),
                                              child: const Text('Cancel'),
                                            ),
                                            ElevatedButton(
                                              onPressed: () =>
                                                  Navigator.of(context)
                                                      .pop(true),
                                              child: const Text('Confirm'),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (confirmed == true) {
                                        // Mark as completed in backend
                                        await _markAppointmentCompleted(
                                            appointment);
                                        // The backend refresh will handle the state update
                                        // Add to patient's appointment history in _patients
                                        final patientId =
                                            appointment['patientId'] ??
                                                appointment['patient_id'];
                                        if (patientId != null) {
                                          final patientIndex =
                                              _patients.indexWhere((p) =>
                                                  (p['id'] ?? p['patientId']) ==
                                                  (patientId));
                                          if (patientIndex != -1) {
                                            final patient =
                                                _patients[patientIndex];
                                            final appointmentsList =
                                                (patient['appointments']
                                                        as List?) ??
                                                    [];
                                            // Avoid duplicate by checking id
                                            if (!appointmentsList.any((a) =>
                                                a['id'] ==
                                                    appointment[
                                                        'appointmentId'] ||
                                                a['appointmentId'] ==
                                                    appointment[
                                                        'appointmentId'])) {
                                              final completedAppointment =
                                                  Map<String, dynamic>.from(
                                                      appointment);
                                              completedAppointment['status'] =
                                                  'completed';
                                              appointmentsList
                                                  .add(completedAppointment);
                                              patient['appointments'] =
                                                  appointmentsList;
                                              setState(() {
                                                _patients[patientIndex] =
                                                    patient;
                                              });
                                            }
                                          }
                                        }
                                        // Fetch patientId and navigate to appointment history
                                        if (patientId != null) {
                                          showDialog(
                                            context: context,
                                            barrierDismissible: false,
                                            builder: (context) => const Center(
                                                child:
                                                    CircularProgressIndicator()),
                                          );
                                          try {
                                            final appointments =
                                                await ApiService
                                                    .getAppointmentsAsAdmin(
                                                        patientId);
                                            Navigator.of(context)
                                                .pop(); // Remove loading dialog
                                            final patientWithAppointments = {
                                              'appointments': appointments,
                                              'fullName':
                                                  appointment['patientName'] ??
                                                      ''
                                            };
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    AppointmentHistoryScreen(
                                                        patient:
                                                            patientWithAppointments),
                                              ),
                                            );
                                          } catch (e) {
                                            Navigator.of(context).pop();
                                            showDialog(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                title: const Text('Error'),
                                                content: Text(
                                                    'Failed to load appointment history:\n$e'),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.of(context)
                                                            .pop(),
                                                    child: const Text('OK'),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }
                                        }
                                      }
                                    },
                                    icon: const Icon(Icons.check, size: 16),
                                    label: const Text('Completed'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ElevatedButton.icon(
                                    onPressed: () async {
                                      DateTime? newDate;
                                      TimeOfDay? newTime;
                                      final serviceController =
                                          TextEditingController(
                                              text:
                                                  appointment['service'] ?? '');
                                      final confirmed = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => StatefulBuilder(
                                          builder: (context, setState) =>
                                              AlertDialog(
                                            title: const Text(
                                                'Re-book Appointment'),
                                            content: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                TextField(
                                                  controller: serviceController,
                                                  decoration:
                                                      const InputDecoration(
                                                    labelText: 'Service',
                                                    border:
                                                        OutlineInputBorder(),
                                                  ),
                                                ),
                                                const SizedBox(height: 12),
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: OutlinedButton(
                                                        onPressed: () async {
                                                          final picked =
                                                              await showDatePicker(
                                                            context: context,
                                                            initialDate: DateTime.tryParse(
                                                                    appointment[
                                                                            'appointmentDate'] ??
                                                                        '') ??
                                                                DateTime.now(),
                                                            firstDate:
                                                                DateTime.now(),
                                                            lastDate: DateTime
                                                                    .now()
                                                                .add(const Duration(
                                                                    days: 365)),
                                                          );
                                                          if (picked != null) {
                                                            setState(() =>
                                                                newDate =
                                                                    picked);
                                                          }
                                                        },
                                                        child: Text(newDate !=
                                                                null
                                                            ? 'Date: \\${newDate!.toLocal().toString().split(' ')[0]}'
                                                            : 'Pick new date'),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: OutlinedButton(
                                                        onPressed: () async {
                                                          final picked =
                                                              await showTimePicker(
                                                            context: context,
                                                            initialTime: TimeOfDay
                                                                .fromDateTime(
                                                              DateTime.tryParse(
                                                                      appointment[
                                                                              'appointmentDate'] ??
                                                                          '') ??
                                                                  DateTime
                                                                      .now(),
                                                            ),
                                                          );
                                                          if (picked != null) {
                                                            setState(() =>
                                                                newTime =
                                                                    picked);
                                                          }
                                                        },
                                                        child: Text(newTime !=
                                                                null
                                                            ? 'Time: \\${newTime!.format(context)}'
                                                            : 'Pick new time'),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.of(context)
                                                        .pop(false),
                                                child: const Text('Cancel'),
                                              ),
                                              ElevatedButton(
                                                onPressed: () =>
                                                    Navigator.of(context)
                                                        .pop(true),
                                                child: const Text('Confirm'),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                      if (confirmed == true) {
                                        try {
                                          final newDateStr = newDate != null
                                              ? newDate!
                                                  .toIso8601String()
                                                  .split('T')[0]
                                              : null;
                                          final newTimeStr =
                                              newTime?.format(context);
                                          await ApiService
                                              .rebookAppointmentAsAdmin(
                                            appointment['appointmentId'] ??
                                                appointment['id'],
                                            service: serviceController.text
                                                    .trim()
                                                    .isEmpty
                                                ? null
                                                : serviceController.text.trim(),
                                            date: newDateStr,
                                            timeSlot: newTimeStr,
                                          );
                                          setState(() {
                                            _approvedAppointments[index]
                                                    ['appointmentDate'] =
                                                newDateStr ??
                                                    _approvedAppointments[index]
                                                        ['appointmentDate'];
                                            _approvedAppointments[index]
                                                    ['timeSlot'] =
                                                newTimeStr ??
                                                    _approvedAppointments[index]
                                                        ['timeSlot'];
                                          });
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                                content: Text(
                                                    'Appointment rebooked and patient notified.')),
                                          );
                                        } catch (e) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                                content: Text(
                                                    'Failed to rebook appointment: \\${e.toString()}')),
                                          );
                                        }
                                      }
                                    },
                                    icon: const Icon(Icons.refresh, size: 16),
                                    label: const Text('Re-book'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      _cancelAppointment(appointment);
                                    },
                                    icon: const Icon(Icons.cancel, size: 16),
                                    label: const Text('Cancel Appointment'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      );
    }
  }

  Widget _buildEmergenciesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Search',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0029B2),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Search Bar
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      controller: _emergencySearchController,
                      decoration: InputDecoration(
                        hintText:
                            'Search by patient name, emergency type, or notes...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        suffixIcon: _emergencySearchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  setState(() {
                                    _emergencySearchController.clear();
                                    _emergencySearchQuery = '';
                                  });
                                },
                              )
                            : null,
                      ),
                      onChanged: (value) {
                        setState(() {
                          _emergencySearchQuery = value;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Results Count
          Text(
            'Found ${_filteredEmergencyRecords.length} emergency record${_filteredEmergencyRecords.length == 1 ? '' : 's'}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),

          // Emergency Records
          ..._filteredEmergencyRecords
              .map((record) => _buildEmergencyCard(record))
              .toList(),
        ],
      ),
    );
  }

  Widget _buildEmergencyCard(EmergencyRecord record) {
    // Get patient information from the patient map
    final patientData = _patientMap[record.patientId];
    final patientName = patientData != null
        ? '${patientData['firstName'] ?? ''} ${patientData['lastName'] ?? ''}'
            .trim()
        : 'Unknown Patient';
    final classification = patientData?['classification'] ?? 'N/A';
    final unitAssignment = patientData?['unitAssignment'] ?? 'N/A';
    final serialNumber = patientData?['serialNumber'] ?? 'N/A';

    // Format date and time
    final dateStr =
        '${record.reportedAt.year}-${record.reportedAt.month.toString().padLeft(2, '0')}-${record.reportedAt.day.toString().padLeft(2, '0')}';
    final timeStr =
        '${record.reportedAt.hour.toString().padLeft(2, '0')}:${record.reportedAt.minute.toString().padLeft(2, '0')}';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        leading: const Icon(Icons.emergency, color: Colors.red, size: 24),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Emergency - ${record.emergencyTypeDisplay}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            Text(
              patientName,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            Text(
              'Priority: ${record.priorityDisplay}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: record.priority == EmergencyPriority.immediate
                    ? Colors.red
                    : record.priority == EmergencyPriority.urgent
                        ? Colors.orange
                        : Colors.green,
              ),
            ),
          ],
        ),
        subtitle: Row(
          children: [
            Text(
              '$dateStr at $timeStr',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(record.status),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                record.statusDisplay,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Patient Information Section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.person, color: Color(0xFF0029B2)),
                          SizedBox(width: 8),
                          Text('Patient Information',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Color(0xFF0029B2))),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildEmergencyInfoRow('Name', patientName),
                      _buildEmergencyInfoRow('Classification', classification),
                      _buildEmergencyInfoRow('Unit Assignment', unitAssignment),
                      _buildEmergencyInfoRow('Serial Number', serialNumber),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Emergency Details Section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.emergency, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Emergency Details',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.red)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildEmergencyInfoRow(
                          'Emergency Type', record.emergencyTypeDisplay),
                      _buildEmergencyInfoRow(
                          'Priority', record.priorityDisplay),
                      _buildEmergencyInfoRow('Status', record.statusDisplay),
                      _buildEmergencyInfoRow(
                          'Pain Level', '${record.painLevel}/10'),
                      _buildEmergencyInfoRow('Date', dateStr),
                      _buildEmergencyInfoRow('Time', timeStr),
                      if (record.notes != null && record.notes!.isNotEmpty)
                        _buildEmergencyInfoRow('Notes', record.notes!),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          _markEmergencyCompleted(record);
                        },
                        icon: const Icon(Icons.check_circle, size: 16),
                        label: const Text('Completed'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          _removeEmergency(record);
                        },
                        icon: const Icon(Icons.delete, size: 16),
                        label: const Text('Remove'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
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

  Widget _buildEmergencyInfoRow(String label, String value) {
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
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(EmergencyStatus status) {
    switch (status) {
      case EmergencyStatus.reported:
        return Colors.orange;
      case EmergencyStatus.triaged:
        return Colors.blue;
      case EmergencyStatus.inProgress:
        return Colors.purple;
      case EmergencyStatus.resolved:
        return Colors.green;
      case EmergencyStatus.referred:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: const Color(0xFF0029B2),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.logout),
          tooltip: 'Logout',
          onPressed: () async {
            final shouldLogout = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Logout'),
                content: const Text('Are you sure you want to logout?'),
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
                    child: const Text('Logout'),
                  ),
                ],
              ),
            );
            if (shouldLogout == true) {
              Navigator.of(context).popUntil((route) => route.isFirst);
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  color: const Color(0xFF0029B2),
                  child: TabBar(
                    controller: _tabController,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white70,
                    indicatorColor: Colors.white,
                    tabs: const [
                      Tab(icon: Icon(Icons.dashboard), text: 'Dashboard'),
                      Tab(icon: Icon(Icons.people), text: 'Patients'),
                      Tab(
                          icon: Icon(Icons.calendar_today),
                          text: 'Appointments'),
                      Tab(icon: Icon(Icons.medical_services), text: 'Approved'),
                      Tab(icon: Icon(Icons.emergency), text: 'Emergencies'),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildDashboardTab(),
                      _buildPatientsTab(),
                      _buildAppointmentsTab(),
                      _buildTreatmentsTab(),
                      _buildEmergenciesTab(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  // Helper method to build section headers
  Widget _buildSectionHeader(String title) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFF0029B2),
        ),
      ),
    );
  }

  // Helper method to format dates
  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    try {
      DateTime dateTime = DateTime.parse(date.toString());
      // Format to readable format (e.g., "July 31, 2025")
      return DateFormat('MMMM d, yyyy').format(dateTime);
    } catch (e) {
      return date.toString();
    }
  }

  // Helper method to build summary items
  Widget _buildSummaryItem(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 24, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  // Show patient edit dialog
  void _showPatientEditDialog(dynamic patient) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Patient: ${patient['fullName']}'),
          content: const Text(
              'Patient editing functionality will be implemented in a future update.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // Export patient data
  void _exportPatientData(dynamic patient) {
    final patientData = '''
Patient Information Export
==========================

Personal Information:
- Full Name: ${patient['fullName'] ?? 'N/A'}
- Email: ${patient['email'] ?? 'N/A'}
- Phone: ${patient['phone'] ?? 'N/A'}
- Date of Birth: ${_formatDate(patient['dateOfBirth'])}
- Address: ${patient['address'] ?? 'N/A'}

Military Information:
- Serial Number: ${patient['serialNumber'] ?? 'N/A'}
- Unit Assignment: ${patient['unitAssignment'] ?? 'N/A'}
- Classification: ${patient['classification'] ?? 'N/A'}
- Other Classification: ${patient['otherClassification'] ?? 'N/A'}

Emergency Contact:
- Emergency Contact: ${patient['emergencyContact'] ?? 'N/A'}
- Emergency Phone: ${patient['emergencyPhone'] ?? 'N/A'}

Medical Information:
- Medical History: ${patient['medicalHistory'] ?? 'N/A'}
- Allergies: ${patient['allergies'] ?? 'N/A'}

Registration Information:
- Patient ID: ${patient['id'] ?? 'N/A'}
- Registration Date: ${_formatDate(patient['createdAt'])}

Exported on: ${DateTime.now().toString()}
''';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Export Patient Data: ${patient['fullName']}'),
          content: SingleChildScrollView(
            child: SelectableText(patientData),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () {
                // In a real app, you would implement actual file export
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'Export functionality will be implemented in a future update'),
                    backgroundColor: Colors.orange,
                  ),
                );
                Navigator.of(context).pop();
              },
              child: const Text('Export to File'),
            ),
          ],
        );
      },
    );
  }

  // Export all patients data
  void _exportAllPatientsData() {
    final allPatientsData = _patients.map((patient) => '''
Patient: ${patient['fullName'] ?? 'N/A'}
=====================================
Personal Information:
- Full Name: ${patient['fullName'] ?? 'N/A'}
- Email: ${patient['email'] ?? 'N/A'}
- Phone: ${patient['phone'] ?? 'N/A'}
- Date of Birth: ${_formatDate(patient['dateOfBirth'])}
- Address: ${patient['address'] ?? 'N/A'}

Military Information:
- Serial Number: ${patient['serialNumber'] ?? 'N/A'}
- Unit Assignment: ${patient['unitAssignment'] ?? 'N/A'}
- Classification: ${patient['classification'] ?? 'N/A'}
- Other Classification: ${patient['otherClassification'] ?? 'N/A'}

Emergency Contact:
- Emergency Contact: ${patient['emergencyContact'] ?? 'N/A'}
- Emergency Phone: ${patient['emergencyPhone'] ?? 'N/A'}

Medical Information:
- Medical History: ${patient['medicalHistory'] ?? 'N/A'}
- Allergies: ${patient['allergies'] ?? 'N/A'}

Registration Information:
- Patient ID: ${patient['id'] ?? 'N/A'}
- Registration Date: ${_formatDate(patient['createdAt'])}

''').join('\n\n');

    final exportData = '''
DENTAL CASE APP - ALL PATIENTS EXPORT
=====================================
Total Patients: ${_patients.length}
Export Date: ${DateTime.now().toString()}

$allPatientsData
''';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Export All Patients Data'),
          content: SingleChildScrollView(
            child: SelectableText(exportData),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'Bulk export functionality will be implemented in a future update'),
                    backgroundColor: Colors.orange,
                  ),
                );
                Navigator.of(context).pop();
              },
              child: const Text('Export to File'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPatientCard(dynamic patient) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              // Patient info
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    patient['fullName'] ??
                        '${patient['firstName'] ?? ''} ${patient['lastName'] ?? ''}'
                            .trim(),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(patient['email'] ?? 'No email'),
                ],
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          PatientDetailScreen(patient: patient),
                    ),
                  );
                },
                icon: const Icon(Icons.history, size: 16),
                label: const Text('Details'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  textStyle: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<Map<String, dynamic>?> fetchPatientSurvey(String patientId) async {
    try {
      final adminToken = await _getAdminToken();
      if (adminToken == null) {
        print('❌ Admin token not available for fetching patient survey');
        return null;
      }

      final response = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/admin/patients/$patientId/survey'),
        headers: {
          'Authorization': 'Bearer $adminToken',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data is Map<String, dynamic> ? data : null;
      }
    } catch (e) {
      print('Error fetching survey: $e');
    }
    return null;
  }

  void _showSurveyDetailsDialog(BuildContext context, String patientId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return const Center(child: CircularProgressIndicator());
      },
    );
    final surveyData = await fetchPatientSurvey(patientId);
    Navigator.of(context).pop(); // Remove loading dialog
    showDialog(
      context: context,
      builder: (context) {
        if (surveyData == null || surveyData.isEmpty) {
          return AlertDialog(
            title: const Text('Survey Details'),
            content: const Text('No survey data found for this patient.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          );
        }
        return AlertDialog(
          title: const Text('Survey Details'),
          content: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.teal.shade700,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Patient Assessment Survey',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...surveyData.entries.toList().asMap().entries.map((entry) {
                      final idx = entry.key;
                      final key = entry.value.key;
                      final value = entry.value.value;
                      final bgColor =
                          idx % 2 == 0 ? Colors.grey.shade50 : Colors.white;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 10),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.teal.shade100),
                        ),
                        child: _buildSurveyEntry(_capitalize(key), value),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSurveyEntry(String key, dynamic value, {int indent = 0}) {
    final isMap = value is Map;
    final isBool = value is bool;
    final isNull = value == null;
    final displayValue =
        isBool ? (value ? 'Yes' : 'No') : (isNull ? 'N/A' : value.toString());

    if (isMap) {
      return Padding(
        padding: EdgeInsets.only(left: 16.0 * indent, bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              indent == 0 ? key : _capitalize(key),
              style: TextStyle(
                fontWeight: indent == 0 ? FontWeight.w600 : FontWeight.w500,
                fontSize: indent == 0 ? 16 : 15,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            ...(value).entries.map(
                (e) => _buildSurveyEntry(e.key, e.value, indent: indent + 1)),
          ],
        ),
      );
    } else {
      return Padding(
        padding: EdgeInsets.only(left: 16.0 * indent, bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (indent > 0)
              const Icon(Icons.radio_button_checked,
                  color: Colors.teal, size: 16),
            if (indent > 0) const SizedBox(width: 6),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(fontSize: 15, color: Colors.black87),
                  children: [
                    if (indent > 0)
                      TextSpan(
                        text: '${_capitalize(key)}: ',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    TextSpan(
                      text: displayValue,
                      style: const TextStyle(fontWeight: FontWeight.normal),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1).replaceAll('_', ' ');
  }

  Future<void> _markEmergencyCompleted(EmergencyRecord record) async {
    try {
      // Get patient information for the confirmation dialog
      final patientData = _patientMap[record.patientId];
      final patientName = patientData != null
          ? '${patientData['firstName'] ?? ''} ${patientData['lastName'] ?? ''}'
              .trim()
          : 'Unknown Patient';

      bool? confirmed = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Complete Emergency & Create Appointment'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Are you sure you want to complete this emergency?',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text('Patient: $patientName'),
                Text('Emergency Type: ${record.emergencyTypeDisplay}'),
                Text('Priority: ${record.priorityDisplay}'),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: const Text(
                    'This will:\n• Mark emergency as resolved\n• Create an appointment record\n• Remove from emergency list\n• Add to patient\'s appointment history',
                    style: TextStyle(fontSize: 12),
                  ),
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
                child: const Text('Complete Emergency'),
              ),
            ],
          );
        },
      );

      if (confirmed == true) {
        // Show loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );

        try {
          // Get admin token
          final adminToken = await _getAdminToken();
          if (adminToken == null) {
            throw Exception('Admin token not available');
          }

          // Step 1: Update emergency status to resolved
          final emergencyResponse = await http.put(
            Uri.parse(
                '${AppConfig.apiBaseUrl}/api/admin/emergencies/${record.id}/status'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $adminToken',
            },
            body: jsonEncode({
              'status': 'resolved',
              'handledBy': 'Admin',
              'resolution': 'Emergency resolved and converted to appointment',
              'followUpRequired': 'Follow-up appointment created',
            }),
          );

          if (emergencyResponse.statusCode != 200) {
            throw Exception(
                'Failed to update emergency status: ${emergencyResponse.statusCode}');
          }

          // Step 1.5: Get the updated emergency record to get the resolved_at date
          final updatedEmergencyResponse = await http.get(
            Uri.parse('${AppConfig.apiBaseUrl}/admin/emergencies'),
            headers: {
              'Authorization': 'Bearer $adminToken',
            },
          );

          if (updatedEmergencyResponse.statusCode != 200) {
            throw Exception(
                'Failed to fetch updated emergency record: ${updatedEmergencyResponse.statusCode}');
          }

          final updatedEmergencyData =
              jsonDecode(updatedEmergencyResponse.body);
          final updatedEmergency =
              updatedEmergencyData['emergencyRecords'].firstWhere(
            (e) => e['id'] == record.id,
            orElse: () => null,
          );

          if (updatedEmergency == null) {
            throw Exception('Could not find updated emergency record');
          }

          // Step 2: Create appointment record for the patient
          // Use the resolved date from the updated emergency record
          final resolvedAtString = updatedEmergency['resolvedAt'];
          final resolvedDate = resolvedAtString != null
              ? DateTime.parse(resolvedAtString)
              : DateTime.now();
          final appointmentDate = resolvedDate.toIso8601String().split('T')[0];

          final appointmentResponse = await http.post(
            Uri.parse('${AppConfig.apiBaseUrl}/admin/appointments/rebook'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $adminToken',
            },
            body: jsonEncode({
              'patient_id': record.patientId,
              'service': 'Emergency Follow-up: ${record.emergencyTypeDisplay}',
              'date': appointmentDate,
              'time_slot': 'Emergency Resolution',
              'notify_patient':
                  false, // Don't notify since this is a completed emergency
            }),
          );

          if (appointmentResponse.statusCode == 200) {
            // Update the appointment status to completed since this is a resolved emergency
            final appointmentData = jsonDecode(appointmentResponse.body);
            final appointmentId = appointmentData['appointment']['id'];

            final updateAppointmentResponse = await http.put(
              Uri.parse(
                  '${AppConfig.apiBaseUrl}/admin/appointments/$appointmentId/status'),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $adminToken',
              },
              body: jsonEncode({
                'status': 'completed',
                'notes':
                    'Emergency resolved and converted to completed appointment',
              }),
            );

            if (updateAppointmentResponse.statusCode != 200) {
              print(
                  'Warning: Failed to update appointment status to completed: ${updateAppointmentResponse.statusCode}');
            }
          }

          if (appointmentResponse.statusCode != 200) {
            print(
                'Warning: Failed to create appointment record: ${appointmentResponse.statusCode}');
            // Don't throw error here as the emergency was already resolved
          }

          // Close loading dialog
          Navigator.of(context).pop();

          // Reload emergency records to reflect the updated status
          await _loadEmergencyRecords();

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Emergency completed successfully! Appointment record created for $patientName'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
            ),
          );
        } catch (e) {
          // Close loading dialog
          Navigator.of(context).pop();
          throw e;
        }
      }
    } catch (e) {
      print('Error completing emergency: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to complete emergency: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _removeEmergency(EmergencyRecord record) async {
    try {
      final TextEditingController noteController = TextEditingController();
      bool? confirmed = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Remove Emergency Record'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                    'Are you sure you want to remove this emergency record?'),
                const SizedBox(height: 16),
                Text(
                    'Patient: ${_patientMap[record.patientId]?['firstName'] ?? ''} ${_patientMap[record.patientId]?['lastName'] ?? ''}'),
                Text('Emergency Type: ${record.emergencyTypeDisplay}'),
                const SizedBox(height: 16),
                const Text(
                  'Leave a note for the patient (optional):',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: noteController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Enter a note for the patient...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'This action cannot be undone.',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
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
                child: const Text('Remove & Notify'),
              ),
            ],
          );
        },
      );

      if (confirmed == true) {
        // Call backend API to delete emergency record
        final adminToken = await _getAdminToken();
        if (adminToken == null) {
          throw Exception('Admin token not available');
        }

        final response = await http.delete(
          Uri.parse('${AppConfig.apiBaseUrl}/api/admin/emergencies/${record.id}'),
          headers: {
            'Authorization': 'Bearer $adminToken',
          },
        );

        if (response.statusCode == 200) {
          // Send notification to patient if note is provided
          if (noteController.text.trim().isNotEmpty) {
            await _sendEmergencyNotification(
                record, noteController.text.trim());
          }

          // Reload emergency records to reflect the deletion
          await _loadEmergencyRecords();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(noteController.text.trim().isNotEmpty
                  ? 'Emergency record removed and patient notified successfully'
                  : 'Emergency record removed successfully'),
              backgroundColor: Colors.orange,
            ),
          );
        } else {
          print(
              '❌ Failed to delete emergency record: ${response.statusCode} - ${response.body}');
          throw Exception(
              'Failed to delete emergency record: ${response.statusCode}');
        }
      }
    } catch (e) {
      print('Error removing emergency record: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to remove emergency record: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<String?> _getAdminToken() async {
    // Try to get token from API service first (where it's actually stored)
    final apiToken = ApiService.currentToken;
    print(
        '🔑 ApiService.currentToken: ${apiToken != null ? 'present' : 'null'}');
    if (apiToken != null) {
      print('✅ Using ApiService token');
      return apiToken;
    }
    // Fallback to UserStateManager
    final userStateToken = UserStateManager().adminToken;
    print(
        '🔑 UserStateManager().adminToken: ${userStateToken != null ? 'present' : 'null'}');
    print('✅ Using UserStateManager token');
    return userStateToken;
  }

  Future<void> _sendEmergencyNotification(
      EmergencyRecord record, String note) async {
    try {
      final adminToken = await _getAdminToken();
      if (adminToken == null) {
        throw Exception('Admin token not available');
      }

      final response = await http.post(
        Uri.parse(
            '${AppConfig.apiBaseUrl}/api/admin/emergencies/${record.id}/notify'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $adminToken',
        },
        body: jsonEncode({
          'patientId': record.patientId,
          'message': note,
          'emergencyType': record.emergencyTypeDisplay,
        }),
      );

      if (response.statusCode == 200) {
        print('✅ Emergency notification sent successfully');
      } else {
        print(
            '❌ Failed to send emergency notification: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to send notification: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error sending emergency notification: $e');
      throw Exception('Failed to send notification: $e');
    }
  }
}
