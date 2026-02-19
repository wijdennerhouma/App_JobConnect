import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiClient {
  ApiClient(this.baseUrl, {this.token});

  final String baseUrl;
  final String? token;

  Map<String, String> _headers({bool jsonBody = true}) {
    final headers = <String, String>{};
    if (jsonBody) {
      headers['Content-Type'] = 'application/json';
    }
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<http.Response> get(String path) {
    final uri = Uri.parse('$baseUrl$path');
    return http.get(uri, headers: _headers()).timeout(
      const Duration(seconds: 15),
      onTimeout: () => throw Exception('Requête expirée (Timeout)'),
    );
  }

  Future<http.Response> post(String path, Map<String, dynamic> body) {
    final uri = Uri.parse('$baseUrl$path');
    return http.post(uri, headers: _headers(), body: jsonEncode(body)).timeout(
      const Duration(seconds: 15),
      onTimeout: () => throw Exception('Requête expirée (Timeout)'),
    );
  }

  Future<http.Response> put(String path, Map<String, dynamic> body) {
    final uri = Uri.parse('$baseUrl$path');
    return http.put(uri, headers: _headers(), body: jsonEncode(body)).timeout(
      const Duration(seconds: 15),
      onTimeout: () => throw Exception('Requête expirée (Timeout)'),
    );
  }

  Future<http.Response> patch(String path, Map<String, dynamic> body) {
    final uri = Uri.parse('$baseUrl$path');
    return http.patch(uri, headers: _headers(), body: jsonEncode(body)).timeout(
      const Duration(seconds: 15),
      onTimeout: () => throw Exception('Requête expirée (Timeout)'),
    );
  }

  Future<http.Response> delete(String path) {
    final uri = Uri.parse('$baseUrl$path');
    return http.delete(uri, headers: _headers()).timeout(
      const Duration(seconds: 15),
      onTimeout: () => throw Exception('Requête expirée (Timeout)'),
    );
  }
}
