import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/appointment.dart';
import '../models/treatment_record.dart';
import '../models/emergency_record.dart';
import 'api_service.dart';

class PatientHistoryService {
  static final PatientHistoryService _instance =
      PatientHistoryService._internal();
  factory PatientHistoryService() => _instance;
  PatientHistoryService._internal();

  Future<Map<String, dynamic>> getPatientHistory(
      String patientId, String token) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/patients/$patientId/history'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['history'];
      } else {
        throw Exception(
            'Failed to load patient history: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching patient history: $e');
    }
  }

  // Parse survey data into a readable format
  Map<String, dynamic> parseSurveyData(Map<String, dynamic> surveyData) {
    final parsed = <String, dynamic>{};

    // Map the standardized survey format to readable questions
    final questionMap = {
      'question1': 'Do you experience tooth pain or discomfort?',
      'question2': 'Do you have bleeding gums?',
      'question3': 'Do you have bad breath?',
      'question4': 'Do you have loose teeth?',
      'question5': 'Do you have difficulty chewing?',
      'question6': 'Do you experience jaw pain?',
      'question7': 'Do you have dry mouth?',
      'question8': 'Do you have visible cavities?',
    };

    surveyData.forEach((key, value) {
      if (questionMap.containsKey(key)) {
        parsed[questionMap[key]!] = value ?? 'Not specified';
      } else {
        parsed[key] = value;
      }
    });

    return parsed;
  }

  // Convert appointment data to Appointment objects
  List<Appointment> parseAppointments(List<dynamic> appointmentsData) {
    return appointmentsData
        .map((apt) => Appointment(
              id: apt['id'],
              patientId: apt['patientId'] ?? '',
              service: apt['service'],
              date: DateTime.parse(apt['date']),
              timeSlot: apt['timeSlot'],
              status: AppointmentStatus.values.firstWhere(
                (e) => e.name == apt['status'],
                orElse: () => AppointmentStatus.scheduled,
              ),
              notes: apt['notes'],
              createdAt: DateTime.parse(apt['createdAt']),
            ))
        .toList();
  }

  // Convert treatment data to TreatmentRecord objects
  List<TreatmentRecord> parseTreatments(List<dynamic> treatmentsData) {
    return treatmentsData
        .map((tr) => TreatmentRecord(
              id: tr['id'],
              patientId: tr['patientId'] ?? '',
              appointmentId: tr['appointmentId'] ?? '',
              treatmentType: tr['treatmentType'],
              description: tr['description'],
              treatmentDate: DateTime.parse(tr['treatmentDate']),
              procedures: List<String>.from(tr['procedures'] ?? []),
              notes: tr['notes'],
              prescription: tr['prescription'],
              createdAt: DateTime.parse(tr['createdAt']),
            ))
        .toList();
  }

  // Convert emergency data to EmergencyRecord objects
  List<EmergencyRecord> parseEmergencies(List<dynamic> emergenciesData) {
    return emergenciesData
        .map((er) => EmergencyRecord(
              id: er['id'],
              patientId: er['patientId'] ?? '',
              reportedAt: DateTime.parse(er['reportedAt']),
              type: EmergencyType.values.firstWhere(
                (e) => e.name == er['type'],
                orElse: () => EmergencyType.other,
              ),
              priority: EmergencyPriority.values.firstWhere(
                (e) => e.name == er['priority'],
                orElse: () => EmergencyPriority.standard,
              ),
              status: EmergencyStatus.values.firstWhere(
                (e) => e.name == er['status'],
                orElse: () => EmergencyStatus.reported,
              ),
              description: er['description'],
              painLevel: er['painLevel'] ?? 0,
              symptoms: List<String>.from(er['symptoms'] ?? []),
              location: er['location'],
              handledBy: er['handledBy'],
              resolvedAt: er['resolvedAt'] != null
                  ? DateTime.parse(er['resolvedAt'])
                  : null,
              resolution: er['resolution'],
            ))
        .toList();
  }
}
