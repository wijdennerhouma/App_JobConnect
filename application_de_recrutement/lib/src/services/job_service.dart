import 'dart:convert';

import '../core/auth_state.dart';
import '../core/api_config.dart';
import '../models/job.dart';
import 'api_client.dart';

class JobService {
  JobService(this.auth);

  final AuthState auth;

  ApiClient get _client => ApiClient(ApiConfig.baseUrl, token: auth.token);

  Future<List<Job>> fetchAll() async {
    final res = await _client.get('/job');
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as List<dynamic>;
      return data.map((e) => Job.fromJson(e)).toList();
    }
    throw Exception('Impossible de récupérer les offres (${res.statusCode})');
  }

  Future<Job?> fetchById(String id) async {
    final res = await _client.get('/job/$id');
    if (res.statusCode == 200) {
      if (res.body.isEmpty) return null;
      final data = jsonDecode(res.body);
      return Job.fromJson(data);
    }
    return null;
  }

  Future<Job> create(Job payload) async {
    final body = {
      'title': payload.title,
      'description': payload.description,
      'startTime': payload.startTime,
      'endTime': payload.endTime,
      'duration': payload.duration,
      'contract': payload.contract,
      'startDate': payload.startDate,
      'endDate': payload.endDate,
      'work_hours': payload.workHours,
      'price': payload.price,
      'pricing_type': payload.pricingType,
      'address': payload.address,
      'applicants_ids': payload.applicantsIds,
    };

    final res = await _client.post('/job/create', body);
    if (res.statusCode == 201 || res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return Job.fromJson(data);
    }
    throw Exception('Création impossible (${res.statusCode})');
  }

  Future<void> delete(String id) async {
    final res = await _client.delete('/job/$id');
    if (res.statusCode != 200) {
      throw Exception('Suppression impossible (${res.statusCode})');
    }
  }
}

