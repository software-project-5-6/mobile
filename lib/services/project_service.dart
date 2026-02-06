import 'api_service.dart';

class ProjectService {
  final ApiService _api = ApiService();

  // Get All Projects
  Future<List<dynamic>> getAllProjects() async {
    try {
      final data = await _api.get('/projects');
      return data as List<dynamic>;
    } catch (e) {
      print("Error fetching projects: $e");
      return [];
    }
  }

  // Create Project
  Future<void> createProject(Map<String, dynamic> projectData) async {
    await _api.post('/projects', projectData);
  }
}