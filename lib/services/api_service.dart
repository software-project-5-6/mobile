
import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/api_constants.dart';

class ApiService {
  // Hosted Spring Boot Backend
  static const String baseUrl =
      '${ApiConstants.baseUrl}/api/v1';

  static const Duration _requestTimeout =
      Duration(seconds: 60);

  // ==========================================
  // GET SUPABASE ACCESS TOKEN
  // ==========================================

  Future<String> getIdToken() async {
    final auth = Supabase.instance.client.auth;

    var session = auth.currentSession;

    if (session == null) {
      throw StateError(
        'No active session. Please login first.',
      );
    }

    // Refresh the token only when necessary
    if (session.isExpired) {
      try {
        final response = await auth.refreshSession();
        session = response.session;
      } on AuthException catch (e) {
        throw StateError(
          'Session refresh failed: ${e.message}',
        );
      }
    }

    if (session == null ||
        session.isExpired ||
        session.accessToken.isEmpty) {
      throw StateError(
        'Session expired. Please login again.',
      );
    }

    return session.accessToken;
  }

  // ==========================================
  // GENERATE AUTHENTICATED HEADERS
  // ==========================================

  Future<Map<String, String>> getHeaders() async {
    final token = await getIdToken();

    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ==========================================
  // BUILD API URL
  // ==========================================

  Uri _buildUri(String endpoint) {
    final path = endpoint.startsWith('/')
        ? endpoint
        : '/$endpoint';

    return Uri.parse('$baseUrl$path');
  }

  // ==========================================
  // GET REQUEST
  // ==========================================

  Future<dynamic> get(String endpoint) async {
    return _sendRequest(
      'GET',
      endpoint,
    );
  }

  // ==========================================
  // POST REQUEST
  // ==========================================

  Future<dynamic> post(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    return _sendRequest(
      'POST',
      endpoint,
      data: data,
    );
  }

  // ==========================================
  // PUT REQUEST
  // ==========================================

  Future<dynamic> put(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    return _sendRequest(
      'PUT',
      endpoint,
      data: data,
    );
  }

  // ==========================================
  // DELETE REQUEST
  // ==========================================

  Future<dynamic> delete(String endpoint) async {
    return _sendRequest(
      'DELETE',
      endpoint,
    );
  }

  // ==========================================
  // CENTRALIZED HTTP REQUEST HANDLER
  // ==========================================

  Future<dynamic> _sendRequest(
    String method,
    String endpoint, {
    Map<String, dynamic>? data,
  }) async {
    final headers = await getHeaders();
    final uri = _buildUri(endpoint);

    try {
      late final http.Response response;

      switch (method) {
        case 'GET':
          response = await http
              .get(uri, headers: headers)
              .timeout(_requestTimeout);
          break;

        case 'POST':
          response = await http
              .post(
                uri,
                headers: headers,
                body: jsonEncode(data),
              )
              .timeout(_requestTimeout);
          break;

        case 'PUT':
          response = await http
              .put(
                uri,
                headers: headers,
                body: jsonEncode(data),
              )
              .timeout(_requestTimeout);
          break;

        case 'DELETE':
          response = await http
              .delete(uri, headers: headers)
              .timeout(_requestTimeout);
          break;

        default:
          throw ArgumentError(
            'Unsupported HTTP method: $method',
          );
      }

      return _handleResponse(response);
    } on TimeoutException {
      throw Exception(
        'Request timed out. Please try again.',
      );
    } on http.ClientException {
      throw Exception(
        'Network error. Please check your internet connection.',
      );
    }
  }

  // ==========================================
  // RESPONSE HANDLING
  // ==========================================

  dynamic _handleResponse(http.Response response) {
    final statusCode = response.statusCode;

    if (statusCode >= 200 && statusCode < 300) {
      if (response.body.isEmpty) {
        return {};
      }

      final contentType =
          response.headers['content-type'] ?? '';

      if (contentType.contains('text/plain')) {
        return response.body;
      }

      try {
        return jsonDecode(response.body);
      } on FormatException {
        return response.body;
      }
    }

    if (statusCode == 401) {
      throw Exception(
        'Unauthorized (401). Please login again '
        'or check backend JWT configuration.',
      );
    }

    if (statusCode == 403) {
      throw Exception(
        'Forbidden (403). You do not have '
        'permission to access this resource.',
      );
    }

    if (statusCode == 404) {
      throw Exception(
        'Resource not found (404).',
      );
    }

    if (statusCode >= 500) {
      throw Exception(
        'Server error ($statusCode). '
        'Please try again later.',
      );
    }

    throw Exception(
      'Request failed with status code $statusCode.',
    );
  }
}
