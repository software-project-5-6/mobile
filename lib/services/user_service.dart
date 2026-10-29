import 'package:flutter/foundation.dart';
import 'api_service.dart';

class UserService {
  // Centralized API Service
  final ApiService _apiService = ApiService();

  // ==========================================
  // 1. GET ALL USERS
  // ==========================================

  Future<List<dynamic>> getAllUsers() async {
    try {
      // ApiService automatically handles:
      // - Supabase JWT access token
      // - Token refresh
      // - Authorization header
      // - Hosted Render backend URL
      // - HTTP error handling

      final response = await _apiService.get('/users');

      if (response is List) {
        return List<dynamic>.from(response);
      }

      throw const FormatException(
        'Invalid response format: expected a list of users.',
      );
    } catch (e) {
      debugPrint('UserService: Failed to load users.');
      rethrow;
    }
  }

  // ==========================================
  // 2. DELETE USER
  // ==========================================

  Future<void> deleteUser(String userId) async {
    final id = userId.trim();

    if (id.isEmpty) {
      throw ArgumentError('User ID cannot be empty.');
    }

    try {
      // Encode user ID safely for URL path
      final encodedId = Uri.encodeComponent(id);

      // JWT and error handling are managed
      // automatically by ApiService.

      await _apiService.delete('/users/$encodedId');

      debugPrint('User deleted successfully.');
    } catch (e) {
      debugPrint('UserService: Failed to delete user.');
      rethrow;
    }
  }
}
