import 'dart:convert';

import '../core/auth_state.dart';
import '../core/api_config.dart';
import 'api_client.dart';
import 'package:http/http.dart' as http;

class ResumeService {
  ResumeService(this.auth);

  final AuthState auth;

  ApiClient get _client => ApiClient(ApiConfig.baseUrl, token: auth.token);

  Future<Map<String, dynamic>?> getByUser(String userId) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/resumes/user/$userId');
    final response = await http.get(uri, headers: {
      'Authorization': 'Bearer ${auth.token}',
    });

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    if (response.statusCode == 404) {
      return null; // No resume found for the user
    }

    throw Exception('Failed to fetch resume: ${response.statusCode}');
  }

  Future<Map<String, dynamic>?> update(String resumeId, Map<String, dynamic> data) async {
    // Vérifier la taille du fichier (max 10MB)
    if (data['file'] != null) {
      String file = data['file'];
      int sizeInBytes = file.length;
      int sizeInMB = sizeInBytes ~/ (1024 * 1024);
      
      if (sizeInMB > 10) {
        throw Exception('Le fichier CV ne doit pas dépasser 10 MB (taille actuelle: ${sizeInMB}MB)');
      }
    }
    
    final res = await _client.put('/resumes/$resumeId', data);
    if (res.statusCode == 200 || res.statusCode == 201) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception('Échec de mise à jour du CV: ${res.statusCode} - ${res.body}');
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> data) async {
    // Vérifier la taille du fichier (max 10MB)
    if (data['file'] != null) {
      String file = data['file'];
      int sizeInBytes = file.length;
      int sizeInMB = sizeInBytes ~/ (1024 * 1024);
      
      if (sizeInMB > 10) {
        throw Exception('Le fichier CV ne doit pas dépasser 10 MB (taille actuelle: ${sizeInMB}MB)');
      }
    }
    
    final res = await _client.post('/resumes', data);
    if (res.statusCode == 200 || res.statusCode == 201) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception('Échec de création du CV: ${res.statusCode} - ${res.body}');
  }
}

