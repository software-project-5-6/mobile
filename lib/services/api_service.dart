import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';

class ApiService {
  // REPLACE '10.0.2.2' with your actual backend IP if running locally.
  // Android Emulator uses 10.0.2.2 to access localhost.
  static const String baseUrl = "http://10.0.2.2:8080/api/v1"; 

  // Helper to get the token (Mimics your axios interceptor)
  Future<String?> _getIdToken() async {
    try {
      final session = await Amplify.Auth.fetchAuthSession();
      final cognitoSession = session as CognitoAuthSession;
      return cognitoSession.userPoolTokensResult.value.idToken.raw;
    } catch (e) {
      print("Error fetching token: $e");
      return null;
    }
  }

  // GET Request
  Future<dynamic> get(String endpoint) async {
    final token = await _getIdToken();
    final response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token', // Attach Token
      },
    );
    return _handleResponse(response);
  }

  // POST Request
  Future<dynamic> post(String endpoint, Map<String, dynamic> data) async {
    final token = await _getIdToken();
    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );
    return _handleResponse(response);
  }

  // Handle Errors (Like your axios interceptor)
  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 401) {
      print("Unauthorized! Redirect to login.");
      // Trigger logout logic here if needed
      throw Exception("Unauthorized");
    } else {
      throw Exception("Error: ${response.statusCode} - ${response.body}");
    }
  }
}