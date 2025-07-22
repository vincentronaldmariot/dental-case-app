import 'dart:convert';
import 'package:http/http.dart' as http;
import '../user_state_manager.dart';

class SurveyService {
  static final SurveyService _instance = SurveyService._internal();
  factory SurveyService() => _instance;
  SurveyService._internal();

  static const String baseUrl = 'http://localhost:3000/api';

  // Get auth token from UserStateManager
  String? _getAuthToken() {
    return UserStateManager().patientToken;
  }

  // Submit or update survey data
  Future<Map<String, dynamic>> submitSurvey(
      Map<String, dynamic> surveyData) async {
    try {
      final token = _getAuthToken();
      print('Survey service - Token found: ${token != null}');
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/surveys'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'surveyData': surveyData,
        }),
      );

      print('Survey API response status: ${response.statusCode}');
      print('Survey API response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'],
          'survey': data['survey'],
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['error'] ?? 'Failed to submit survey',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Get patient's survey data
  Future<Map<String, dynamic>> getSurveyData() async {
    try {
      final token = _getAuthToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/surveys'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'survey': data['survey'],
        };
      } else if (response.statusCode == 404) {
        return {
          'success': false,
          'message': 'No survey found',
          'notFound': true,
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['error'] ?? 'Failed to retrieve survey',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Check if patient has completed survey
  Future<Map<String, dynamic>> checkSurveyStatus() async {
    try {
      final token = _getAuthToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/surveys/status'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'hasCompletedSurvey': data['hasCompletedSurvey'],
          'surveyInfo': data['surveyInfo'],
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['error'] ?? 'Failed to check survey status',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Delete survey (for testing purposes)
  Future<Map<String, dynamic>> deleteSurvey() async {
    try {
      final token = _getAuthToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/surveys'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'],
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['error'] ?? 'Failed to delete survey',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }
}
