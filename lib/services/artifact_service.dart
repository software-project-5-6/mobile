
import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'api_service.dart';

class ArtifactService {
  final ApiService _api = ApiService();

  static const Duration _transferTimeout =
      Duration(minutes: 5);

  String _encodeId(String id) {
    if (id.trim().isEmpty) {
      throw ArgumentError('ID cannot be empty.');
    }
    return Uri.encodeComponent(id.trim());
  }

  // ==========================================
  // 1. GET ALL ARTIFACTS
  // ==========================================

  Future<List<dynamic>> getArtifacts(
    String projectId,
  ) async {
    try {
      final id = _encodeId(projectId);

      final response = await _api.get(
        '/projects/$id/artifacts',
      );

      if (response is List) {
        return List<dynamic>.from(response);
      }

      throw const FormatException(
        'Expected a list of artifacts.',
      );
    } catch (e) {
      debugPrint('Failed to fetch artifacts: $e');
      rethrow;
    }
  }

  // ==========================================
  // 2. UPLOAD ARTIFACT
  // ==========================================

  Future<void> uploadArtifact(
    String projectId,
    File file,
    String tags,
  ) async {
    if (!await file.exists()) {
      throw FileSystemException(
        'Upload file not found.',
        file.path,
      );
    }

    final id = _encodeId(projectId);
    final token = await _api.getIdToken();

    final uri = Uri.parse(
      '${ApiService.baseUrl}/projects/'
      '$id/artifacts/upload',
    );

    final mimeType =
        lookupMimeType(file.path) ??
        'application/octet-stream';

    String fileType = 'DOCUMENT';

    if (mimeType.startsWith('image/')) {
      fileType = 'IMAGE';
    } else if (mimeType.startsWith('audio/')) {
      fileType = 'AUDIO';
    } else if (mimeType.startsWith('video/')) {
      fileType = 'VIDEO';
    }

    final user =
        Supabase.instance.client.auth.currentUser;

    final displayName =
        user?.userMetadata?['name']?.toString() ??
        user?.email ??
        'Mobile User';

    final request = http.MultipartRequest(
      'POST',
      uri,
    );

    request.headers['Authorization'] =
        'Bearer $token';

    // Preserve existing backend field names.
    request.fields['type'] = fileType;
    request.fields['tags'] = tags;
    request.fields['uploadedBy'] = displayName;

    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        file.path,
        contentType: MediaType.parse(mimeType),
      ),
    );

    final client = http.Client();

    try {
      final streamedResponse = await client
          .send(request)
          .timeout(_transferTimeout);

      final response =
          await http.Response.fromStream(
        streamedResponse,
      ).timeout(_transferTimeout);

      if (response.statusCode < 200 ||
          response.statusCode >= 300) {
        throw Exception(
          'Artifact upload failed '
          '(${response.statusCode}).',
        );
      }

      debugPrint('Artifact uploaded successfully.');
    } on TimeoutException {
      throw Exception(
        'Artifact upload timed out.',
      );
    } catch (e) {
      debugPrint('Artifact upload failed: $e');
      rethrow;
    } finally {
      client.close();
    }
  }

  // ==========================================
  // 3. DOWNLOAD ARTIFACT
  // ==========================================

  Future<void> downloadArtifact(
    String projectId,
    String artifactId,
    String filename,
  ) async {
    final project = _encodeId(projectId);
    final artifact = _encodeId(artifactId);

    final token = await _api.getIdToken();

    final uri = Uri.parse(
      '${ApiService.baseUrl}/projects/'
      '$project/artifacts/$artifact/download',
    );

    try {
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
        },
      ).timeout(_transferTimeout);

      if (response.statusCode != 200) {
        throw Exception(
          'Download failed '
          '(${response.statusCode}).',
        );
      }

      final directory =
          await getApplicationDocumentsDirectory();

      // Prevent path traversal through server filenames.
      final lastComponent =
          filename.split(RegExp(r'[/\\]')).last;

      final safeName = lastComponent.replaceAll(
        RegExp(r'[^a-zA-Z0-9._() -]'),
        '_',
      );

      final finalName = safeName.isEmpty ||
              safeName == '.' ||
              safeName == '..'
          ? 'artifact_$artifactId'
          : safeName;

      final file = File(
        '${directory.path}'
        '${Platform.pathSeparator}$finalName',
      );

      await file.writeAsBytes(
        response.bodyBytes,
        flush: true,
      );

      debugPrint(
        'Artifact downloaded successfully.',
      );

      // Opens with an installed compatible app,
      // if one is available.
      await OpenFile.open(file.path);
    } on TimeoutException {
      throw Exception(
        'Artifact download timed out.',
      );
    } catch (e) {
      debugPrint('Artifact download failed: $e');
      rethrow;
    }
  }

  // ==========================================
  // 4. DELETE ARTIFACT
  // ==========================================

  Future<void> deleteArtifact(
    String projectId,
    String artifactId,
  ) async {
    try {
      final project = _encodeId(projectId);
      final artifact = _encodeId(artifactId);

      await _api.delete(
        '/projects/$project/artifacts/$artifact',
      );

      debugPrint('Artifact deleted successfully.');
    } catch (e) {
      debugPrint('Failed to delete artifact: $e');
      rethrow;
    }
  }
}
