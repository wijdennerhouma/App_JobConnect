import 'package:application_de_recrutement/src/core/auth_state.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../core/api_config.dart';
import 'package:file_picker/file_picker.dart';

class UserService {
  final AuthState auth;

  UserService(this.auth);

  // Add your methods here
  Future<Map<String, dynamic>> getProfile(String userId) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/auth/user/$userId');
    final response = await http.get(uri, headers: {
      'Authorization': 'Bearer ${auth.token}',
    });

    if (response.statusCode == 200) {
      if (response.body.isEmpty) {
        throw Exception('User not found (empty response)');
      }
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    throw Exception('Failed to fetch profile: ${response.statusCode}');
  }

  Future<Map<String, dynamic>> updateProfile(String userId, Map<String, dynamic> userUpdateData) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/auth/user/$userId');
    final response = await http.patch(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${auth.token}',
      },
      body: jsonEncode(userUpdateData),
    );

    // Accepter 200 (OK) et 201 (Created) comme succès
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    throw Exception('Failed to update profile: ${response.statusCode} - ${response.body}');
  }

  Future<Map<String, dynamic>> updateAvatar(String userId, PlatformFile file) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/auth/user/$userId/avatar');
    final request = http.MultipartRequest('POST', uri);

    request.headers['Authorization'] = 'Bearer ${auth.token}';
    
    // Sur le web, utiliser bytes. Sur mobile/desktop, utiliser path si disponible
    if (file.bytes != null) {
      // Web ou fichier déjà chargé en mémoire
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          file.bytes!,
          filename: file.name.isNotEmpty ? file.name : 'avatar.jpg',
        ),
      );
    } else if (file.path != null) {
      // Mobile/Desktop avec chemin de fichier
      request.files.add(
        await http.MultipartFile.fromPath('file', file.path!),
      );
    } else {
      throw Exception('File has no path or bytes');
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    // Accepter 200 (OK) et 201 (Created) comme succès
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    throw Exception('Failed to update avatar: ${response.statusCode} - ${response.body}');
  }
  Future<List<dynamic>> getSavedJobs(String userId) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/auth/user/$userId/saved-jobs');
    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer ${auth.token}'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    }
    throw Exception('Failed to fetch saved jobs: ${response.statusCode}');
  }

  Future<Map<String, dynamic>> toggleSavedJob(String userId, String jobId) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/auth/user/$userId/saved-jobs/$jobId');
    final response = await http.post(
      uri,
      headers: {'Authorization': 'Bearer ${auth.token}'},
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to toggle saved job: ${response.statusCode}');
  }

  Future<void> deleteAccount(String userId) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/auth/user/$userId');
    final response = await http.delete(
      uri,
      headers: {'Authorization': 'Bearer ${auth.token}'},
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete account: ${response.statusCode}');
    }
  }

  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    if (query.isEmpty) return [];
    
    final uri = Uri.parse('${ApiConfig.baseUrl}/auth/search').replace(queryParameters: {'q': query});
    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer ${auth.token}'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('Failed to search users: ${response.statusCode}');
  }
}