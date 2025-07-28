import 'package:flutter/material.dart';
import 'lib/services/print_service.dart';

void main() {
  runApp(const PrintTestApp());
}

class PrintTestApp extends StatelessWidget {
  const PrintTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Print Test',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const PrintTestScreen(),
    );
  }
}

class PrintTestScreen extends StatelessWidget {
  const PrintTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Sample survey data for testing
    final testSurveyData = {
      'patient_info': {
        'name': 'John Doe',
        'serial_number': 'SN123456',
        'unit_assignment': 'Unit A',
        'contact_number': '+1234567890',
        'email': 'john.doe@example.com',
        'emergency_contact': 'Jane Doe',
        'emergency_phone': '+1234567891',
        'classification': 'Regular Patient',
        'other_classification': '',
        'last_visit': '2024-01-15',
      },
      'tooth_conditions': {
        'decayed_tooth': true,
        'worn_down_tooth': false,
        'impacted_tooth': false,
      },
      'tartar_level': 'moderate',
      'tooth_pain': true,
      'tooth_sensitive': false,
      'damaged_fillings': {
        'broken_tooth': false,
        'broken_pasta': false,
      },
      'need_dentures': false,
      'has_missing_teeth': false,
      'missing_tooth_conditions': {
        'missing_broken_tooth': false,
        'missing_broken_pasta': false,
      },
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Print Functionality Test'),
        backgroundColor: const Color(0xFF0029B2),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Dental Survey Print Test',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0029B2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'This test will generate and print a sample receipt',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () async {
                try {
                  await PrintService.printReceipt(
                    surveyData: testSurveyData,
                    receiptNumber: 'SRV-001',
                  );
                } catch (e) {
                  print('Print error: $e');
                }
              },
              icon: const Icon(Icons.print),
              label: const Text('Test Print Receipt'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0029B2),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Note: This will open the print dialog. You can save as PDF or print to a physical printer.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
