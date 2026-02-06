import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart'; 
import 'package:mime/mime.dart'; 
import 'package:path_provider/path_provider.dart'; // Add this to pubspec.yaml for downloads
import 'package:open_file/open_file.dart'; // Add this to pubspec.yaml for opening files
import 'api_service.dart';

class ArtifactService {
  final ApiService _api = ApiService();

  // 1. Get All Artifacts
  Future<List<dynamic>> getArtifacts(String projectId) async {
    try {
      final data = await _api.get('/projects/$projectId/artifacts');
      return data as List<dynamic>;
    } catch (e) {
      print("Error fetching artifacts: $e");
      return [];
    }
  }

  // 2. Upload Artifact
  Future<void> uploadArtifact(String projectId, File file, String tags) async {
    try {
      final token = await _api.getIdToken();
      // NOTE: Using the /upload endpoint as required by your backend
      final uri = Uri.parse('${ApiService.baseUrl}/projects/$projectId/artifacts/upload');
      
      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';
      
      final mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';
      String fileType = 'DOCUMENT';
      if (mimeType.startsWith('image/')) fileType = 'IMAGE';
      else if (mimeType.startsWith('audio/')) fileType = 'AUDIO';
      else if (mimeType.startsWith('video/')) fileType = 'VIDEO';

      request.fields['type'] = fileType;
      request.fields['tags'] = tags;
      request.fields['uploadedBy'] = "Mobile User"; 

      request.files.add(await http.MultipartFile.fromPath(
        'file',
        file.path,
        contentType: MediaType.parse(mimeType),
      ));

      final response = await http.Response.fromStream(await request.send());

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception("Upload failed: ${response.body}");
      }
    } catch (e) {
      print("Error uploading: $e");
      throw e;
    }
  }

  // 3. Download Artifact
  Future<void> downloadArtifact(String projectId, String artifactId, String filename) async {
    try {
      final token = await _api.getIdToken();
      final uri = Uri.parse('${ApiService.baseUrl}/projects/$projectId/artifacts/$artifactId/download');
      
      final response = await http.get(uri, headers: {'Authorization': 'Bearer $token'});

      if (response.statusCode == 200) {
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/$filename');
        await file.writeAsBytes(response.bodyBytes);
        print("File saved to ${file.path}");
        // Optional: Open the file
        await OpenFile.open(file.path);
      } else {
        throw Exception("Download failed: ${response.statusCode}");
      }
    } catch (e) {
      print("Error downloading: $e");
      throw e;
    }
  }

  // 4. Delete Artifact
  Future<void> deleteArtifact(String projectId, String artifactId) async {
    await _api.delete('/projects/$projectId/artifacts/$artifactId');
  }
}