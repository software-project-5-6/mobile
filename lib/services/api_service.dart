import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';

class ApiService {
  // REPLACE '10.0.2.2' with your actual backend IP
  static const String baseUrl = "http://10.0.2.2:8080/api/v1";

  // --- CHANGED: Made this PUBLIC (removed the underscore) ---
  Future<String?> getIdToken() async {
    try {
      final session = await Amplify.Auth.fetchAuthSession();
      final cognitoSession = session as CognitoAuthSession;
      return cognitoSession.userPoolTokensResult.value.idToken.raw;
    } catch (e) {
      print("Error fetching token: $e");
      return null;
    }
  }

  // --- GET Request ---
  Future<dynamic> get(String endpoint) async {
    final token = await getIdToken(); // Updated to call public method
    final response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token', 
      },
    );
    return _handleResponse(response);
  }

  // --- POST Request ---
  Future<dynamic> post(String endpoint, Map<String, dynamic> data) async {
    final token = await getIdToken(); // Updated to call public method
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

  // --- PUT Request ---
  Future<dynamic> put(String endpoint, Map<String, dynamic> data) async {
    final token = await getIdToken(); // Updated to call public method
    final response = await http.put(
      Uri.parse('$baseUrl$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );
    return _handleResponse(response);
  }

  // --- DELETE Request ---
  Future<dynamic> delete(String endpoint) async {
    final token = await getIdToken(); // Updated to call public method
    final response = await http.delete(
      Uri.parse('$baseUrl$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return _handleResponse(response);
  }

  // --- Error Handling ---
  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return {};

      // FIX: Check if the response is explicitly plain text
      final contentType = response.headers['content-type'] ?? '';
      if (contentType.contains('text/plain')) {
        return response.body; // Return the raw text immediately
      }

      // If it's not plain text, decode it as JSON
      try {
        return jsonDecode(response.body);
      } catch (e) {
        // Fallback just in case the Content-Type header was missing
        return response.body; 
      }
      
    } else if (response.statusCode == 401) {
      print("Unauthorized! Token might be expired.");
      throw Exception("Unauthorized");
    } else {
      throw Exception("Error: ${response.statusCode} - ${response.body}");
    }
  }
}