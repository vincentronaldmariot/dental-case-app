import 'package:flutter/foundation.dart';

class UserStateManager extends ChangeNotifier {
  static final UserStateManager _instance = UserStateManager._internal();
  factory UserStateManager() => _instance;
  UserStateManager._internal();

  bool _isSurveyCompleted = false;
  bool _isFirstTimeUser = true;
  bool _isAdminLoggedIn = false;
  bool _isClientLoggedIn = false;
  bool _isGuestUser = false;

  bool get isSurveyCompleted => _isSurveyCompleted;
  bool get isFirstTimeUser => _isFirstTimeUser;
  bool get isAdminLoggedIn => _isAdminLoggedIn;
  bool get isClientLoggedIn => _isClientLoggedIn;
  bool get isGuestUser => _isGuestUser;

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
}
