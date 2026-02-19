import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

import '../core/api_config.dart';

class AuthResult {
  final String token;
  final String userId;
  final String type;
  final bool isTwoFactorEnabled;

  AuthResult({
    required this.token,
    required this.userId,
    required this.type,
    this.isTwoFactorEnabled = false,
  });

  factory AuthResult.fromJson(Map<String, dynamic> json) => AuthResult(
        token: json['token'] as String,
        userId: json['userId'] as String,
        type: json['type'] as String,
        isTwoFactorEnabled: json['isTwoFactorEnabled'] ?? false,
      );
}

class AuthService {
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/auth/login');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw Exception('Connection timeout. Please check if the server is running.'),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return AuthResult.fromJson(data);
    }

    debugPrint('Unexpected status code: ${response.statusCode}, body: ${response.body}');
    throw Exception('Login failed (${response.statusCode})');
  }

  Future<AuthResult> signup({
    required String name,
    String? firstName,
    required String email,
    required String password,
    required String city,
    required String type, // 'employee' | 'entreprise'
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/auth/signup');
    final body = {
      'user': {
        'name': name,
        if (firstName != null && firstName.isNotEmpty) 'firstName': firstName,
        'email': email,
        'password': password,
        'city': city,
        'type': type,
      },
      // For now send an empty resume; backend will ignore for entreprise
      'resume': {
        'userId': null,
        'title': '',
        'summary': '',
        'skills': [],
        'education': [],
        'workExperience': [],
        'languages': [],
        'certifications': [],
      },
    };

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw Exception('Connection timeout. Please check if the server is running.'),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return AuthResult.fromJson(data);
    }

    throw Exception("Signup failed (${response.statusCode})");
  }

  Future<void> forgotPassword(String email) async {
    // TODO: Connect to actual backend endpoint
    // final uri = Uri.parse('${ApiConfig.baseUrl}/auth/forgot-password');
    // final response = await http.post...
    
    // Simulating API call
    await Future.delayed(const Duration(seconds: 1));
    
    // If backend existed:
    /*
    if (response.statusCode != 200) {
      throw Exception('Erreur lors de la demande de réinitialisation');
    }
    */
  }

  Future<void> changePassword(String userId, String currentPass, String newPass, String token) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/auth/user/$userId/change-password');
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'currentPass': currentPass,
        'newPass': newPass,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to change password: ${response.body}');
    }
  }

  Future<void> toggleTwoFactor(String userId, bool enable, String token) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/auth/user/$userId/toggle-2fa');
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'enable': enable}),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to toggle 2FA: ${response.body}');
    }
  }
}

