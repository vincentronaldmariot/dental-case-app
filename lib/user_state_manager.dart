import 'package:flutter/foundation.dart';
import 'models/patient.dart';

class UserStateManager extends ChangeNotifier {
  static final UserStateManager _instance = UserStateManager._internal();
  factory UserStateManager() => _instance;
  UserStateManager._internal();

  bool _isSurveyCompleted = false;
  bool _isFirstTimeUser = true;
  bool _isAdminLoggedIn = false;
  bool _isClientLoggedIn = false;
  bool _isPatientLoggedIn = false;
  Patient? _currentPatient;
  String? _patientToken;
  String? _adminToken;

  bool get isSurveyCompleted => _isSurveyCompleted;
  bool get isFirstTimeUser => _isFirstTimeUser;
  bool get isAdminLoggedIn => _isAdminLoggedIn;
  bool get isClientLoggedIn => _isClientLoggedIn;
  bool get isPatientLoggedIn => _isPatientLoggedIn;
  Patient? get currentPatient => _currentPatient;
  String? get patientToken => _patientToken;
  String? get adminToken => _adminToken;

  // Get current patient ID (for use in database operations)
  String get currentPatientId {
    final id = _currentPatient?.id ?? 'guest';
    print('🔍 UserStateManager.currentPatientId called: "$id"');
    print('🔍 _currentPatient: $_currentPatient');
    print('🔍 _currentPatient?.id: ${_currentPatient?.id}');
    return id;
  }

  void completeSurvey() {
    _isSurveyCompleted = true;
    _isFirstTimeUser = false;
    notifyListeners();
  }

  void updateSurveyStatus(bool hasCompletedSurvey) {
    _isSurveyCompleted = hasCompletedSurvey;
    if (hasCompletedSurvey) {
      _isFirstTimeUser = false;
    }
    notifyListeners();
  }

  void markAsReturningUser() {
    _isFirstTimeUser = false;
    notifyListeners();
  }

  void resetUserState() {
    _isSurveyCompleted = false;
    _isFirstTimeUser = true;
    _isAdminLoggedIn = false;
    _isClientLoggedIn = false;
    _isPatientLoggedIn = false;
    _currentPatient = null;
    notifyListeners();
  }

  void loginAsAdmin() {
    _isAdminLoggedIn = true;
    _isClientLoggedIn = false;
    notifyListeners();
  }

  void loginAsClient() {
    _isClientLoggedIn = true;
    _isAdminLoggedIn = false;
    _isFirstTimeUser = false;
    notifyListeners();
  }

  void logoutAdmin() {
    _isAdminLoggedIn = false;
    _adminToken = null;
    notifyListeners();
  }

  void setAdminToken(String token) {
    _adminToken = token;
    notifyListeners();
  }

  void logoutClient() {
    _isSurveyCompleted = false;
    _isFirstTimeUser = true;
    _isClientLoggedIn = false;
    notifyListeners();
  }

  bool canBookAppointment() {
    return !_isFirstTimeUser || _isSurveyCompleted;
  }

  // Patient authentication methods
  void setCurrentPatient(Patient patient) {
    print('🔍 setCurrentPatient called with patient: ${patient.id}');
    print('🔍 Patient details: ${patient.firstName} ${patient.lastName}');
    _currentPatient = patient;
    _isPatientLoggedIn = true;
    _isClientLoggedIn = false;
    _isAdminLoggedIn = false;
    notifyListeners();
    print(
        '🔍 Patient set successfully. Current patient ID: ${_currentPatient?.id}');
  }

  void setPatientToken(String token) {
    _patientToken = token;
    notifyListeners();
  }

  void logoutPatient() {
    _currentPatient = null;
    _isPatientLoggedIn = false;
    _isSurveyCompleted = false;
    _isFirstTimeUser = true;
    _patientToken = null;
    notifyListeners();
  }

  bool canBookAppointmentAsPatient() {
    return _isPatientLoggedIn && _currentPatient != null;
  }

  String get patientFullName {
    if (_currentPatient != null) {
      return '${_currentPatient!.firstName} ${_currentPatient!.lastName}';
    }
    return 'Guest User';
  }

  String get patientEmail {
    return _currentPatient?.email ?? 'guest@dental-clinic.mil';
  }
}
