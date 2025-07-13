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
  bool _isGuestUser = false;
  bool _isPatientLoggedIn = false;
  Patient? _currentPatient;

  bool get isSurveyCompleted => _isSurveyCompleted;
  bool get isFirstTimeUser => _isFirstTimeUser;
  bool get isAdminLoggedIn => _isAdminLoggedIn;
  bool get isClientLoggedIn => _isClientLoggedIn;
  bool get isGuestUser => _isGuestUser;
  bool get isPatientLoggedIn => _isPatientLoggedIn;
  Patient? get currentPatient => _currentPatient;

  // Get current patient ID (for use in database operations)
  String get currentPatientId =>
      _currentPatient?.id ??
      'guest'; // Default to 'guest' for guest/default user

  void completeSurvey() {
    _isSurveyCompleted = true;
    _isFirstTimeUser = false;
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
    _isGuestUser = false;
    _isPatientLoggedIn = false;
    _currentPatient = null;
    notifyListeners();
  }

  void loginAsAdmin() {
    _isAdminLoggedIn = true;
    _isClientLoggedIn = false;
    _isGuestUser = false;
    notifyListeners();
  }

  void loginAsClient() {
    _isClientLoggedIn = true;
    _isGuestUser = false;
    _isAdminLoggedIn = false;
    _isFirstTimeUser = false;
    notifyListeners();
  }

  void continueAsGuest() {
    _isGuestUser = true;
    _isClientLoggedIn = false;
    _isAdminLoggedIn = false;
    notifyListeners();
  }

  void logoutAdmin() {
    _isAdminLoggedIn = false;
    notifyListeners();
  }

  void logoutClient() {
    _isSurveyCompleted = false;
    _isFirstTimeUser = true;
    _isClientLoggedIn = false;
    _isGuestUser = false;
    notifyListeners();
  }

  bool canBookAppointment() {
    return !_isFirstTimeUser || _isSurveyCompleted;
  }

  void updateSurveyStatus(bool isCompleted) {
    _isSurveyCompleted = isCompleted;
    notifyListeners();
  }

  // Patient authentication methods
  void setCurrentPatient(Patient patient) {
    _currentPatient = patient;
    _isPatientLoggedIn = true;
    _isGuestUser = false;
    _isClientLoggedIn = false;
    _isAdminLoggedIn = false;
    notifyListeners();
  }

  void logoutPatient() {
    _currentPatient = null;
    _isPatientLoggedIn = false;
    _isSurveyCompleted = false;
    _isFirstTimeUser = true;
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
