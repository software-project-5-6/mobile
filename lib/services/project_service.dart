
import 'package:flutter/foundation.dart';

import 'api_service.dart';

class ProjectService {
  final ApiService _api = ApiService();

  String _encodeId(String id) {
    if (id.trim().isEmpty) {
      throw ArgumentError('ID cannot be empty.');
    }

    return Uri.encodeComponent(id.trim());
  }

  // ==========================================
  // 1. GET ALL PROJECTS
  // ==========================================

  Future<List<dynamic>> getAllProjects() async {
    try {
      final response = await _api.get('/projects');

      if (response is List) {
        return List<dynamic>.from(response);
      }

      throw const FormatException(
        'Expected a list of projects.',
      );
    } catch (e) {
      debugPrint('Fetching projects failed: $e');
      rethrow;
    }
  }

  // ==========================================
  // 2. CREATE PROJECT
  // ==========================================

  Future<void> createProject(
    Map<String, dynamic> projectData,
  ) async {
    try {
      await _api.post(
        '/projects',
        projectData,
      );

      debugPrint('Project created successfully.');
    } catch (e) {
      debugPrint('Creating project failed: $e');
      rethrow;
    }
  }

  // ==========================================
  // 3. UPDATE PROJECT
  // ==========================================

  Future<void> updateProject(
    String id,
    Map<String, dynamic> projectData,
  ) async {
    try {
      final projectId = _encodeId(id);

      await _api.put(
        '/projects/$projectId',
        projectData,
      );

      debugPrint('Project updated successfully.');
    } catch (e) {
      debugPrint('Updating project failed: $e');
      rethrow;
    }
  }

  // ==========================================
  // 4. DELETE PROJECT
  // ==========================================

  Future<void> deleteProject(String id) async {
    try {
      final projectId = _encodeId(id);

      await _api.delete(
        '/projects/$projectId',
      );

      debugPrint('Project deleted successfully.');
    } catch (e) {
      debugPrint('Deleting project failed: $e');
      rethrow;
    }
  }

  // ==========================================
  // 5. GET SINGLE PROJECT DETAILS
  // ==========================================

  Future<Map<String, dynamic>> getProjectById(
    String id,
  ) async {
    try {
      final projectId = _encodeId(id);

      final response = await _api.get(
        '/projects/$projectId',
      );

      if (response is Map) {
        return Map<String, dynamic>.from(
          response,
        );
      }

      throw const FormatException(
        'Invalid project details response.',
      );
    } catch (e) {
      debugPrint(
        'Fetching project details failed: $e',
      );
      rethrow;
    }
  }

  // ==========================================
  // 6. REMOVE USER FROM PROJECT
  // ==========================================

  Future<void> removeUserFromProject(
    String projectId,
    String userId,
  ) async {
    try {
      final project = _encodeId(projectId);
      final user = _encodeId(userId);

      await _api.delete(
        '/projects/$project/users/$user',
      );

      debugPrint(
        'User removed from project successfully.',
      );
    } catch (e) {
      debugPrint(
        'Removing project member failed: $e',
      );
      rethrow;
    }
  }
}
