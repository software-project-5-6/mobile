
import 'package:flutter/foundation.dart';

import 'api_service.dart';

class ChatService {
  final ApiService _api = ApiService();

  String _encodeId(String id) {
    if (id.trim().isEmpty) {
      throw ArgumentError('ID cannot be empty.');
    }
    return Uri.encodeComponent(id.trim());
  }

  // ==========================================
  // 1. ASK PROJECT AI
  // ==========================================

  Future<Map<String, dynamic>> askProject(
    String projectId,
    Map<String, dynamic> questionPayload,
  ) async {
    try {
      if (projectId.trim().isEmpty) {
        throw ArgumentError('Project ID is required.');
      }

      // Do not mutate the caller's original Map.
      final payload =
          Map<String, dynamic>.from(questionPayload);

      payload['projectId'] =
          int.tryParse(projectId) ?? projectId;

      final response = await _api.post(
        '/chat/ask',
        payload,
      );

      if (response is Map) {
        return Map<String, dynamic>.from(response);
      }

      throw const FormatException(
        'Invalid AI response format.',
      );
    } catch (e) {
      debugPrint('Project AI request failed: $e');
      rethrow;
    }
  }

  // ==========================================
  // 2. CREATE CONVERSATION
  // ==========================================

  Future<String> createConversation(
    Map<String, dynamic> newConversationObject,
  ) async {
    try {
      final payload = Map<String, dynamic>.from(
        newConversationObject,
      );

      final projectId = payload['projectId'];

      if (projectId is String) {
        payload['projectId'] =
            int.tryParse(projectId) ?? projectId;
      }

      final response = await _api.post(
        '/chat/conversation',
        payload,
      );

      if (response is String) {
        return response;
      }

      if (response is num) {
        return response.toString();
      }

      if (response is Map) {
        final id =
            response['conversationId'] ??
            response['id'];

        if (id != null) {
          return id.toString();
        }
      }

      throw const FormatException(
        'Conversation response does not '
        'contain a valid ID.',
      );
    } catch (e) {
      debugPrint('Create conversation failed: $e');
      rethrow;
    }
  }

  // ==========================================
  // 3. GET PROJECT CONVERSATIONS
  // ==========================================

  Future<dynamic> getAllConversationsForProject(
    String projectId,
  ) async {
    try {
      final id = _encodeId(projectId);

      return await _api.get(
        '/chat/conversations/$id',
      );
    } catch (e) {
      debugPrint(
        'Fetching project conversations failed: $e',
      );
      rethrow;
    }
  }

  // ==========================================
  // 4. GET CONVERSATION MESSAGES
  // ==========================================

  Future<dynamic> getAllMessagesForConversation(
    String conversationId,
  ) async {
    try {
      final id = _encodeId(conversationId);

      return await _api.get(
        '/chat/conversation/$id',
      );
    } catch (e) {
      debugPrint(
        'Fetching conversation messages failed: $e',
      );
      rethrow;
    }
  }

  // ==========================================
  // 5. DELETE CONVERSATION MESSAGES
  // ==========================================

  Future<dynamic> deleteAllMessagesForConversation(
    String conversationId,
  ) async {
    try {
      final id = _encodeId(conversationId);

      return await _api.delete(
        '/chat/conversation/$id',
      );
    } catch (e) {
      debugPrint(
        'Deleting conversation failed: $e',
      );
      rethrow;
    }
  }
}
