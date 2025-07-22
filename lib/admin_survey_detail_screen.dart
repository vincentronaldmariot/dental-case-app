import 'package:flutter/material.dart';

class AdminSurveyDetailScreen extends StatelessWidget {
  final Map<String, dynamic> surveyData;
  const AdminSurveyDetailScreen({Key? key, required this.surveyData})
      : super(key: key);

  static const Color primaryColor = Color(0xFF0029B2); // Blue
  static const Color secondaryColor = Colors.white; // White

  final List<Map<String, String>> questions = const [
    {'key': 'name', 'label': '1. Name'},
    {'key': 'contact_number', 'label': '2. Contact Number'},
    {'key': 'email', 'label': '3. Email'},
    {'key': 'serial_number', 'label': '4. Serial Number'},
    {'key': 'unit_assignment', 'label': '5. Unit Assignment'},
    {'key': 'classification', 'label': '6. Classification'},
    {'key': 'other_classification', 'label': '7. Other Classification'},
    {'key': 'last_visit', 'label': '8. Last Dental Visit'},
    {'key': 'emergency_contact', 'label': '9. Emergency Contact'},
    {'key': 'emergency_phone', 'label': '10. Emergency Phone'},
    // Add more questions here as needed
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Self-Assessment Survey Details'),
        backgroundColor: primaryColor,
        foregroundColor: secondaryColor,
      ),
      backgroundColor: secondaryColor,
      body: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: questions.length,
        itemBuilder: (context, index) {
          final q = questions[index];
          final answer = (surveyData[q['key']] ?? '').toString();
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: index % 2 == 0
                  ? primaryColor.withOpacity(0.07)
                  : secondaryColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: primaryColor.withOpacity(0.15)),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListTile(
              title: Text(
                q['label']!,
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 6.0),
                child: Text(
                  answer.isNotEmpty ? answer : '—',
                  style: TextStyle(
                    color: answer.isNotEmpty ? Colors.black : Colors.grey,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
