import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'models/treatment_record.dart';
import 'services/history_service.dart';
import 'services/patient_history_service.dart';
import 'user_state_manager.dart';
import 'services/api_service.dart'; // Added import for ApiService

class TreatmentHistoryScreen extends StatefulWidget {
  final String? patientId;
  final String? patientEmail;
  const TreatmentHistoryScreen({Key? key, this.patientId, this.patientEmail})
      : super(key: key);

  @override
  State<TreatmentHistoryScreen> createState() => _TreatmentHistoryScreenState();
}

class _TreatmentHistoryScreenState extends State<TreatmentHistoryScreen> {
  final HistoryService _historyService = HistoryService();
  final PatientHistoryService _patientHistoryService = PatientHistoryService();

  List<TreatmentRecord> _treatmentRecords = [];
  String _selectedFilter = 'All';
  bool _isLoading = true;

  // New variables for comprehensive history
  Map<String, dynamic>? _surveyData;
  List<dynamic> _appointments = [];
  List<dynamic> _emergencies = [];
  String _selectedTab = 'Treatment History';

  final List<String> _filterOptions = [
    'All',
    'General Checkup',
    'Teeth Cleaning',
    'Root Canal',
    'Orthodontics',
    'Emergency',
  ];

  final List<String> _tabOptions = [
    'Treatment History',
    'Self Assessment',
    'Appointments',
    'Emergencies',
  ];

  @override
  void initState() {
    super.initState();
    _loadPatientHistory();
  }

  Future<void> _loadPatientHistory() async {
    setState(() => _isLoading = true);
    try {
      final String patientId = (widget.patientId != null &&
              widget.patientId!.isNotEmpty &&
              widget.patientId != 'null')
          ? widget.patientId!
          : (UserStateManager().currentPatientId ?? '');
      final String token = UserStateManager().adminToken ??
          UserStateManager().patientToken ??
          '';
      Map<String, dynamic>? surveyData;
      if (UserStateManager().isAdminLoggedIn &&
          widget.patientId != null &&
          widget.patientId!.isNotEmpty &&
          widget.patientId != 'null') {
        final String adminPatientId = widget.patientId!;
        surveyData = await ApiService.getPatientSurveyAsAdmin(adminPatientId);
        if (surveyData == null &&
            widget.patientEmail != null &&
            widget.patientEmail!.isNotEmpty) {
          // Try fetching by email as fallback
          surveyData = await ApiService.getPatientSurveyAsAdmin(adminPatientId,
              email: widget.patientEmail);
        }
        _surveyData = surveyData != null ? surveyData['surveyData'] : null;
        print('Admin survey data: $_surveyData');
      } else {
        final history =
            await _patientHistoryService.getPatientHistory(patientId, token);
        _surveyData = history['survey']?['surveyData'];
        _appointments = history['appointments'] ?? [];
        _emergencies = history['emergencies'] ?? [];
        _treatmentRecords =
            _patientHistoryService.parseTreatments(history['treatments'] ?? []);
      }
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading patient history: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterTreatmentRecords(String filter) {
    setState(() {
      _selectedFilter = filter;
      if (filter == 'All') {
        _treatmentRecords = _historyService.getTreatmentRecords(
          patientId: UserStateManager().currentPatientId,
        );
      } else {
        _treatmentRecords = _historyService.getTreatmentRecordsByType(
          filter,
          patientId: UserStateManager().currentPatientId,
        );
      }
    });
  }

  void _selectTab(String tab) {
    setState(() {
      _selectedTab = tab;
    });
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
                  'Treatment History',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                backgroundColor: const Color(0xFF0029B2),
                elevation: 0,
                iconTheme: const IconThemeData(color: Colors.white),
                actions: [
                  IconButton(
                    onPressed: _loadPatientHistory,
                    icon: const Icon(Icons.refresh, color: Colors.white),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Patient History',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _tabOptions.length,
                    itemBuilder: (context, index) {
                      final tab = _tabOptions[index];
                      final isSelected = _selectedTab == tab;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(
                            tab,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF0029B2),
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                          selected: isSelected,
                          onSelected: (selected) => _selectTab(tab),
                          backgroundColor: Colors.white,
                          selectedColor: const Color(0xFF005800),
                          checkmarkColor: Colors.white,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Content Section
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF0029B2),
                      ),
                    ),
                  )
                : _buildSelectedTabContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedTabContent() {
    switch (_selectedTab) {
      case 'Treatment History':
        return _buildTreatmentHistoryTab();
      case 'Self Assessment':
        return _buildSelfAssessmentTab();
      case 'Appointments':
        return _buildAppointmentsTab();
      case 'Emergencies':
        return _buildEmergenciesTab();
      default:
        return _buildTreatmentHistoryTab();
    }
  }

  Widget _buildTreatmentHistoryTab() {
    if (_treatmentRecords.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _treatmentRecords.length,
      itemBuilder: (context, index) {
        final record = _treatmentRecords[index];
        return _buildTreatmentRecordCard(record);
      },
    );
  }

  Widget _buildSelfAssessmentTab() {
    if (_surveyData == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.quiz_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No Self Assessment Found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Complete a dental survey to see your self-assessment here',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // If admin, show the full original survey Q&A
    if (UserStateManager().isAdminLoggedIn) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 3,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: _buildFullSurveyQA(_surveyData!),
          ),
        ),
      );
    }

    // Default: mapped Q&A style
    final parsedSurveyData =
        _patientHistoryService.parseSurveyData(_surveyData!);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 3,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.quiz,
                        color: const Color(0xFF0029B2),
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Dental Self Assessment',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0029B2),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ...parsedSurveyData.entries.map((entry) {
                    final question = entry.key;
                    final answer = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            question,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: _getAnswerColor(answer),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              answer.toString(),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: _getAnswerTextColor(answer),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentsTab() {
    if (_appointments.isEmpty) {
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
              'No Appointments Found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your appointment history will appear here',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _appointments.length,
      itemBuilder: (context, index) {
        final appointment = _appointments[index];
        return _buildAppointmentCard(appointment);
      },
    );
  }

  Widget _buildEmergenciesTab() {
    if (_emergencies.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.local_hospital_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No Emergency Records Found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your emergency records will appear here',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _emergencies.length,
      itemBuilder: (context, index) {
        final emergency = _emergencies[index];
        return _buildEmergencyCard(emergency);
      },
    );
  }

  Color _getAnswerColor(String answer) {
    switch (answer.toLowerCase()) {
      case 'yes':
        return Colors.red.shade50;
      case 'no':
        return Colors.green.shade50;
      case 'not specified':
        return Colors.grey.shade50;
      default:
        return Colors.blue.shade50;
    }
  }

  Color _getAnswerTextColor(String answer) {
    switch (answer.toLowerCase()) {
      case 'yes':
        return Colors.red.shade700;
      case 'no':
        return Colors.green.shade700;
      case 'not specified':
        return Colors.grey.shade600;
      default:
        return Colors.blue.shade700;
    }
  }

  Widget _buildAppointmentCard(Map<String, dynamic> appointment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0029B2).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.calendar_today,
                    color: Color(0xFF0029B2),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appointment['service'] ?? 'Appointment',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        appointment['doctorName'] ?? 'Doctor',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(appointment['status']),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    appointment['status'] ?? 'Unknown',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  DateFormat('MMM dd, yyyy').format(
                    DateTime.parse(appointment['date']),
                  ),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(width: 16),
                Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  appointment['timeSlot'] ?? 'No time specified',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            if (appointment['notes'] != null) ...[
              const SizedBox(height: 8),
              Text(
                'Notes: ${appointment['notes']}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyCard(Map<String, dynamic> emergency) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.local_hospital,
                    color: Colors.red,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        emergency['type'] ?? 'Emergency',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        emergency['description'] ?? 'No description',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getPriorityColor(emergency['priority']),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    emergency['priority'] ?? 'Unknown',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  DateFormat('MMM dd, yyyy').format(
                    DateTime.parse(emergency['reportedAt']),
                  ),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(width: 16),
                Icon(Icons.person, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  emergency['handledBy'] ?? 'Not specified',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'scheduled':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Color _getPriorityColor(String? priority) {
    switch (priority?.toLowerCase()) {
      case 'immediate':
        return Colors.red;
      case 'urgent':
        return Colors.orange;
      case 'standard':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.medical_services_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Treatment Records',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your treatment history will appear here',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildTreatmentRecordCard(TreatmentRecord record) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.all(16),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: const Color(0xFF0029B2).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _getIconForTreatmentType(record.treatmentType),
            color: const Color(0xFF0029B2),
            size: 24,
          ),
        ),
        title: Text(
          record.treatmentType,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              record.description,
              style: const TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  DateFormat('MMM dd, yyyy').format(record.treatmentDate),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(width: 16),
                Icon(Icons.person, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  record.doctorName,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
        children: [
          const Divider(),
          _buildDetailSection('Procedures Performed', record.procedures),
          if (record.notes != null) ...[
            const SizedBox(height: 12),
            _buildDetailSection('Notes', [record.notes!]),
          ],
          if (record.prescription != null) ...[
            const SizedBox(height: 12),
            _buildDetailSection('Prescription', [record.prescription!]),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ', style: TextStyle(color: Color(0xFF0029B2))),
                Expanded(
                  child: Text(
                    item,
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFullSurveyQA(Map<String, dynamic> surveyData) {
    List<Widget> qaWidgets = [];
    void addQA(String question, dynamic answer) {
      qaWidgets.add(Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              question,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                answer == null || answer.toString().isEmpty
                    ? '—'
                    : answer.toString(),
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ));
    }

    surveyData.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        value.forEach((subKey, subValue) {
          addQA('${_humanize(key)} - ${_humanize(subKey)}', subValue);
        });
      } else {
        addQA(_humanize(key), value);
      }
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: qaWidgets,
    );
  }

  String _humanize(String key) {
    return key
        .replaceAll('_', ' ')
        .replaceAll(RegExp(r'([a-z])([A-Z])'), r'$1 $2')
        .replaceAllMapped(
            RegExp(r'\b([a-z])'), (m) => m.group(0)!.toUpperCase())
        .replaceFirstMapped(
            RegExp(r'^[a-z]'), (m) => m.group(0)!.toUpperCase());
  }

  IconData _getIconForTreatmentType(String treatmentType) {
    switch (treatmentType.toLowerCase()) {
      case 'general checkup':
        return Icons.medical_services;
      case 'teeth cleaning':
        return Icons.cleaning_services;
      case 'root canal':
        return Icons.healing;
      case 'orthodontics':
        return Icons.straighten;
      case 'emergency':
        return Icons.local_hospital;
      case 'preventive care':
        return Icons.shield;
      default:
        return Icons.medical_information;
    }
  }
}
