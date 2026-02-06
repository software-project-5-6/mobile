import 'api_service.dart';

class InvitationService {
  final ApiService _api = ApiService();

  // Send an invitation
  Future<void> sendInvitation(String projectId, String email, String role) async {
    try {
      await _api.post('/projects/$projectId/invitations', {
        'email': email,
        'role': role,
      });
    } catch (e) {
      print("Error sending invitation: $e");
      throw e;
    }
  }

  // Get pending invitations (You will need this for the list later)
  Future<List<dynamic>> getPendingInvitations(String projectId) async {
    try {
      final data = await _api.get('/projects/$projectId/invitations?status=PENDING');
      return data as List<dynamic>;
    } catch (e) {
      return [];
    }
  }
}