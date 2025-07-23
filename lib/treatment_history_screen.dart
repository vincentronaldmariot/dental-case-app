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
  final PatientHistoryService _patientHistoryService = PatientHistoryService();

  Map<String, dynamic>? _surveyData;
  List<dynamic> _appointments = [];
  bool _isLoading = true;
  String _selectedTab = 'Appointment History';

  final List<String> _tabOptions = [
    'Appointment History',
    'Self Assessment',
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
      final history =
          await _patientHistoryService.getPatientHistory(patientId, token);
      _surveyData = history['survey']?['surveyData'];
      _appointments = history['appointments'] ?? [];
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

  void _selectTab(String tab) {
    setState(() {
      _selectedTab = tab;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Patient History'),
        backgroundColor: const Color(0xFF0029B2),
        foregroundColor: Colors.white,
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
              mainAxisAlignment: MainAxisAlignment.start,
              children: _tabOptions.map((tab) {
                final isSelected = _selectedTab == tab;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(
                      tab,
                      style: TextStyle(
                        color:
                            isSelected ? Colors.white : const Color(0xFF0029B2),
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (selected) => _selectTab(tab),
                    backgroundColor: Colors.white,
                    selectedColor: const Color(0xFF005800),
                    checkmarkColor: Colors.white,
                  ),
                );
              }).toList(),
            ),
          ),
          // Content Section
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFF0029B2)),
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
      case 'Appointment History':
        return _buildAppointmentHistoryTab();
      case 'Self Assessment':
        return _buildSelfAssessmentTab();
      default:
        return _buildAppointmentHistoryTab();
    }
  }

  Widget _buildAppointmentHistoryTab() {
    if (_appointments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today_outlined,
                size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('No Appointments Found',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600])),
            const SizedBox(height: 8),
            Text('Your appointment history will appear here',
                style: TextStyle(fontSize: 14, color: Colors.grey[500])),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _appointments.length,
      itemBuilder: (context, index) {
        final appointment = _appointments[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appointment['service'] ?? 'Unknown Service',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                    'Date: ${appointment['date'] ?? appointment['booking_date'] ?? 'Unknown'}'),
                Text('Time: ${appointment['time_slot'] ?? 'Unknown'}'),
                Text('Status: ${appointment['status'] ?? 'Unknown'}'),
                if (appointment['doctor_name'] != null)
                  Text('Doctor: ${appointment['doctor_name']}'),
                if (appointment['notes'] != null &&
                    appointment['notes'].toString().isNotEmpty)
                  Text('Notes: ${appointment['notes']}'),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSelfAssessmentTab() {
    if (_surveyData == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.quiz_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('No Self Assessment Found',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600])),
            const SizedBox(height: 8),
            Text('Complete a dental survey to see your self-assessment here',
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                textAlign: TextAlign.center),
          ],
        ),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: _buildFullSurveyQA(_surveyData!),
        ),
      ),
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
                  color: Colors.black87),
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

    final Map<String, dynamic> safeSurveyData =
        Map<String, dynamic>.from(surveyData);
    for (var entry in safeSurveyData.entries) {
      final key = entry.key.toString();
      final value = entry.value;
      if (value is Map<String, dynamic>) {
        for (final MapEntry<String, dynamic> subEntry in value.entries) {
          final subKey = subEntry.key;
          final subValue = subEntry.value;
          addQA('${_humanize(key)} - ${_humanize(subKey)}', subValue);
        }
      } else {
        addQA(_humanize(key), value);
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: qaWidgets,
    );
  }

  String _humanize(String key) {
    return key.replaceAll('_', ' ').replaceAllMapped(
        RegExp(r'\b\w'), (match) => match.group(0)!.toUpperCase());
  }
}
