
import 'package:flutter/foundation.dart';

import 'api_service.dart';

class InvitationService {
  final ApiService _api = ApiService();

  // ==========================================
  // 1. SEND INVITATION
  // ==========================================

  Future<void> sendInvitation(
    String projectId,
    String email,
    String role,
  ) async {
    final cleanProjectId = projectId.trim();
    final cleanEmail = email.trim();
    final cleanRole = role.trim();

    if (cleanProjectId.isEmpty ||
        cleanEmail.isEmpty ||
        cleanRole.isEmpty) {
      throw ArgumentError(
        'Project ID, email and role are required.',
      );
    }

    try {
      await _api.post('/invitations', {
        'projectId':
            int.tryParse(cleanProjectId) ??
            cleanProjectId,
        'email': cleanEmail,
        'role': cleanRole,
      });

      debugPrint('Invitation sent successfully.');
    } catch (e) {
      debugPrint('Sending invitation failed: $e');
      rethrow;
    }
  }

  // ==========================================
  // 2. GET PENDING INVITATIONS
  // ==========================================

  Future<List<dynamic>> getPendingInvitations(
    String projectId,
  ) async {
    if (projectId.trim().isEmpty) {
      throw ArgumentError('Project ID is required.');
    }

    try {
      final id = Uri.encodeComponent(
        projectId.trim(),
      );

      final response = await _api.get(
        '/invitations/project/$id',
      );

      if (response is List) {
        return List<dynamic>.from(response);
      }

      throw const FormatException(
        'Expected a list of invitations.',
      );
    } catch (e) {
      debugPrint(
        'Fetching pending invitations failed: $e',
      );
      rethrow;
    }
  }

  // ==========================================
  // 3. REVOKE INVITATION
  // ==========================================

  Future<void> revokeInvitation(int inviteId) async {
    if (inviteId <= 0) {
      throw ArgumentError(
        'Invalid invitation ID.',
      );
    }

    try {
      await _api.delete(
        '/invitations/$inviteId',
      );

      debugPrint(
        'Invitation revoked successfully.',
      );
    } catch (e) {
      debugPrint('Revoking invitation failed: $e');
      rethrow;
    }
  }
}
