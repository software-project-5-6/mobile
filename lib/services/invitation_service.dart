import 'api_service.dart';

class InvitationService {
  final ApiService _api = ApiService();

  // Send an invitation
  Future<void> sendInvitation(
    String projectId,
    String email,
    String role,
  ) async {
    try {
      print(projectId);
      print(email);
      print(role);

      // Keep this as '/invitations' based on your backend POST mapping
      await _api.post('/invitations', {
        'projectId': projectId,
        'email': email,
        'role': role,
      });
    } catch (e) {
      print("Error sending invitation: $e");
      throw e; // We want the dialog to catch this so it can show the red SnackBar
    }
  }

  // Get pending invitations
  Future<List<dynamic>> getPendingInvitations(String projectId) async {
    try {
      final data = await _api.get(
        '/invitations/project/$projectId',
      );
      return data as List<dynamic>;
    } catch (e) {
      print("Error fetching invitations: $e");
      return [];
    }
  }
  // Revoke an invitation
  Future<void> revokeInvitation(int inviteId) async {
    try {
      await _api.delete('/invitations/$inviteId');
    } catch (e) {
      print("Error revoking invitation: $e");
      throw e;
    }
  }
}