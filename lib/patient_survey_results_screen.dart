import 'package:flutter/material.dart';
import 'models/patient.dart';
import 'appointment_scheduling_screen.dart';

class PatientSurveyResultsScreen extends StatelessWidget {
  final Patient patient;

  const PatientSurveyResultsScreen({super.key, required this.patient});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            // Header with DSC logo and title
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0029B2), Color(0xFF000074)],
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
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
                        child: Text(
                          'PATIENT SURVEY RESULTS\nAFPHSC',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Survey Results
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Patient Information Section
                    _buildSectionCard('Patient Information', [
                      _buildInfoRow('Name:', patient.fullName),
                      _buildInfoRow('Serial Number:', patient.serialNumber),
                      _buildInfoRow('Unit Assignment:', patient.unitAssignment),
                      _buildInfoRow('Email:', patient.email),
                      _buildInfoRow('Phone:', patient.phone),
                    ]),

                    const SizedBox(height: 20),

                    // Classification Section
                    _buildSectionCard('Classification', [
                      _buildInfoRow('Status:', _getPatientClassification()),
                    ]),

                    const SizedBox(height: 20),

                    // Self-Assessment Results
                    _buildSectionCard('Self-Assessment Dental Survey Results', [
                      _buildSurveyResultRow(
                        'Tooth Conditions:',
                        _getToothConditions(),
                      ),
                      _buildSurveyResultRow(
                        'Tartar/Calculus Level:',
                        _getTartarLevel(),
                      ),
                      _buildSurveyResultRow(
                        'Tooth Pain:',
                        _getYesNoAnswer(true),
                      ),
                      _buildSurveyResultRow(
                        'Tooth Sensitivity:',
                        _getYesNoAnswer(false),
                      ),
                      _buildSurveyResultRow(
                        'Damaged Fillings:',
                        _getDamagedFillings(),
                      ),
                      _buildSurveyResultRow(
                        'Missing Teeth:',
                        _getYesNoAnswer(true),
                      ),
                      _buildSurveyResultRow(
                        'Need Dentures:',
                        _getYesNoAnswer(false),
                      ),
                    ]),

                    const SizedBox(height: 20),

                    // Emergency Contact Section
                    _buildSectionCard('Emergency Contact', [
                      _buildInfoRow(
                        'Emergency Contact:',
                        patient.emergencyContact,
                      ),
                      _buildInfoRow('Emergency Phone:', patient.emergencyPhone),
                    ]),

                    const SizedBox(height: 20),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.arrow_back),
                            label: const Text('Back to Dashboard'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[600],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              _showTreatmentPlanDialog(context);
                            },
                            icon: const Icon(Icons.medical_services),
                            label: const Text('Create Treatment Plan'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0029B2),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
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
    );
  }

  Widget _buildSectionCard(String title, List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0029B2),
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSurveyResultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 150,
              child: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0029B2),
                ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getPatientClassification() {
    // Simulate patient classification based on unit assignment
    if (patient.unitAssignment.contains('Military')) {
      return 'Active Military Personnel';
    } else if (patient.unitAssignment.contains('AV/HR')) {
      return 'Civilian Staff';
    } else if (patient.unitAssignment.contains('Emergency')) {
      return 'Emergency Services Staff';
    } else {
      return 'Healthcare Personnel';
    }
  }

  String _getToothConditions() {
    // Simulate survey answers based on patient data
    List<String> conditions = [];
    if (patient.medicalHistory.contains('dental') ||
        patient.medicalHistory.isEmpty) {
      conditions.add('Decayed tooth identified');
    }
    if (patient.allergies.isNotEmpty) {
      conditions.add('Worn down tooth noted');
    }
    return conditions.isEmpty
        ? 'No tooth conditions reported'
        : conditions.join(', ');
  }

  String _getTartarLevel() {
    // Simulate tartar level based on patient history
    if (patient.medicalHistory.contains('good') ||
        patient.medicalHistory.isEmpty) {
      return 'Mild tartar deposits';
    } else {
      return 'Moderate tartar buildup';
    }
  }

  String _getYesNoAnswer(bool value) {
    return value ? 'Yes' : 'No';
  }

  String _getDamagedFillings() {
    // Simulate filling condition
    return patient.allergies.isNotEmpty
        ? 'Damaged filling detected'
        : 'No damaged fillings';
  }

  void _showTreatmentPlanDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Row(
            children: [
              Icon(Icons.medical_services, color: Colors.blue[600], size: 28),
              const SizedBox(width: 12),
              const Text('Treatment Plan'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Recommended treatment plan for ${patient.fullName}:'),
              const SizedBox(height: 12),
              const Text('• Dental cleaning and scaling'),
              const Text('• Cavity treatment'),
              const Text('• Follow-up examination in 6 months'),
              const SizedBox(height: 12),
              Text(
                'Estimated duration: 2-3 visits',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Navigate to appointment scheduling screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AppointmentSchedulingScreen(
                      patient: patient,
                      treatmentPlan: const [
                        'Dental cleaning and scaling',
                        'Cavity treatment',
                        'Follow-up examination in 6 months',
                      ],
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0029B2),
                foregroundColor: Colors.white,
              ),
              child: const Text('Create Plan'),
            ),
          ],
        );
      },
    );
  }
}
