import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';

class UserService {
  // Use 10.0.2.2 if testing on an Android Emulator, or your local network IP for physical devices
  final String baseUrl = "http://10.0.2.2:8080/api/v1";

  // --- FETCH SECURE HEADERS ---
  Future<Map<String, String>> _getHeaders() async {
    String token = "";
    
    try {
      // 1. Fetch the current logged-in user's session from AWS Amplify
      final session = await Amplify.Auth.fetchAuthSession() as CognitoAuthSession;
      
      // 2. Extract the ID Token (idToken contains your user roles like APP_ADMIN)
      token = session.userPoolTokensResult.value.idToken.raw; 
      
    } catch (e) {
      print("Error fetching AWS Auth Token: $e");
    }

    return {
      'Content-Type': 'application/json',
      // 3. Attach the token to pass the Spring Boot security
      'Authorization': 'Bearer $token', 
    };
  }

  // --- Get All Users ---
  Future<List<dynamic>> getAllUsers() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse('$baseUrl/users'), headers: headers);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load users: ${response.statusCode}');
      }
    } catch (error) {
      print("Error fetching users: $error");
      throw error;
    }
  }

  // --- Delete User ---
  Future<void> deleteUser(String userId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/users/$userId'),
        headers: headers,
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete user: ${response.statusCode}');
      }
    } catch (error) {
      print("Error deleting user: $error");
      throw error;
    }
  }
}