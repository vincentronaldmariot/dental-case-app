import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/patient.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:3000/api';
  static String? _token;
  static bool _offlineMode = false;
  static final Map<String, dynamic> _localData = {};

  // Initialize service
  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');

    // Test backend connection
    try {
      final response = await http.get(
        Uri.parse('http://localhost:3000/health'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(Duration(seconds: 5));

      _offlineMode = response.statusCode != 200;
      if (!_offlineMode) {
        print('✅ Backend connection successful');
      }
    } catch (e) {
      _offlineMode = true;
      print('❌ Backend unavailable, running in offline mode: $e');
    }

    print(
        'ApiService initialized with token: ${_token != null ? 'present' : 'none'}');
    print('Offline mode: $_offlineMode');
  }

  // Get headers with authentication
  static Map<String, String> get _headers {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }

    return headers;
  }

  // Store authentication token
  static Future<void> _storeToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  // Clear authentication token
  static Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  // Handle API errors
  static void _handleError(http.Response response) {
    final data = json.decode(response.body);
    final error = data['error'] ?? 'Unknown error occurred';
    throw Exception(error);
  }

  // AUTHENTICATION METHODS

  /// Authenticate patient with email and password
  static Future<String?> authenticatePatient(
      String email, String password) async {
    if (_offlineMode) {
      // Offline mode - simulate login
      await Future.delayed(Duration(milliseconds: 500));
      final patientId = 'offline_${email.hashCode}';
      await _storeToken('offline_token_$patientId');

      _localData[patientId] = {
        'id': patientId,
        'email': email,
        'firstName': 'Demo',
        'lastName': 'User',
        'phone': '123-456-7890',
      };

      return patientId;
    }

    try {
      print('Authenticating patient: $email');

      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: _headers,
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      print('Auth response status: ${response.statusCode}');
      print('Auth response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final token = data['token'];
        final patientData = data['patient'];

        await _storeToken(token);

        print('Authentication successful for patient: ${patientData['id']}');
        return patientData['id'];
      } else {
        _handleError(response);
        return null;
      }
    } catch (e) {
      print('Authentication error: $e');
      return null;
    }
  }

  /// Register new patient
  static Future<String?> registerPatient(
      Patient patient, String password) async {
    if (_offlineMode) {
      // Offline mode - simulate registration
      await Future.delayed(Duration(milliseconds: 500));
      final patientId = 'offline_${patient.email.hashCode}';
      await _storeToken('offline_token_$patientId');

      _localData[patientId] = {
        'id': patientId,
        'email': patient.email,
        'firstName': patient.firstName,
        'lastName': patient.lastName,
        'phone': patient.phone,
      };

      return patientId;
    }

    try {
      print('Registering patient: ${patient.email}');

      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: _headers,
        body: json.encode({
          'firstName': patient.firstName,
          'lastName': patient.lastName,
          'email': patient.email,
          'password': password,
          'phone': patient.phone,
          'dateOfBirth': patient.dateOfBirth.toIso8601String(),
          'address': patient.address,
          'emergencyContact': patient.emergencyContact,
          'emergencyPhone': patient.emergencyPhone,
          'medicalHistory': patient.medicalHistory,
          'allergies': patient.allergies,
          'serialNumber': patient.serialNumber,
          'unitAssignment': patient.unitAssignment,
          'classification': patient.classification,
          'otherClassification': patient.otherClassification,
        }),
      );

      print('Registration response status: ${response.statusCode}');
      print('Registration response body: ${response.body}');

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        final token = data['token'];
        final patientData = data['patient'];

        await _storeToken(token);

        print('Registration successful for patient: ${patientData['id']}');
        return patientData['id'];
      } else {
        _handleError(response);
        return null;
      }
    } catch (e) {
      print('Registration error: $e');
      throw Exception('Registration failed: $e');
    }
  }

  // PATIENT METHODS

  /// Get patient profile
  static Future<Patient?> getPatient(String patientId) async {
    if (_offlineMode) {
      // Offline mode - return mock data
      final patientData = _localData[patientId];
      if (patientData != null) {
        return Patient(
          id: patientData['id'],
          firstName: patientData['firstName'] ?? 'Demo',
          lastName: patientData['lastName'] ?? 'User',
          email: patientData['email'] ?? 'demo@example.com',
          phone: patientData['phone'] ?? '123-456-7890',
          passwordHash: 'hashed',
          dateOfBirth: DateTime.now().subtract(Duration(days: 365 * 25)),
          address: '123 Demo Street',
          emergencyContact: 'Emergency Contact',
          emergencyPhone: '098-765-4321',
        );
      }
      return null;
    }

    try {
      print('Getting patient profile for: $patientId');

      final response = await http.get(
        Uri.parse('$baseUrl/patients/profile'),
        headers: _headers,
      );

      print('Get patient response status: ${response.statusCode}');
      print('Get patient response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final patient = data['profile'];

        print('Patient data from API: $patient');

        return Patient.fromMap(patient);
      } else {
        _handleError(response);
        return null;
      }
    } catch (e) {
      print('Get patient error: $e');
      return null;
    }
  }

  // SURVEY METHODS

  /// Save dental survey
  static Future<void> saveDentalSurvey(
      String patientId, Map<String, dynamic> surveyData) async {
    if (_offlineMode) {
      // Offline mode - store locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('survey_$patientId', json.encode(surveyData));
      print('Survey saved locally for patient: $patientId');
      return;
    }

    try {
      print('Saving dental survey for patient: $patientId');

      final response = await http.post(
        Uri.parse('$baseUrl/surveys'),
        headers: _headers,
        body: json.encode({
          'surveyData': surveyData,
        }),
      );

      print('Survey save response status: ${response.statusCode}');
      print('Survey save response body: ${response.body}');

      if (response.statusCode == 200) {
        print('Survey saved successfully');
      } else {
        _handleError(response);
      }
    } catch (e) {
      print('Save survey error: $e');
      throw Exception('Failed to save dental survey: $e');
    }
  }

  /// Get dental survey
  static Future<Map<String, dynamic>?> getDentalSurvey(String patientId) async {
    if (_offlineMode) {
      // Offline mode - get from local storage
      final prefs = await SharedPreferences.getInstance();
      final surveyJson = prefs.getString('survey_$patientId');
      if (surveyJson != null) {
        final surveyData = json.decode(surveyJson);
        return {
          'patient_id': patientId,
          'survey_data': surveyData,
          'completed_at': DateTime.now().toIso8601String(),
        };
      }
      return null;
    }

    try {
      print('Getting dental survey for patient: $patientId');

      final response = await http.get(
        Uri.parse('$baseUrl/surveys'),
        headers: _headers,
      );

      print('Get survey response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final survey = data['survey'];

        return {
          'patient_id': survey['patientId'],
          'survey_data': survey['surveyData'],
          'completed_at': survey['completedAt'],
        };
      } else if (response.statusCode == 404) {
        return null;
      } else {
        _handleError(response);
        return null;
      }
    } catch (e) {
      print('Get survey error: $e');
      return null;
    }
  }

  // APPOINTMENT METHODS

  /// Save appointment
  static Future<void> saveAppointment(
      String patientId, Map<String, dynamic> appointmentData) async {
    if (_offlineMode) {
      // Offline mode - store locally
      final prefs = await SharedPreferences.getInstance();
      final appointmentId =
          'offline_apt_${DateTime.now().millisecondsSinceEpoch}';
      appointmentData['id'] = appointmentId;
      await prefs.setString(
          'appointment_$appointmentId', json.encode(appointmentData));
      print('Appointment saved locally: $appointmentId');
      return;
    }

    try {
      print('Saving appointment for patient: $patientId');

      final response = await http.post(
        Uri.parse('$baseUrl/appointments'),
        headers: _headers,
        body: json.encode({
          'service': appointmentData['service'],
          'appointmentDate': appointmentData['date'],
          'timeSlot': appointmentData['timeSlot'],
          'doctorName': appointmentData['doctorName'],
          'notes': appointmentData['notes'],
        }),
      );

      print('Appointment save response status: ${response.statusCode}');
      print('Appointment save response body: ${response.body}');

      if (response.statusCode == 201) {
        print('Appointment saved successfully');
      } else {
        _handleError(response);
      }
    } catch (e) {
      print('Save appointment error: $e');
      throw Exception('Failed to save appointment: $e');
    }
  }

  /// Get appointments for patient
  static Future<List<Map<String, dynamic>>> getAppointments(
      String patientId) async {
    if (_offlineMode) {
      // Offline mode - return mock appointments
      return [
        {
          'id': 'offline_apt_1',
          'patient_id': patientId,
          'service': 'General Checkup',
          'appointment_date':
              DateTime.now().add(Duration(days: 7)).toIso8601String(),
          'time_slot': '10:00 AM',
          'doctor_name': 'Dr. Demo',
          'status': 'pending',
          'notes': 'Regular checkup',
          'created_at': DateTime.now().toIso8601String(),
        }
      ];
    }

    try {
      print('Getting appointments for patient: $patientId');

      final response = await http.get(
        Uri.parse('$baseUrl/appointments'),
        headers: _headers,
      );

      print('Get appointments response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final appointments = data['appointments'] as List;

        return appointments
            .map((apt) => {
                  'id': apt['id'],
                  'patient_id': apt['patientId'],
                  'service': apt['service'],
                  'appointment_date': apt['appointmentDate'],
                  'time_slot': apt['timeSlot'],
                  'doctor_name': apt['doctorName'],
                  'status': apt['status'],
                  'notes': apt['notes'],
                  'created_at': apt['createdAt'],
                })
            .toList();
      } else {
        _handleError(response);
        return [];
      }
    } catch (e) {
      print('Get appointments error: $e');
      return [];
    }
  }

  // UTILITY METHODS

  /// Check if user is authenticated
  static bool get isAuthenticated => _token != null;

  /// Get current authentication token
  static String? get currentToken => _token;

  /// Check if running in offline mode
  static bool get isOfflineMode => _offlineMode;
}
