import 'dart:convert';

import '../core/auth_state.dart';
import '../core/api_config.dart';
import '../models/app_application.dart';
import 'api_client.dart';

class ApplicationService {
  ApplicationService(this.auth);

  final AuthState auth;

  ApiClient get _client => ApiClient(ApiConfig.baseUrl, token: auth.token);

  Future<ApplicationItem> apply({
    required String jobId,
    required String entrepriseId,
    String? coverLetter,
    List<String>? skills,
  }) async {
    final body = {
      'job_id': jobId,
      'user_id': auth.userId,
      'entreprise_id': entrepriseId,
      'status': 'pending',
      if (coverLetter != null) 'coverLetter': coverLetter,
      if (skills != null) 'skills': skills,
    };
    final res = await _client.post('/applications', body);
    if (res.statusCode == 201 || res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return ApplicationItem.fromJson(data);
    }
    throw Exception('Candidature impossible (${res.statusCode})');
  }

  Future<List<ApplicationItem>> byApplicant(String applicantId) async {
    final res = await _client.get('/applications/byApplicant/$applicantId');
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as List<dynamic>;
      return data.map((e) => ApplicationItem.fromJson(e)).toList();
    }
    throw Exception('Impossible de charger les candidatures');
  }

  Future<List<ApplicationItem>> byJob(String jobId) async {
    final res = await _client.get('/applications/job/$jobId');
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as List<dynamic>;
      return data.map((e) => ApplicationItem.fromJson(e)).toList();
    }
    throw Exception('Impossible de charger les candidats');
  }
  Future<void> updateStatus(String applicationId, String status) async {
    final res = await _client.patch(
      '/applications/$applicationId/status',
      {'status': status},
    );
    if (res.statusCode != 200) {
      throw Exception('Impossible de mettre à jour le statut (${res.statusCode})');
    }
  }

  Future<void> delete(String applicationId) async {
    final res = await _client.delete('/applications/$applicationId');
    if (res.statusCode != 200 && res.statusCode != 204) {
      throw Exception('Impossible de supprimer la candidature (${res.statusCode})');
    }
  }

  Future<ApplicationItem?> getById(String id) async {
    final res = await _client.get('/applications/$id');
    if (res.statusCode == 200) {
      if (res.body.isEmpty) return null;
      final data = jsonDecode(res.body);
      return ApplicationItem.fromJson(data);
    }
    return null;
  }
}

