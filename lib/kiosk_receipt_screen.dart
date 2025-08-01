import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:convert';

import 'kiosk_mode_screen.dart';
import 'services/print_service.dart';
import 'services/thermal_print_service.dart';

class KioskReceiptScreen extends StatelessWidget {
  final Map<String, dynamic> surveyData;
  final String receiptNumber;

  const KioskReceiptScreen({
    super.key,
    required this.surveyData,
    required this.receiptNumber,
  });

  // Helper method to format survey data into questions
  List<Map<String, dynamic>> _formatSurveyDataToQuestions(
      Map<String, dynamic> surveyData) {
    final questions = <Map<String, dynamic>>[];

    // Tooth Conditions
    final toothConditions =
        surveyData['tooth_conditions'] as Map<String, dynamic>? ?? {};
    if (toothConditions['decayed_tooth'] != null) {
      questions.add({
        'question': 'Do you have any decayed teeth?',
        'answer': toothConditions['decayed_tooth'] == true ? 'Yes' : 'No',
        'score': toothConditions['decayed_tooth'] == true ? '10' : '0',
      });
    }
    if (toothConditions['worn_down_tooth'] != null) {
      questions.add({
        'question': 'Do you have worn down teeth?',
        'answer': toothConditions['worn_down_tooth'] == true ? 'Yes' : 'No',
        'score': toothConditions['worn_down_tooth'] == true ? '10' : '0',
      });
    }
    if (toothConditions['impacted_tooth'] != null) {
      questions.add({
        'question': 'Do you have impacted wisdom teeth?',
        'answer': toothConditions['impacted_tooth'] == true ? 'Yes' : 'No',
        'score': toothConditions['impacted_tooth'] == true ? '10' : '0',
      });
    }

    // Tartar Level
    final tartarLevel = surveyData['tartar_level'];
    if (tartarLevel != null) {
      questions.add({
        'question': 'What is your tartar level?',
        'answer': tartarLevel.toString(),
        'score': _getTartarScore(tartarLevel.toString()),
      });
    }

    // Tooth Pain
    final toothPain = surveyData['tooth_pain'];
    if (toothPain != null) {
      questions.add({
        'question': 'Do you experience tooth pain?',
        'answer': toothPain == true ? 'Yes' : 'No',
        'score': toothPain == true ? '15' : '0',
      });
    }

    // Tooth Sensitivity
    final toothSensitive = surveyData['tooth_sensitive'];
    if (toothSensitive != null) {
      questions.add({
        'question': 'Do you have sensitive teeth?',
        'answer': toothSensitive == true ? 'Yes' : 'No',
        'score': toothSensitive == true ? '10' : '0',
      });
    }

    // Damaged Fillings
    final damagedFillings =
        surveyData['damaged_fillings'] as Map<String, dynamic>? ?? {};
    if (damagedFillings['broken_tooth'] != null) {
      questions.add({
        'question': 'Do you have broken teeth?',
        'answer': damagedFillings['broken_tooth'] == true ? 'Yes' : 'No',
        'score': damagedFillings['broken_tooth'] == true ? '15' : '0',
      });
    }
    if (damagedFillings['broken_pasta'] != null) {
      questions.add({
        'question': 'Do you have broken fillings?',
        'answer': damagedFillings['broken_pasta'] == true ? 'Yes' : 'No',
        'score': damagedFillings['broken_pasta'] == true ? '10' : '0',
      });
    }

    // Dentures
    final needDentures = surveyData['need_dentures'];
    if (needDentures != null) {
      questions.add({
        'question': 'Do you need dentures?',
        'answer': needDentures == true ? 'Yes' : 'No',
        'score': needDentures == true ? '20' : '0',
      });
    }

    // Missing Teeth
    final hasMissingTeeth = surveyData['has_missing_teeth'];
    if (hasMissingTeeth != null) {
      questions.add({
        'question': 'Do you have missing teeth?',
        'answer': hasMissingTeeth == true ? 'Yes' : 'No',
        'score': hasMissingTeeth == true ? '15' : '0',
      });
    }

    return questions;
  }

  // Helper method to calculate total score
  int _calculateTotalScore(Map<String, dynamic> surveyData) {
    int totalScore = 0;

    // Tooth Conditions
    final toothConditions =
        surveyData['tooth_conditions'] as Map<String, dynamic>? ?? {};
    if (toothConditions['decayed_tooth'] == true) totalScore += 10;
    if (toothConditions['worn_down_tooth'] == true) totalScore += 10;
    if (toothConditions['impacted_tooth'] == true) totalScore += 10;

    // Tartar Level
    final tartarLevel = surveyData['tartar_level'];
    if (tartarLevel != null) {
      totalScore += int.tryParse(_getTartarScore(tartarLevel.toString())) ?? 0;
    }

    // Tooth Pain
    if (surveyData['tooth_pain'] == true) totalScore += 15;

    // Tooth Sensitivity
    if (surveyData['tooth_sensitive'] == true) totalScore += 10;

    // Damaged Fillings
    final damagedFillings =
        surveyData['damaged_fillings'] as Map<String, dynamic>? ?? {};
    if (damagedFillings['broken_tooth'] == true) totalScore += 15;
    if (damagedFillings['broken_pasta'] == true) totalScore += 10;

    // Dentures
    if (surveyData['need_dentures'] == true) totalScore += 20;

    // Missing Teeth
    if (surveyData['has_missing_teeth'] == true) totalScore += 15;

    return totalScore;
  }

  // Helper method to get tartar score
  String _getTartarScore(String tartarLevel) {
    switch (tartarLevel.toLowerCase()) {
      case 'none':
        return '0';
      case 'light':
        return '5';
      case 'moderate':
        return '10';
      case 'heavy':
        return '15';
      default:
        return '0';
    }
  }

  @override
  Widget build(BuildContext context) {
    final patientInfo = surveyData['patient_info'] ?? {};
    final name = patientInfo['name'] ?? 'N/A';
    final serialNumber = patientInfo['serial_number'] ?? 'N/A';
    final unitAssignment = patientInfo['unit_assignment'] ?? 'N/A';
    final classification = patientInfo['classification'] ?? 'N/A';
    final contactNumber = patientInfo['contact_number'] ?? 'N/A';

    // Format survey data into questions and answers
    final questions = _formatSurveyDataToQuestions(surveyData);
    final totalScore = _calculateTotalScore(surveyData).toString();
    final surveyDate =
        surveyData['survey_date'] ?? DateTime.now().toIso8601String();

    // Extract daily counter number from receipt number (e.g., "SRV-001" -> "001")
    final dailyCounter = receiptNumber.split('-').last;

    // Create comprehensive QR code data for survey receipt
    final qrData = {
      'type': 'dental_survey_complete',
      'receipt_number': receiptNumber,
      'daily_counter': dailyCounter,
      'survey_date': surveyDate,
      'total_score': totalScore,
      'patient_info': {
        'name': name,
        'serial_number': serialNumber,
        'unit_assignment': unitAssignment,
        'classification': classification,
        'contact_number': contactNumber,
      },
      'survey_questions': questions
          .map((q) => {
                'question': q['question'] ?? 'Unknown Question',
                'answer': q['answer'] ?? 'No Answer',
                'score': q['score']?.toString() ?? 'N/A',
              })
          .toList(),
      'timestamp': DateTime.now().toIso8601String(),
      'clinic_info': {
        'name': 'Dental Clinic',
        'version': '1.0',
        'qr_type': 'survey_data',
      },
    };

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFF0029B2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.medical_services,
                          color: Color(0xFF0029B2),
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'DENTAL CLINIC',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          Text(
                            'Survey Receipt',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Receipt Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Daily Counter Display
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0029B2),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.format_list_numbered,
                            color: Colors.white,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'TODAY\'S SURVEY #$dailyCounter',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Receipt Card
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Receipt Header
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'SURVEY RECEIPT',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0029B2),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF005800),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    'COMPLETED',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Receipt Number
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.grey[300]!,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.receipt_long,
                                    color: Color(0xFF0029B2),
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Receipt Number',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          receiptNumber,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF0029B2),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Daily Counter: #$dailyCounter',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Patient Information
                            const Text(
                              'PATIENT INFORMATION',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0029B2),
                              ),
                            ),
                            const SizedBox(height: 16),

                            _buildInfoRow('Name', name),
                            _buildInfoRow('Serial Number', serialNumber),
                            _buildInfoRow('Unit Assignment', unitAssignment),
                            _buildInfoRow('Classification', classification),
                            _buildInfoRow('Contact Number', contactNumber),
                            const SizedBox(height: 24),

                            // Timestamp
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.blue[200]!,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    color: Colors.blue[700],
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Completed on: ${DateTime.now().toString().substring(0, 19)}',
                                    style: TextStyle(
                                      color: Colors.blue[700],
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // QR Code for Survey Receipt
                            Center(
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.grey[300]!,
                                        width: 1,
                                      ),
                                    ),
                                    child: QrImageView(
                                      data: jsonEncode(qrData),
                                      version: QrVersions.auto,
                                      size: 150,
                                      backgroundColor: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Scan for complete survey data',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Contains all questions & answers',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Instructions
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.orange[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.orange[200]!,
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.info_outline,
                                        color: Colors.orange[700],
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Next Steps',
                                        style: TextStyle(
                                          color: Colors.orange[700],
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Please present this receipt to the reception desk. Your survey data has been saved and will be reviewed by our dental staff. The kiosk will be ready for the next patient.',
                                    style: TextStyle(
                                      color: Colors.orange[700],
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Action Buttons
                    Column(
                      children: [
                        // Print Options Row
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  try {
                                    // Show loading indicator
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Preparing PDF print...'),
                                        backgroundColor: Colors.blue,
                                        duration: Duration(seconds: 1),
                                      ),
                                    );

                                    // Call the PDF print service
                                    await PrintService.printReceipt(
                                      surveyData: surveyData,
                                      receiptNumber: receiptNumber,
                                    );

                                    // Show success message
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content:
                                              Text('PDF printed successfully!'),
                                          backgroundColor: Colors.green,
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                    }

                                    // After print, return to survey for next patient
                                    Future.delayed(const Duration(seconds: 2),
                                        () {
                                      if (context.mounted) {
                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const KioskModeScreen(),
                                          ),
                                        );
                                      }
                                    });
                                  } catch (e) {
                                    // Show error message
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              'PDF print failed: ${e.toString()}'),
                                          backgroundColor: Colors.red,
                                          duration: const Duration(seconds: 3),
                                        ),
                                      );
                                    }
                                  }
                                },
                                icon: const Icon(Icons.picture_as_pdf),
                                label: const Text('Print PDF'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0029B2),
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  try {
                                    // Show loading indicator
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content:
                                            Text('Preparing thermal print...'),
                                        backgroundColor: Colors.orange,
                                        duration: Duration(seconds: 1),
                                      ),
                                    );

                                    // Call the thermal print service
                                    await ThermalPrintService.showPrintDialog(
                                      context,
                                      {
                                        ...surveyData,
                                        'receipt_number': receiptNumber,
                                      },
                                    );

                                    // Show success message
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content:
                                              Text('Thermal receipt printed!'),
                                          backgroundColor: Colors.green,
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                    }

                                    // After print, return to survey for next patient
                                    Future.delayed(const Duration(seconds: 2),
                                        () {
                                      if (context.mounted) {
                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const KioskModeScreen(),
                                          ),
                                        );
                                      }
                                    });
                                  } catch (e) {
                                    // Show error message
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              'Thermal print failed: ${e.toString()}'),
                                          backgroundColor: Colors.red,
                                          duration: const Duration(seconds: 3),
                                        ),
                                      );
                                    }
                                  }
                                },
                                icon: const Icon(Icons.receipt_long),
                                label: const Text('Thermal Print'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFF6B35),
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Next Patient Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              // Navigate directly to kiosk mode screen (replacing current screen)
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const KioskModeScreen(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.refresh),
                            label: const Text('Next Patient'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF005800),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          const Text(
            ': ',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
