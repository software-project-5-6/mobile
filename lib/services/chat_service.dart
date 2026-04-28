import 'api_service.dart';

class ChatService {
  final ApiService _api = ApiService();

  // Ask a question about a specific project
  Future<Map<String, dynamic>> askProject(String projectId, Map<String, dynamic> questionPayload) async {
    try {
      // React: api.post(`/chat/ask`, askObject);
      // We inject the projectId into the payload to match React's {projectId, conversationId, question}
      questionPayload['projectId'] = int.tryParse(projectId) ?? projectId; 
      
      final response = await _api.post('/chat/ask', questionPayload);
      return response as Map<String, dynamic>;
    } catch (e) {
      print("Error asking project AI: $e");
      rethrow;
    }
  }

  // Create a new conversation
  Future<String> createConversation(Map<String, dynamic> newConversationObject) async {
    try {
      // React: api.post(`/chat/conversation`, newConvesationObject);
      
      // Ensure projectId is an integer if your backend expects it
      if (newConversationObject['projectId'] is String) {
        newConversationObject['projectId'] = int.tryParse(newConversationObject['projectId']) ?? newConversationObject['projectId'];
      }

      final response = await _api.post('/chat/conversation', newConversationObject);
      return response.toString(); 
    } catch (e) {
      print("Error creating conversation: $e");
      rethrow;
    }
  }

 // Get All Conversations for a Project
  Future<dynamic> getAllConversationsForProject(String projectId) async {
    try {
      final response = await _api.get('/chat/conversations/$projectId');
      return response; // Return dynamic instead of forcing a Map
    } catch (e) {
      print("Error fetching project conversations: $e");
      rethrow;
    }
  }

  // Get All Messages for a Conversation
  Future<dynamic> getAllMessagesForConversation(String conversationId) async {
    try {
      final response = await _api.get('/chat/conversation/$conversationId');
      return response; // Return dynamic instead of forcing a Map
    } catch (e) {
      print("Error fetching messages for conversation: $e");
      rethrow;
    }
  }

  // Delete All Messages for a Conversation
  Future<dynamic> deleteAllMessagesForConversation(String conversationId) async {
    try {
      // React: api.delete(`/chat/conversation/${conversationId}`);
      final response = await _api.delete('/chat/conversation/$conversationId');
      return response;
    } catch (e) {
      print("Error deleting messages for conversation: $e");
      rethrow;
    }
  }
}