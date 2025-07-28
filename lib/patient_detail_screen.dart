import 'package:flutter/material.dart';

class PatientDetailScreen extends StatefulWidget {
  final dynamic patient;

  const PatientDetailScreen({super.key, required this.patient});

  @override
  State<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<PatientDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final patient = widget.patient;
    final stats = patient['stats'] ?? {};

    return Scaffold(
      backgroundColor: const Color(0xFF0029B2),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0029B2),
        foregroundColor: Colors.white,
        title: Text(
          patient['fullName'] ?? 'Patient Details',
          style: const TextStyle(color: Colors.white),
        ),
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Background with logo
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFF0029B2),
              ),
              child: Stack(
                children: [
                  // Main logo as background
                  Positioned(
                    top: -50,
                    right: -50,
                    child: Opacity(
                      opacity: 0.1,
                      child: Image.asset(
                        'assets/image/main_logo.png',
                        width: 200,
                        height: 200,
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                  // Additional smaller logos for pattern
                  Positioned(
                    bottom: 100,
                    left: -30,
                    child: Opacity(
                      opacity: 0.05,
                      child: Image.asset(
                        'assets/image/main_logo.png',
                        width: 100,
                        height: 100,
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 200,
                    left: -20,
                    child: Opacity(
                      opacity: 0.03,
                      child: Image.asset(
                        'assets/image/main_logo.png',
                        width: 80,
                        height: 80,
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Content
          SingleChildScrollView(
            child: Column(
              children: [
                // Header Section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Color(0xFF0029B2),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        child: Text(
                          (patient['firstName']?[0] ?? '') +
                              (patient['lastName']?[0] ?? ''),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        patient['fullName'] ?? 'Unknown Patient',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        patient['email'] ?? 'N/A',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),

                // Content Section
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Patient Information Section
                      _buildSectionCard(
                        'Patient Information',
                        Icons.person,
                        [
                          _buildInfoRow(
                              'Full Name', patient['fullName'] ?? 'N/A'),
                          _buildInfoRow('Email', patient['email'] ?? 'N/A'),
                          _buildInfoRow('Phone', patient['phone'] ?? 'N/A'),
                          if (patient['dateOfBirth'] != null)
                            _buildInfoRow('Date of Birth',
                                _formatDateOfBirth(patient['dateOfBirth'])),
                          _buildInfoRow(
                              'Address', patient['address'] ?? 'Not provided'),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Military Information Section
                      _buildSectionCard(
                        'Military Information',
                        Icons.military_tech,
                        [
                          if (patient['serialNumber']?.isNotEmpty == true)
                            _buildInfoRow(
                                'Serial Number', patient['serialNumber']),
                          _buildInfoRow('Classification',
                              patient['classification'] ?? 'N/A'),
                          if (patient['otherClassification']?.isNotEmpty ==
                              true)
                            _buildInfoRow('Other Classification',
                                patient['otherClassification']),
                          _buildInfoRow('Unit Assignment',
                              patient['unitAssignment'] ?? 'N/A'),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Registration Information Section
                      _buildSectionCard(
                        'Registration Information',
                        Icons.info,
                        [
                          _buildInfoRow('Patient ID', patient['id'] ?? 'N/A'),
                          _buildInfoRow(
                              'Registered',
                              _formatDateTime(
                                  DateTime.parse(patient['createdAt']))),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Appointments Section
                      if ((patient['appointments'] as List?)?.isNotEmpty ==
                          true) ...[
                        _buildSectionCard(
                          'Appointments (${patient['appointments'].length})',
                          Icons.calendar_today,
                          (patient['appointments'] as List)
                              .map((apt) => _buildAppointmentItem(apt))
                              .toList(),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Survey Section
                      if (patient['survey'] != null) ...[
                        _buildSectionCard(
                          'Dental Survey',
                          Icons.assignment,
                          [_buildSurveyItem(patient['survey'])],
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Emergency Records Section
                      if ((patient['emergencyRecords'] as List?)?.isNotEmpty ==
                          true) ...[
                        _buildSectionCard(
                          'Emergency Records (${patient['emergencyRecords'].length})',
                          Icons.emergency,
                          (patient['emergencyRecords'] as List)
                              .map(
                                  (emergency) => _buildEmergencyItem(emergency))
                              .toList(),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Treatment Records Section
                      if ((patient['treatmentRecords'] as List?)?.isNotEmpty ==
                          true) ...[
                        _buildSectionCard(
                          'Treatment History (${patient['treatmentRecords'].length})',
                          Icons.medical_services,
                          (patient['treatmentRecords'] as List)
                              .map(
                                  (treatment) => _buildTreatmentItem(treatment))
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(String title, IconData icon, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF0029B2), size: 24),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0029B2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
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
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
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
                  color: statusColor.withValues(alpha: 0.1),
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
          const SizedBox(height: 8),
          Text('Date: ${_formatHistoryDate(appointment['appointmentDate'])}'),
          Text('Time: ${appointment['timeSlot'] ?? 'N/A'}'),
          if (appointment['notes']?.isNotEmpty == true)
            Text('Notes: ${appointment['notes']}'),
        ],
      ),
    );
  }

  Widget _buildSurveyItem(dynamic survey) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
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
          const SizedBox(height: 8),
          Text(
              'Completed: ${_formatDateTime(DateTime.parse(survey['completedAt']))}'),
          if (survey['surveyData'] != null) ...[
            const SizedBox(height: 12),
            Text(
              'Survey Data:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.blue[700],
              ),
            ),
            const SizedBox(height: 8),
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
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
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
                  color: urgencyColor.withValues(alpha: 0.1),
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
          const SizedBox(height: 8),
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
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            treatment['treatmentType'] ?? 'N/A',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text('Description: ${treatment['description'] ?? 'N/A'}'),
          Text('Date: ${_formatHistoryDate(treatment['datePerformed'])}'),
          if (treatment['notes']?.isNotEmpty == true)
            Text('Notes: ${treatment['notes']}'),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
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

  String _formatDateOfBirth(dynamic date) {
    if (date == null) return 'N/A';
    try {
      final dateTime = DateTime.parse(date.toString());
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } catch (e) {
      return 'Invalid date';
    }
  }
}
