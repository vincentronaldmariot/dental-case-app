import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';

class AuthService {
  static const String _baseUrl = ApiService.baseUrl;

  /// Authenticate admin user with backend API
  static Future<Map<String, dynamic>> authenticateAdmin(
    String username,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/admin/login'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'token': data['token'],
          'admin': data['admin'],
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Authentication failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  /// Validate admin token
  static Future<bool> validateToken(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/admin/validate'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Logout admin user
  static Future<bool> logoutAdmin(String token) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/admin/logout'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Get admin profile information
  static Future<Map<String, dynamic>> getAdminProfile(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/admin/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'error': 'Failed to fetch profile'};
      }
    } catch (e) {
      return {'error': 'Network error: ${e.toString()}'};
    }
  }
}
