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

    // Test backend connection with better error handling
    await _checkBackendConnection();

    print(
        'ApiService initialized with token: ${_token != null ? 'present' : 'none'}');
    print('Offline mode: $_offlineMode');
  }

  // Check backend connection with retry logic
  static Future<void> _checkBackendConnection() async {
    int retryCount = 0;
    const maxRetries = 3;

    while (retryCount < maxRetries) {
      try {
        print('🔄 Checking backend connection (attempt ${retryCount + 1})...');

        final response = await http.get(
          Uri.parse('http://localhost:3000/health'),
          headers: {'Content-Type': 'application/json'},
        ).timeout(const Duration(seconds: 5));

        if (response.statusCode == 200) {
          _offlineMode = false;
          print('✅ Backend connection successful');

          // If we were offline before, try to sync local data
          if (retryCount > 0) {
            print('🔄 Backend is back online, syncing local data...');
            await syncAllLocalAppointments();
          }
          return;
        } else {
          print('⚠️ Backend responded with status: ${response.statusCode}');
          _offlineMode = true;
        }
      } catch (e) {
        print('❌ Backend connection attempt ${retryCount + 1} failed: $e');
        _offlineMode = true;
      }

      retryCount++;
      if (retryCount < maxRetries) {
        print('⏳ Retrying in 2 seconds...');
        await Future.delayed(const Duration(seconds: 2));
      }
    }

    print(
        '❌ Backend unavailable after $maxRetries attempts, running in offline mode');
  }

  // Manual connection check and sync
  static Future<bool> checkConnectionAndSync() async {
    print('🔄 Manual connection check and sync...');

    try {
      final response = await http.get(
        Uri.parse('http://localhost:3000/health'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        _offlineMode = false;
        print('✅ Backend is online, syncing local data...');
        await syncAllLocalAppointments();
        return true;
      } else {
        _offlineMode = true;
        print('⚠️ Backend responded with status: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      _offlineMode = true;
      print('❌ Backend connection failed: $e');
      return false;
    }
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
  static Future<Map<String, dynamic>?> authenticatePatient(
      String email, String password) async {
    if (_offlineMode) {
      // Offline mode - validate credentials
      await Future.delayed(const Duration(milliseconds: 500));

      // Check if this is a valid demo account
      if (email == 'demo@dental.com' && password == 'demo123') {
        const patientId = 'offline_demo_user';
        await _storeToken('offline_token_$patientId');

        _localData[patientId] = {
          'id': patientId,
          'email': email,
          'firstName': 'Demo',
          'lastName': 'User',
          'phone': '123-456-7890',
        };

        return {
          'token': 'offline_token_$patientId',
          'patientId': patientId,
        };
      }

      // For any other credentials, authentication fails
      return null;
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
        return {
          'token': token,
          'patient': patientData, // Return the full patient data
        };
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
      await Future.delayed(const Duration(milliseconds: 500));

      // Check if email already exists
      for (final existingPatient in _localData.values) {
        if (existingPatient['email'] == patient.email) {
          throw Exception('Email already registered');
        }
      }

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

  /// Unified authentication for admin and patient
  static Future<Map<String, dynamic>?> authenticateUser(
      String emailOrUsername, String password) async {
    if (_offlineMode) {
      // Offline mode - only allow demo patient
      await Future.delayed(const Duration(milliseconds: 500));
      if (emailOrUsername == 'demo@dental.com' && password == 'demo123') {
        const patientId = 'offline_demo_user';
        await _storeToken('offline_token_$patientId');
        _localData[patientId] = {
          'id': patientId,
          'email': emailOrUsername,
          'firstName': 'Demo',
          'lastName': 'User',
          'phone': '123-456-7890',
          'type': 'patient',
        };
        return {
          'token': 'offline_token_$patientId',
          'user': _localData[patientId],
        };
      }
      return null;
    }

    try {
      print('Authenticating user: $emailOrUsername');
      // Try admin login first
      final adminResponse = await http.post(
        Uri.parse('$baseUrl/auth/admin/login'),
        headers: _headers,
        body: json.encode({
          'username': emailOrUsername,
          'password': password,
        }),
      );
      print('Admin login response status: ${adminResponse.statusCode}');
      print('Admin login response body: ${adminResponse.body}');
      if (adminResponse.statusCode == 200) {
        final data = json.decode(adminResponse.body);
        final token = data['token'];
        final user = data['admin'] ?? data['user'] ?? {};
        user['type'] = 'admin';
        await _storeToken(token);
        return {
          'token': token,
          'user': user,
        };
      }
      // If not admin, try patient login
      final patientResponse = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: _headers,
        body: json.encode({
          'email': emailOrUsername,
          'password': password,
        }),
      );
      print('Patient login response status: ${patientResponse.statusCode}');
      print('Patient login response body: ${patientResponse.body}');
      if (patientResponse.statusCode == 200) {
        final data = json.decode(patientResponse.body);
        final token = data['token'];
        final user = data['patient'] ?? data['user'] ?? {};
        user['type'] = 'patient';
        await _storeToken(token);
        return {
          'token': token,
          'user': user,
        };
      }
      // If both fail, return null
      return null;
    } catch (e) {
      print('Unified authentication error: ${e.toString()}');
      return null;
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
          dateOfBirth: DateTime.now().subtract(const Duration(days: 365 * 25)),
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

  /// Admin: Get any patient's dental survey
  static Future<Map<String, dynamic>?> getPatientSurveyAsAdmin(String patientId,
      {String? email}) async {
    try {
      final uri = email != null && email.isNotEmpty
          ? Uri.parse(
              '$baseUrl/admin/surveys/$patientId?email=${Uri.encodeComponent(email)}')
          : Uri.parse('$baseUrl/admin/surveys/$patientId');
      final response = await http.get(
        uri,
        headers: _headers,
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['survey'];
      } else if (response.statusCode == 404) {
        return null;
      } else {
        _handleError(response);
        return null;
      }
    } catch (e) {
      print('Admin get patient survey error: $e');
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

      // Try to sync to database when online
      _trySyncToDatabase(patientId, appointmentData);
      return;
    }

    try {
      print('Saving appointment for patient: $patientId');

      final response = await http.post(
        Uri.parse('$baseUrl/appointments'),
        headers: _headers,
        body: json.encode({
          'service': appointmentData['service'],
          'appointmentDate':
              appointmentData['date'], // This should now be YYYY-MM-DD format
          'timeSlot': appointmentData['timeSlot'],
          'doctorName': appointmentData['doctorName'],
          'notes': appointmentData['notes'],
        }),
      );

      print('Appointment save response status: ${response.statusCode}');
      print('Appointment save response body: ${response.body}');

      if (response.statusCode == 201) {
        print('Appointment saved successfully to database');
      } else {
        _handleError(response);
      }
    } catch (e) {
      print('Save appointment error: $e');
      // Fallback to local storage if API fails
      final prefs = await SharedPreferences.getInstance();
      final appointmentId =
          'offline_apt_${DateTime.now().millisecondsSinceEpoch}';
      appointmentData['id'] = appointmentId;
      await prefs.setString(
          'appointment_$appointmentId', json.encode(appointmentData));
      print('Appointment saved locally as fallback: $appointmentId');
    }
  }

  /// Try to sync local appointments to database
  static Future<void> _trySyncToDatabase(
      String patientId, Map<String, dynamic> appointmentData) async {
    try {
      // Test if backend is now available
      final healthResponse = await http.get(
        Uri.parse('http://localhost:3000/health'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));

      if (healthResponse.statusCode == 200) {
        print('🔄 Backend available, syncing appointment to database...');

        final response = await http.post(
          Uri.parse('$baseUrl/appointments'),
          headers: _headers,
          body: json.encode({
            'service': appointmentData['service'],
            'appointmentDate':
                appointmentData['date'], // This should now be YYYY-MM-DD format
            'timeSlot': appointmentData['timeSlot'],
            'doctorName': appointmentData['doctorName'],
            'notes': appointmentData['notes'],
          }),
        );

        if (response.statusCode == 201) {
          print('✅ Appointment synced to database successfully');
          // Remove from local storage after successful sync
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('appointment_${appointmentData['id']}');
        } else {
          print('⚠️ Failed to sync appointment: ${response.statusCode}');
        }
      }
    } catch (e) {
      print('🔄 Sync attempt failed: $e');
    }
  }

  /// Sync all local appointments to database
  static Future<void> syncAllLocalAppointments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      final appointmentKeys =
          keys.where((key) => key.startsWith('appointment_')).toList();

      if (appointmentKeys.isEmpty) {
        print('No local appointments to sync');
        return;
      }

      print('🔄 Syncing ${appointmentKeys.length} local appointments...');

      for (final key in appointmentKeys) {
        final appointmentJson = prefs.getString(key);
        if (appointmentJson != null) {
          final appointmentData = json.decode(appointmentJson);
          await _trySyncToDatabase(
              appointmentData['patientId'] ?? 'unknown', appointmentData);
        }
      }

      print('✅ Local appointment sync completed');
    } catch (e) {
      print('❌ Error syncing local appointments: $e');
    }
  }

  /// Get appointments for patient
  static Future<List<Map<String, dynamic>>> getAppointments(
      String patientId) async {
    print('🌐 ApiService.getAppointments called - Offline mode: $_offlineMode');
    if (_offlineMode) {
      // Offline mode - return mock appointments
      print('📱 Returning mock appointment for offline mode');
      return [
        {
          'id': 'offline_apt_1',
          'patient_id': patientId,
          'service': 'General Checkup',
          'appointment_date':
              DateTime.now().add(const Duration(days: 7)).toIso8601String(),
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

        print('📊 Backend returned ${appointments.length} appointments');
        for (int i = 0; i < appointments.length; i++) {
          final apt = appointments[i];
          print(
              '   Appointment $i: ID=${apt['id']}, PatientID=${apt['patientId']}, Status=${apt['status']}, Service=${apt['service']}');
        }

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

  /// Admin: Get appointments for a patient
  static Future<List<Map<String, dynamic>>> getAppointmentsAsAdmin(
      String patientId) async {
    final response = await http.get(
      Uri.parse(
          'http://localhost:3000/api/admin/patients/$patientId/appointments'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data['appointments'] ?? []);
    } else {
      throw Exception(
          'Failed to fetch appointments as admin: ${response.body}');
    }
  }

  /// Update appointment notes as admin
  static Future<void> updateAppointmentNotesAsAdmin(
      String appointmentId, String notes) async {
    final response = await http.put(
      Uri.parse('$baseUrl/admin/appointments/$appointmentId/update'),
      headers: _headers,
      body: json.encode({'notes': notes}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update appointment notes: \n${response.body}');
    }
  }

  /// Cancel appointment as admin with note
  static Future<void> cancelAppointmentAsAdmin(
      String appointmentId, String note) async {
    final response = await http.post(
      Uri.parse('$baseUrl/admin/appointments/$appointmentId/cancel'),
      headers: _headers,
      body: json.encode({'note': note}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to cancel appointment: \n${response.body}');
    }
  }

  /// Rebook appointment as admin (reschedule date/time/service)
  static Future<void> rebookAppointmentAsAdmin(String appointmentId,
      {String? service, String? date, String? timeSlot}) async {
    final response = await http.put(
      Uri.parse('$baseUrl/admin/appointments/$appointmentId/rebook'),
      headers: _headers,
      body: json.encode({
        if (service != null) 'service': service,
        if (date != null) 'date': date,
        if (timeSlot != null) 'time_slot': timeSlot,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to rebook appointment: \n${response.body}');
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
