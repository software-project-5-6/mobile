import 'api_service.dart';

class ChatService {
  final ApiService _api = ApiService();

  // Ask a question about a specific project
  Future<Map<String, dynamic>> askProject(String projectId, Map<String, dynamic> question) async {
    try {
      // Matches the React code: api.post(`/projects/ask/${projectId}`, question)
      final response = await _api.post('/projects/ask/$projectId', question);
      return response as Map<String, dynamic>;
    } catch (e) {
      print("Error asking project AI: $e");
      rethrow;
    }
  }
}