import 'dart:convert';
import 'package:http/http.dart' as http;
import '../user_state_manager.dart';
import '../config/app_config.dart';

class SurveyService {
  static final SurveyService _instance = SurveyService._internal();
  factory SurveyService() => _instance;
  SurveyService._internal();

  // Use centralized configuration instead of hardcoded localhost
  static String get baseUrl => AppConfig.apiBaseUrl;

  // Get auth token from UserStateManager
  String? _getAuthToken() {
    return UserStateManager().patientToken;
  }

  static Future<Map<String, dynamic>> submitSurvey(
      Map<String, dynamic> surveyData, String token) async {
    try {
      print('🔍 SurveyService: Starting API submission...');
      print('🔍 SurveyService: URL: $baseUrl/surveys');
      print('🔍 SurveyService: Token: $token');
      print('🔍 SurveyService: Survey data keys: ${surveyData.keys.toList()}');

      // Wrap survey data in the expected structure for the backend
      final requestBody = {'surveyData': surveyData};

      print(
          '🔍 SurveyService: Request body structure: ${requestBody.keys.toList()}');

      final response = await http.post(
        Uri.parse('$baseUrl/surveys'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      print('🔍 SurveyService: Response status: ${response.statusCode}');
      print('🔍 SurveyService: Response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final result = jsonDecode(response.body);
        print('✅ SurveyService: Submission successful');
        return result;
      } else {
        print(
            '❌ SurveyService: Submission failed with status ${response.statusCode}');
        throw Exception(
            'Failed to submit survey: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ SurveyService: Exception occurred: $e');
      throw Exception('Failed to submit survey: $e');
    }
  }

  // Get patient's survey data
  Future<Map<String, dynamic>> getSurveyData() async {
    try {
      final token = _getAuthToken();
      final authToken = token ?? 'kiosk_token';

      final response = await http.get(
        Uri.parse('$baseUrl/surveys'),
        headers: {
          'Authorization': 'Bearer $authToken',
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
      final authToken = token ?? 'kiosk_token';

      final response = await http.get(
        Uri.parse('$baseUrl/surveys/status'),
        headers: {
          'Authorization': 'Bearer $authToken',
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
      final authToken = token ?? 'kiosk_token';

      final response = await http.delete(
        Uri.parse('$baseUrl/surveys'),
        headers: {
          'Authorization': 'Bearer $authToken',
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
