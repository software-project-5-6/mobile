import 'api_service.dart';

class ProjectService {
  final ApiService _api = ApiService();

  // 1. Get All Projects
  Future<List<dynamic>> getAllProjects() async {
    try {
      final data = await _api.get('/projects');
      return data as List<dynamic>;
    } catch (e) {
      print("Error fetching projects: $e");
      return [];
    }
  }

  // 2. Create Project
  Future<void> createProject(Map<String, dynamic> projectData) async {
    try {
      await _api.post('/projects', projectData);
    } catch (e) {
      print("Error creating project: $e");
      throw e;
    }
  }

  // 3. Update Project
  Future<void> updateProject(String id, Map<String, dynamic> projectData) async {
    try {
      await _api.put('/projects/$id', projectData);
    } catch (e) {
      print("Error updating project: $e");
      throw e;
    }
  }

  // 4. Delete Project
  Future<void> deleteProject(String id) async {
    try {
      await _api.delete('/projects/$id');
    } catch (e) {
      print("Error deleting project: $e");
      throw e;
    }
  }

  // ... inside ProjectService class ...

  // 5. Get Single Project Details (includes assignedUsers list)
  Future<Map<String, dynamic>> getProjectById(String id) async {
    try {
      final data = await _api.get('/projects/$id');
      return data as Map<String, dynamic>;
    } catch (e) {
      print("Error fetching project details: $e");
      throw e;
    }
  }

  // 6. Remove User from Project
  Future<void> removeUserFromProject(String projectId, String userId) async {
    try {
      // Adjust endpoint based on your actual backend API
      // Common pattern: DELETE /projects/{projectId}/users/{userId}
      await _api.delete('/projects/$projectId/users/$userId');
    } catch (e) {
      print("Error removing user: $e");
      throw e;
    }
  }
}