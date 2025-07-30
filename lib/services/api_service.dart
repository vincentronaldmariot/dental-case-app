import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/patient.dart';
import '../config/app_config.dart';
import '../user_state_manager.dart';

class ApiService {
  // Use configuration for server URL
  static String get baseUrl => AppConfig.apiBaseUrl;

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
    print('Server URL: ${AppConfig.serverUrl}');
  }

  // Check backend connection with retry logic
  static Future<void> _checkBackendConnection() async {
    int retryCount = 0;
    const maxRetries = AppConfig.maxRetryAttempts;

    while (retryCount < maxRetries) {
      try {
        print('🔄 Checking backend connection (attempt ${retryCount + 1})...');

        // Use the health check URL from config
        final response = await http.get(
          Uri.parse(AppConfig.healthCheckUrl),
          headers: {'Content-Type': 'application/json'},
        ).timeout(Duration(seconds: AppConfig.connectionTimeoutSeconds));

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
        print('⏳ Retrying in ${AppConfig.retryDelaySeconds} seconds...');
        await Future.delayed(Duration(seconds: AppConfig.retryDelaySeconds));
      }
    }

    print(
        '❌ Backend unavailable after $maxRetries attempts, running in offline mode');
  }

  static Future<bool> checkConnection() async {
    try {
      final response = await http
          .get(
            Uri.parse(AppConfig.healthCheckUrl),
          )
          .timeout(Duration(seconds: AppConfig.connectionTimeoutSeconds));

      if (response.statusCode == 200) {
        _offlineMode = false;
        return true;
      } else {
        _offlineMode = true;
        return false;
      }
    } catch (e) {
      _offlineMode = true;
      return false;
    }
  }

  static Future<bool> checkConnectionAndSync() async {
    try {
      final isOnline = await checkConnection();
      if (isOnline) {
        await syncAllLocalAppointments();
        return true;
      }
      return false;
    } catch (e) {
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

  // Get headers with patient authentication
  static Map<String, String> _getPatientHeaders() {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    final patientToken = UserStateManager().patientToken;
    print('🔑 Patient token: ${patientToken != null ? 'present' : 'null'}');
    if (patientToken != null) {
      headers['Authorization'] = 'Bearer $patientToken';
      print('🔑 Using patient token for authentication');
    } else {
      print('⚠️ No patient token available');
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
        Uri.parse('${AppConfig.serverUrl}/api/auth/register'),
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
        Uri.parse('${AppConfig.serverUrl}/api/auth/admin/login'),
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
        print(
            '✅ Admin token stored in ApiService: ${token != null ? 'present' : 'null'}');
        return {
          'token': token,
          'user': user,
        };
      }
      // If not admin, try patient login
      final patientResponse = await http.post(
        Uri.parse('${AppConfig.serverUrl}/api/auth/login'),
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
        // Don't store patient token in API service - it should be stored in UserStateManager
        // await _storeToken(token);
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
        headers: _getPatientHeaders(),
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
        headers: _getPatientHeaders(),
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
        headers: _getPatientHeaders(),
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
        headers: _getPatientHeaders(),
        body: json.encode({
          'service': appointmentData['service'],
          'appointmentDate':
              appointmentData['date'], // This should now be YYYY-MM-DD format
          'timeSlot': appointmentData['timeSlot'],
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
        Uri.parse(AppConfig.healthCheckUrl),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));

      if (healthResponse.statusCode == 200) {
        print('🔄 Backend available, syncing appointment to database...');

        final response = await http.post(
          Uri.parse('$baseUrl/appointments'),
          headers: _getPatientHeaders(),
          body: json.encode({
            'service': appointmentData['service'],
            'appointmentDate':
                appointmentData['date'], // This should now be YYYY-MM-DD format
            'timeSlot': appointmentData['timeSlot'],
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
    print('🔑 Current patient ID: $patientId');
    print(
        '🔑 Patient token available: ${UserStateManager().patientToken != null}');

    if (_offlineMode) {
      // Offline mode - return empty list instead of mock data
      print('📱 Offline mode: returning empty appointment list');
      return [];
    }

    try {
      print('Getting appointments for patient: $patientId');

      final response = await http.get(
        Uri.parse('$baseUrl/patients/$patientId/history'),
        headers: _getPatientHeaders(),
      );

      print('Get appointments response status: ${response.statusCode}');
      print('Get appointments response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('📊 Parsed response data: $data');
        final history = data['history'];
        final appointments = history['appointments'] as List;

        print('📊 Backend returned ${appointments.length} appointments');
        for (int i = 0; i < appointments.length; i++) {
          final apt = appointments[i];
          print(
              '   Appointment $i: ID=${apt['id']}, Status=${apt['status']}, Service=${apt['service']}');
        }

        return appointments
            .map((apt) => {
                  'id': apt['id'],
                  'patient_id': patientId,
                  'service': apt['service'],
                  'date': apt['date'],
                  'time_slot': apt['timeSlot'],
                  'status': apt['status'],
                  'notes': apt['notes'],
                  'created_at': apt['createdAt'],
                })
            .toList();
      } else if (response.statusCode == 500) {
        // Fallback: Try to get appointments through admin endpoint
        print('⚠️ Patient history endpoint failed, trying fallback method...');
        return await _getAppointmentsFallback(patientId);
      } else {
        _handleError(response);
        return [];
      }
    } catch (e) {
      print('Get appointments error: $e');
      // Try fallback method on any error
      print('⚠️ Trying fallback method due to error...');
      return await _getAppointmentsFallback(patientId);
    }
  }

  /// Fallback method to get appointments when patient history fails
  static Future<List<Map<String, dynamic>>> _getAppointmentsFallback(
      String patientId) async {
    try {
      print('🔄 Using fallback method to get appointments...');

      // Try to get notifications to infer appointments
      final notificationsResponse = await http.get(
        Uri.parse('$baseUrl/patients/$patientId/notifications'),
        headers: _getPatientHeaders(),
      );

      List<Map<String, dynamic>> allAppointments = [];

      if (notificationsResponse.statusCode == 200) {
        final notificationsData = json.decode(notificationsResponse.body);
        final notifications = notificationsData['notifications'] as List? ?? [];

        print('📋 Found ${notifications.length} notifications');

        // Look for approval notifications to infer approved appointments
        final appointmentNotifications = notifications.where((notification) {
          return notification['type'] == 'appointment_approved' ||
              notification['type'] == 'appointment_completed';
        }).toList();

        print(
            '✅ Found ${appointmentNotifications.length} appointment notifications');

        // Convert appointment notifications to appointment data
        for (final notification in appointmentNotifications) {
          final message = notification['message'] as String;

          // Parse appointment details from notification message
          // Example: "Your appointment for Teeth Whitening on 8/1/2025 at 08:00 AM has been approved!"
          final serviceRegex = RegExp(r'for (.+?) on');
          final dateRegex = RegExp(r'on (\d{1,2}/\d{1,2}/\d{4})');
          final timeRegex = RegExp(r'at (\d{1,2}:\d{2}(?: [AP]M)?)');

          final serviceMatch = serviceRegex.firstMatch(message);
          final dateMatch = dateRegex.firstMatch(message);
          final timeMatch = timeRegex.firstMatch(message);

          if (serviceMatch != null && dateMatch != null) {
            final service = serviceMatch.group(1);
            final dateStr = dateMatch.group(1);
            final timeSlot = timeMatch != null ? timeMatch.group(1) : '';

            // Parse date
            if (dateStr != null) {
              final dateParts = dateStr.split('/');
              final month = int.parse(dateParts[0]);
              final day = int.parse(dateParts[1]);
              final year = int.parse(dateParts[2]);
              final date = DateTime(year, month, day);

              // Determine status based on notification type
              String appointmentStatus = 'approved'; // default
              if (notification['type'] == 'appointment_completed') {
                appointmentStatus = 'completed';
              }

              allAppointments.add({
                'id': 'inferred_${notification['id']}',
                'patient_id': patientId,
                'service': service,
                'date': date.toIso8601String(),
                'time_slot': timeSlot,
                'status': appointmentStatus,
                'notes': '',
                'created_at': notification['createdAt'],
              });

              print(
                  '✅ Inferred appointment: $service on $dateStr at $timeSlot');
            }
          }
        }
      }

      print(
          '🔄 Fallback method completed, total appointments: ${allAppointments.length}');
      return allAppointments;
    } catch (e) {
      print('❌ Fallback method also failed: $e');
      return [];
    }
  }

  /// Admin: Get appointments for a patient
  static Future<List<Map<String, dynamic>>> getAppointmentsAsAdmin(
      String patientId) async {
    print('🔍 getAppointmentsAsAdmin called for patientId: $patientId');

    // Get admin token from UserStateManager (where it's actually stored)
    final adminToken = UserStateManager().adminToken;
    print(
        '🔑 Admin token from UserStateManager: ${adminToken != null ? 'present' : 'null'}');

    if (adminToken == null) {
      print('❌ No admin token available');
      throw Exception('Admin token not available. Please log in again.');
    }

    final headers = {
      'Authorization': 'Bearer $adminToken',
      'Content-Type': 'application/json',
    };

    print('🔑 Using headers: $headers');

    final response = await http.get(
      Uri.parse(
          '${AppConfig.apiBaseUrl}/admin/patients/$patientId/appointments'),
      headers: headers,
    );

    print('📊 Response status: ${response.statusCode}');
    print('📊 Response body: ${response.body}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final appointments =
          List<Map<String, dynamic>>.from(data['appointments'] ?? []);
      print('✅ Successfully fetched ${appointments.length} appointments');
      return appointments;
    } else {
      print(
          '❌ Failed to fetch appointments: ${response.statusCode} - ${response.body}');
      throw Exception(
          'Failed to fetch appointments as admin: ${response.body}');
    }
  }

  /// Update appointment notes as admin
  static Future<void> updateAppointmentNotesAsAdmin(
      String appointmentId, String notes) async {
    final adminToken = UserStateManager().adminToken;
    if (adminToken == null) {
      throw Exception('Admin token not available. Please log in again.');
    }

    final headers = {
      'Authorization': 'Bearer $adminToken',
      'Content-Type': 'application/json',
    };

    final response = await http.put(
      Uri.parse('$baseUrl/admin/appointments/$appointmentId/update'),
      headers: headers,
      body: json.encode({'notes': notes}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update appointment notes: \n${response.body}');
    }
  }

  /// Cancel appointment as admin with note
  static Future<void> cancelAppointmentAsAdmin(
      String appointmentId, String note) async {
    final adminToken = UserStateManager().adminToken;
    if (adminToken == null) {
      throw Exception('Admin token not available. Please log in again.');
    }

    final headers = {
      'Authorization': 'Bearer $adminToken',
      'Content-Type': 'application/json',
    };

    final response = await http.post(
      Uri.parse('$baseUrl/admin/appointments/$appointmentId/cancel'),
      headers: headers,
      body: json.encode({'note': note}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to cancel appointment: \n${response.body}');
    }
  }

  /// Rebook appointment as admin (reschedule date/time/service)
  static Future<void> rebookAppointmentAsAdmin(String appointmentId,
      {String? service, String? date, String? timeSlot}) async {
    final adminToken = UserStateManager().adminToken;
    if (adminToken == null) {
      throw Exception('Admin token not available. Please log in again.');
    }

    final headers = {
      'Authorization': 'Bearer $adminToken',
      'Content-Type': 'application/json',
    };

    final response = await http.put(
      Uri.parse('$baseUrl/admin/appointments/$appointmentId/rebook'),
      headers: headers,
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

  // EMERGENCY RECORDS API METHODS

  /// Submit emergency record
  static Future<Map<String, dynamic>> submitEmergencyRecord({
    required String emergencyType,
    required String priority,
    required String description,
    required int painLevel,
    required List<String> symptoms,
    String? location,
    bool? dutyRelated,
    String? unitCommand,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/emergency'),
        headers: _headers,
        body: json.encode({
          'emergencyType': emergencyType,
          'priority': priority,
          'description': description,
          'painLevel': painLevel,
          'symptoms': symptoms,
          if (location != null) 'location': location,
          if (dutyRelated != null) 'dutyRelated': dutyRelated,
          if (unitCommand != null) 'unitCommand': unitCommand,
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        print(
            '✅ Emergency record submitted successfully: ${data['emergency']['id']}');
        return data['emergency'];
      } else {
        final errorData = json.decode(response.body);
        throw Exception(
            'Failed to submit emergency record: ${errorData['error'] ?? 'Unknown error'}');
      }
    } catch (e) {
      print('❌ Emergency submission error: $e');
      throw Exception('Failed to submit emergency record: $e');
    }
  }

  /// Get patient's emergency records
  static Future<List<Map<String, dynamic>>> getEmergencyRecords() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/emergency'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final records =
            List<Map<String, dynamic>>.from(data['emergencyRecords'] ?? []);
        print('✅ Retrieved ${records.length} emergency records');
        return records;
      } else {
        final errorData = json.decode(response.body);
        throw Exception(
            'Failed to get emergency records: ${errorData['error'] ?? 'Unknown error'}');
      }
    } catch (e) {
      print('❌ Get emergency records error: $e');
      throw Exception('Failed to get emergency records: $e');
    }
  }

  /// Admin: Get all emergency records
  static Future<List<Map<String, dynamic>>>
      getAllEmergencyRecordsAsAdmin() async {
    try {
      final adminToken = UserStateManager().adminToken;
      if (adminToken == null) {
        throw Exception('Admin token not available. Please log in again.');
      }

      final headers = {
        'Authorization': 'Bearer $adminToken',
        'Content-Type': 'application/json',
      };

      final response = await http.get(
        Uri.parse('$baseUrl/admin/emergency'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final records =
            List<Map<String, dynamic>>.from(data['emergencyRecords'] ?? []);
        print('✅ Retrieved ${records.length} emergency records as admin');
        return records;
      } else {
        final errorData = json.decode(response.body);
        throw Exception(
            'Failed to get emergency records as admin: ${errorData['error'] ?? 'Unknown error'}');
      }
    } catch (e) {
      print('❌ Get emergency records as admin error: $e');
      throw Exception('Failed to get emergency records as admin: $e');
    }
  }

  /// Admin: Update emergency record status
  static Future<void> updateEmergencyRecordStatusAsAdmin(
      String emergencyId, String status,
      {String? handledBy, String? resolution, String? notes}) async {
    try {
      final adminToken = UserStateManager().adminToken;
      if (adminToken == null) {
        throw Exception('Admin token not available. Please log in again.');
      }

      final headers = {
        'Authorization': 'Bearer $adminToken',
        'Content-Type': 'application/json',
      };

      final response = await http.put(
        Uri.parse('$baseUrl/admin/emergency/$emergencyId/status'),
        headers: headers,
        body: json.encode({
          'status': status,
          if (handledBy != null) 'handledBy': handledBy,
          if (resolution != null) 'resolution': resolution,
          if (notes != null) 'notes': notes,
        }),
      );

      if (response.statusCode == 200) {
        print('✅ Emergency record status updated successfully');
      } else {
        final errorData = json.decode(response.body);
        throw Exception(
            'Failed to update emergency status: ${errorData['error'] ?? 'Unknown error'}');
      }
    } catch (e) {
      print('❌ Update emergency status error: $e');
      throw Exception('Failed to update emergency status: $e');
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
