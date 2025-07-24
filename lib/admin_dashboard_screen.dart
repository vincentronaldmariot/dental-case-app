import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'models/appointment.dart';
import 'models/patient.dart';
import 'models/treatment_record.dart';
import 'models/emergency_record.dart';
import 'services/history_service.dart';
import 'patient_detail_screen.dart';
import 'admin_survey_detail_screen.dart';
import 'dental_survey_simple.dart';
import 'services/api_service.dart';
import 'user_state_manager.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

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
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  final String _selectedNewDate = '';
  final String _selectedNewTimeSlot = '';
  String _approvalNotes = '';
  String _rejectionReason = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await Future.wait([
        _loadPatients(),
        _loadAppointments(),
        _fetchPendingAppointmentsWithSurvey(),
        _loadApprovedAppointments(),
        _loadTreatmentRecords(),
        _loadEmergencyRecords(),
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
      final response = await http.get(
        Uri.parse('http://localhost:3000/api/admin/patients'),
        headers: {
          'Authorization':
              'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6ImJlNTBjOTAxLTdlZWQtNDIyOC05NzExLTk5OWIwOGEwZTcyZCIsInVzZXJuYW1lIjoiYWRtaW4iLCJ0eXBlIjoiYWRtaW4iLCJpYXQiOjE3NTMwODM4NzQsImV4cCI6MTc1MzY4ODY3NH0.jTqWoKAaX3SG2njDlgWbdFMyTjJab5kdgr5466cJcq4',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Handle both array and object responses
        List<dynamic> patients = [];
        if (data is List) {
          patients = data;
        } else if (data is Map && data.containsKey('patients')) {
          patients = data['patients'] ?? [];
        } else {
          patients = [];
        }

        setState(() {
          _patients = patients;
          _patientMap = Map.fromEntries(
            _patients.map((p) => MapEntry(p['id'], p)),
          );
        });
        print('✅ Loaded ${_patients.length} patients');
      } else {
        print('❌ Failed to load patients: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error loading patients: $e');
    }
  }

  Future<void> _loadAppointments() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:3000/api/admin/appointments'),
        headers: {
          'Authorization':
              'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6ImJlNTBjOTAxLTdlZWQtNDIyOC05NzExLTk5OWIwOGEwZTcyZCIsInVzZXJuYW1lIjoiYWRtaW4iLCJ0eXBlIjoiYWRtaW4iLCJpYXQiOjE3NTMwODM4NzQsImV4cCI6MTc1MzY4ODY3NH0.jTqWoKAaX3SG2njDlgWbdFMyTjJab5kdgr5466cJcq4',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Handle both array and object responses
        List<dynamic> appointments = [];
        if (data is List) {
          appointments = data;
        } else if (data is Map && data.containsKey('appointments')) {
          appointments = data['appointments'] ?? [];
        } else {
          appointments = [];
        }

        setState(() {
          _appointments = appointments;
        });
        print('✅ Loaded ${_appointments.length} total appointments');
      } else {
        print('❌ Failed to load appointments: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error loading appointments: $e');
    }
  }

  Future<void> _fetchPendingAppointmentsWithSurvey() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:3000/api/admin/pending-appointments'),
        headers: {
          'Authorization':
              'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6ImJlNTBjOTAxLTdlZWQtNDIyOC05NzExLTk5OWIwOGEwZTcyZCIsInVzZXJuYW1lIjoiYWRtaW4iLCJ0eXBlIjoiYWRtaW4iLCJpYXQiOjE3NTMwODM4NzQsImV4cCI6MTc1MzY4ODY3NH0.jTqWoKAaX3SG2njDlgWbdFMyTjJab5kdgr5466cJcq4',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Handle both array and object responses
        List<dynamic> appointments = [];
        if (data is List) {
          appointments = data;
        } else if (data is Map && data.containsKey('appointments')) {
          appointments = data['appointments'] ?? [];
        } else {
          appointments = [];
        }

        setState(() {
          _pendingAppointments = appointments;
        });
        print('✅ Loaded ${_pendingAppointments.length} pending appointments');
        for (var appointment in _pendingAppointments) {
          print(
              '📋 Appointment: ${appointment['patient_name']} - ${appointment['service']} - ${appointment['appointment_id']}');
        }
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
      final response = await http.get(
        Uri.parse('http://localhost:3000/api/admin/appointments/approved'),
        headers: {
          'Authorization':
              'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6ImJlNTBjOTAxLTdlZWQtNDIyOC05NzExLTk5OWIwOGEwZTcyZCIsInVzZXJuYW1lIjoiYWRtaW4iLCJ0eXBlIjoiYWRtaW4iLCJpYXQiOjE3NTMwODM4NzQsImV4cCI6MTc1MzY4ODY3NH0.jTqWoKAaX3SG2njDlgWbdFMyTjJab5kdgr5466cJcq4',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<dynamic> appointments = [];
        if (data is Map && data.containsKey('approvedAppointments')) {
          appointments = data['approvedAppointments'] ?? [];
        } else {
          appointments = [];
        }

        setState(() {
          _approvedAppointments = appointments;
        });
        print('✅ Loaded ${_approvedAppointments.length} approved appointments');
      } else {
        print('❌ Failed to load approved appointments: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error loading approved appointments: $e');
    }
  }

  Future<void> _loadEmergencyRecords() async {
    // Emergency records are not implemented in HistoryService yet
    setState(() {
      _emergencyRecords = [];
    });
  }

  void _showProceedDialog(dynamic appointment, [dynamic survey]) async {
    print(
        'Opening appointment details dialog for: ${appointment['appointment_id']}');

    final id = appointment is Appointment
        ? appointment.id
        : appointment['appointment_id'];
    String service = appointment is Appointment
        ? appointment.service
        : appointment['service'];
    dynamic date = appointment is Appointment
        ? appointment.date
        : appointment['booking_date'] ?? appointment['appointment_date'];
    String timeSlot = appointment is Appointment
        ? appointment.timeSlot
        : appointment['time_slot'];
    final status =
        appointment is Appointment ? appointment.status : appointment['status'];
    final patientName = appointment is Appointment
        ? (appointment.patientId ?? '')
        : (appointment['patient_name'] ?? '');
    final patientEmail =
        appointment is Appointment ? '' : (appointment['patient_email'] ?? '');
    final patientPhone =
        appointment is Appointment ? '' : (appointment['patient_phone'] ?? '');
    final notes =
        appointment is Appointment ? appointment.notes : appointment['notes'];
    final doctorName = appointment is Appointment
        ? appointment.doctorName
        : (appointment['doctor_name'] ?? '');
    final effectiveSurvey = survey ??
        ((appointment is Map && (appointment).containsKey('survey_data'))
            ? (appointment)['survey_data']
            : null);

    // Format date for display
    String formattedDate = 'Unknown';
    DateTime? parsedDate;
    if (date != null) {
      try {
        if (date is String) {
          parsedDate = DateTime.parse(date);
          formattedDate =
              '${parsedDate.year}-${parsedDate.month.toString().padLeft(2, '0')}-${parsedDate.day.toString().padLeft(2, '0')}';
        } else if (date is DateTime) {
          parsedDate = date;
          formattedDate =
              '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        }
      } catch (e) {
        formattedDate = date.toString();
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
                          _buildInfoRow('Doctor', doctorName, Icons.person),
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
      print('✅ Approving appointment: ${appointment['appointment_id']}');
      print('📋 Patient: ${appointment['patient_name']}');
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
        final response = await http.post(
          Uri.parse(
              'http://localhost:3000/api/admin/appointments/${appointment['appointment_id']}/approve'),
          headers: {
            'Authorization':
                'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6ImJlNTBjOTAxLTdlZWQtNDIyOC05NzExLTk5OWIwOGEwZTcyZCIsInVzZXJuYW1lIjoiYWRtaW4iLCJ0eXBlIjoiYWRtaW4iLCJpYXQiOjE3NTMwODM4NzQsImV4cCI6MTc1MzY4ODY3NH0.jTqWoKAaX3SG2njDlgWbdFMyTjJab5kdgr5466cJcq4',
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
          _fetchPendingAppointmentsWithSurvey();
          _loadApprovedAppointments();
          final treatmentRecord = TreatmentRecord(
            id: 'tr_${DateTime.now().millisecondsSinceEpoch}',
            patientId: appointment['patient_id'] ?? '',
            appointmentId: appointment['appointment_id'] ?? '',
            treatmentType: appointment['service'] ?? 'General Treatment',
            description:
                'Treatment for ${appointment['service'] ?? 'General Treatment'}',
            doctorName: appointment['doctor_name'] ?? 'Unknown',
            treatmentDate:
                DateTime.tryParse(appointment['date'] ?? '') ?? DateTime.now(),
            procedures: [],
            notes: _approvalNotes.isNotEmpty ? _approvalNotes : null,
            prescription: null,
          );
          HistoryService().addTreatmentRecord(treatmentRecord);
          setState(() {
            _treatmentRecords = HistoryService().getTreatmentRecords();
          });
          _tabController.animateTo(2); // Switch to Approved tab
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
        final response = await http.put(
          Uri.parse(
              'http://localhost:3000/api/admin/appointments/${appointment['appointmentId']}/status'),
          headers: {
            'Authorization':
                'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6ImJlNTBjOTAxLTdlZWQtNDIyOC05NzExLTk5OWIwOGEwZTcyZCIsInVzZXJuYW1lIjoiYWRtaW4iLCJ0eXBlIjoiYWRtaW4iLCJpYXQiOjE3NTMwODM4NzQsImV4cCI6MTc1MzY4ODY3NH0.jTqWoKAaX3SG2njDlgWbdFMyTjJab5kdgr5466cJcq4',
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
          _loadApprovedAppointments();
          await _loadData();
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

  Future<void> _rejectAppointment(dynamic appointment) async {
    try {
      print('❌ Rejecting appointment: ${appointment['appointment_id']}');
      print('📋 Patient: ${appointment['patient_name']}');
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
        final response = await http.post(
          Uri.parse(
              'http://localhost:3000/api/admin/appointments/${appointment['appointment_id']}/reject'),
          headers: {
            'Authorization':
                'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6ImJlNTBjOTAxLTdlZWQtNDIyOC05NzExLTk5OWIwOGEwZTcyZCIsInVzZXJuYW1lIjoiYWRtaW4iLCJ0eXBlIjoiYWRtaW4iLCJpYXQiOjE3NTMwODM4NzQsImV4cCI6MTc1MzY4ODY3NH0.jTqWoKAaX3SG2njDlgWbdFMyTjJab5kdgr5466cJcq4',
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
          _fetchPendingAppointmentsWithSurvey();
          await _loadData();
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

      final response = await http.put(
        Uri.parse(
            'http://localhost:3000/api/admin/appointments/$appointmentId/update'),
        headers: {
          'Authorization':
              'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6ImJlNTBjOTAxLTdlZWQtNDIyOC05NzExLTk5OWIwOGEwZTcyZCIsInVzZXJuYW1lIjoiYWRtaW4iLCJ0eXBlIjoiYWRtaW4iLCJpYXQiOjE3NTMwODM4NzQsImV4cCI6MTc1MzY4ODY3NH0.jTqWoKAaX3SG2njDlgWbdFMyTjJab5kdgr5466cJcq4',
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
                          _pendingAppointments.length.toString(),
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
                          _approvedAppointments.length.toString(),
                          Icons.medical_services,
                          Colors.teal,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          'Emergency Records',
                          _emergencyRecords.length.toString(),
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
                            label: const Text('History'),
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
                            onPressed: () {}, // Clickable, no function
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
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
                                        app['booking_date'] ?? '');
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
                                        app['booking_date'] ?? '');
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
                                .where((app) => app['has_survey_data'] == true)
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
          if (_pendingAppointments.isEmpty)
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
            ..._pendingAppointments
                .map((appointment) => _buildAppointmentCard(appointment)),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard(dynamic appointment) {
    // Format the date for better display
    String formattedDate = 'Unknown';
    if (appointment['booking_date'] != null) {
      try {
        DateTime date = DateTime.parse(appointment['booking_date']);
        formattedDate =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      } catch (e) {
        formattedDate = appointment['booking_date'];
      }
    } else if (appointment['date'] != null) {
      formattedDate = appointment['date'];
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appointment['patient_name'] ?? 'Unknown Patient',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ID: ${appointment['appointment_id'] ?? 'N/A'}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Chip(
                  label: Text(
                    (appointment['status'] ?? 'Pending').toUpperCase(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor: Colors.orange.shade100,
                  labelStyle: TextStyle(color: Colors.orange.shade800),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  _buildInfoRow('Service', appointment['service'] ?? 'Unknown'),
                  _buildInfoRow('Date', formattedDate),
                  _buildInfoRow('Time', appointment['time_slot'] ?? 'Unknown'),
                  _buildInfoRow('Classification',
                      appointment['patient_classification'] ?? 'N/A'),
                  _buildInfoRow('Unit Assignment',
                      appointment['patient_unit_assignment'] ?? 'N/A'),
                  _buildInfoRow('Serial Number',
                      appointment['patient_serial_number'] ?? 'N/A'),
                  if (appointment['patient_email'] != null)
                    _buildInfoRow('Email', appointment['patient_email']),
                  if (appointment['patient_phone'] != null)
                    _buildInfoRow('Phone', appointment['patient_phone']),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      print(
                          'Viewing details for appointment: ${appointment['appointment_id']}');
                      _showProceedDialog(appointment);
                    },
                    icon: const Icon(Icons.visibility, size: 16),
                    label: const Text('View Details'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      print(
                          'Approving appointment: ${appointment['appointment_id']}');
                      _approveAppointment(appointment);
                    },
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Approve'),
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
                      print(
                          'Rejecting appointment: ${appointment['appointment_id']}');
                      _rejectAppointment(appointment);
                    },
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Reject'),
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
    );
  }

  Widget _buildTreatmentsTab() {
    if (_approvedAppointments.isEmpty) {
      return Center(
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
      );
    } else {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _approvedAppointments.length,
        itemBuilder: (context, index) {
          final appointment = _approvedAppointments[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.check_circle, color: Colors.teal),
                    title:
                        Text(appointment['patientName'] ?? 'Unknown Patient'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Service: ${appointment['service'] ?? 'N/A'}'),
                        Text(
                            'Date: ${appointment['appointmentDate'] ?? 'N/A'}'),
                        Text('Time: ${appointment['timeSlot'] ?? 'N/A'}'),
                        Text('Status: ${appointment['status'] ?? 'N/A'}'),
                      ],
                    ),
                    // Removed trailing: IconButton (eye/visibility button)
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text('Completed'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () async {
                          DateTime? newDate;
                          TimeOfDay? newTime;
                          String newService = appointment['service'] ?? '';
                          final services = [
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
                          ];
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) {
                              return StatefulBuilder(
                                builder: (context, setState) {
                                  return AlertDialog(
                                    title: const Text('Re-book Appointment'),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        DropdownButtonFormField<String>(
                                          value: newService.isNotEmpty
                                              ? newService
                                              : null,
                                          decoration: const InputDecoration(
                                            labelText: 'Service',
                                            border: OutlineInputBorder(),
                                          ),
                                          items: services
                                              .map((s) =>
                                                  DropdownMenuItem<String>(
                                                    value: s,
                                                    child: Text(s),
                                                  ))
                                              .toList(),
                                          onChanged: (val) {
                                            setState(() {
                                              newService = val ?? newService;
                                            });
                                          },
                                        ),
                                        const SizedBox(height: 12),
                                        InkWell(
                                          onTap: () async {
                                            final picked = await showDatePicker(
                                              context: context,
                                              initialDate: DateTime.tryParse(
                                                      appointment[
                                                              'appointmentDate'] ??
                                                          '') ??
                                                  DateTime.now(),
                                              firstDate: DateTime.now(),
                                              lastDate: DateTime.now().add(
                                                  const Duration(days: 365)),
                                            );
                                            if (picked != null) {
                                              setState(() {
                                                newDate = picked;
                                              });
                                            }
                                          },
                                          child: InputDecorator(
                                            decoration: const InputDecoration(
                                              labelText: 'Date',
                                              border: OutlineInputBorder(),
                                            ),
                                            child: Text(newDate != null
                                                ? '${newDate!.year}-${newDate!.month.toString().padLeft(2, '0')}-${newDate!.day.toString().padLeft(2, '0')}'
                                                : (appointment[
                                                        'appointmentDate'] ??
                                                    'Select Date')),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        InkWell(
                                          onTap: () async {
                                            final picked = await showTimePicker(
                                              context: context,
                                              initialTime: TimeOfDay.now(),
                                            );
                                            if (picked != null) {
                                              setState(() {
                                                newTime = picked;
                                              });
                                            }
                                          },
                                          child: InputDecorator(
                                            decoration: const InputDecoration(
                                              labelText: 'Time',
                                              border: OutlineInputBorder(),
                                            ),
                                            child: Text(newTime != null
                                                ? newTime!.format(context)
                                                : (appointment['timeSlot'] ??
                                                    'Select Time')),
                                          ),
                                        ),
                                      ],
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(false),
                                        child: const Text('Cancel'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(true),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blue,
                                          foregroundColor: Colors.white,
                                        ),
                                        child: const Text('Confirm'),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          );
                          if (confirmed == true) {
                            // Prepare new values
                            final dateStr = newDate != null
                                ? '${newDate!.year.toString().padLeft(4, '0')}-${newDate!.month.toString().padLeft(2, '0')}-${newDate!.day.toString().padLeft(2, '0')}'
                                : appointment['appointmentDate'];
                            final timeStr = newTime != null
                                ? newTime!.format(context)
                                : appointment['timeSlot'];
                            // Send update request to backend
                            final response = await http.put(
                              Uri.parse(
                                  'http://localhost:3000/api/admin/appointments/${appointment['appointmentId'] ?? appointment['id']}/rebook'),
                              headers: {
                                'Authorization':
                                    'Bearer ${UserStateManager().adminToken ?? ''}',
                                'Content-Type': 'application/json',
                              },
                              body: jsonEncode({
                                'service': newService,
                                'date': dateStr,
                                'time_slot': timeStr,
                              }),
                            );
                            if (response.statusCode == 200) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Appointment rebooked and patient notified.'),
                                  backgroundColor: Colors.blue,
                                ),
                              );
                              // Optionally update the UI or reload appointments
                              setState(() {
                                _approvedAppointments[index]['service'] =
                                    newService;
                                _approvedAppointments[index]
                                    ['appointmentDate'] = dateStr;
                                _approvedAppointments[index]['timeSlot'] =
                                    timeStr;
                              });
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'Failed to rebook appointment: \\${response.body}'),
                                  backgroundColor: Colors.red,
                                ),
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
                              horizontal: 12, vertical: 8),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () async {
                          String cancelNote = '';
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: const Text('Cancel Appointment'),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                        'Are you sure you want to cancel this appointment?'),
                                    const SizedBox(height: 16),
                                    TextField(
                                      decoration: const InputDecoration(
                                        labelText: 'Leave a note (optional)',
                                        border: OutlineInputBorder(),
                                      ),
                                      maxLines: 3,
                                      onChanged: (value) {
                                        cancelNote = value;
                                      },
                                    ),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(false),
                                    child: const Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(true),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('Confirm'),
                                  ),
                                ],
                              );
                            },
                          );
                          if (confirmed == true) {
                            // Send cancel request to backend
                            final response = await http.post(
                              Uri.parse(
                                  'http://localhost:3000/api/admin/appointments/${appointment['appointmentId'] ?? appointment['id']}/cancel'),
                              headers: {
                                'Authorization':
                                    'Bearer ${UserStateManager().adminToken ?? ''}',
                                'Content-Type': 'application/json',
                              },
                              body: jsonEncode({'note': cancelNote}),
                            );
                            if (response.statusCode == 200) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Appointment cancelled and patient notified.'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              // Remove from approved list
                              setState(() {
                                _approvedAppointments.removeAt(index);
                              });
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'Failed to cancel appointment: ${response.body}'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.cancel, size: 16),
                        label: const Text('Cancel Appointment'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    }
  }

  Widget _buildEmergenciesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: _emergencyRecords
            .map((record) => _buildEmergencyCard(record))
            .toList(),
      ),
    );
  }

  Widget _buildEmergencyCard(EmergencyRecord record) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: const Icon(Icons.emergency, color: Colors.red),
        title: Text('Emergency - ${record.emergencyTypeDisplay}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Patient ID: ${record.patientId}'),
            Text('Pain Level: ${record.painLevel}'),
            Text('Date: ${record.reportedAt.toString().split(' ')[0]}'),
            if (record.notes != null) Text('Notes: ${record.notes}'),
          ],
        ),
        isThreeLine: true,
      ),
    );
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
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
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
                label: const Text('History'),
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
      final response = await http.get(
        Uri.parse('http://localhost:3000/api/admin/patients/$patientId/survey'),
        headers: {
          'Authorization':
              'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6ImJlNTBjOTAxLTdlZWQtNDIyOC05NzExLTk5OWIwOGEwZTcyZCIsInVzZXJuYW1lIjoiYWRtaW4iLCJ0eXBlIjoiYWRtaW4iLCJpYXQiOjE3NTMwODM4NzQsImV4cCI6MTc1MzY4ODY3NH0.jTqWoKAaX3SG2njDlgWbdFMyTjJab5kdgr5466cJcq4',
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
            ...(value as Map).entries.map(
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
                        text: _capitalize(key) + ': ',
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
}
