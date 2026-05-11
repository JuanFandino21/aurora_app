import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../constants/api_config.dart';

class ApiService {
  static String get baseUrl => ApiConfig.baseUrl;

  static Map<String, String> get headers => {
        'Content-Type': 'application/json',
      };

  static Future<Map<String, dynamic>?> login(
    String email,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: headers,
        body: jsonEncode({
          'email': email.trim(),
          'password': password.trim(),
        }),
      );

      debugPrint(response.body);

      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(jsonDecode(response.body));
      }

      return null;
    } catch (e) {
      debugPrint('LOGIN API ERROR: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> register(
    String name,
    String email,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: headers,
        body: jsonEncode({
          'name': name.trim(),
          'email': email.trim(),
          'password': password.trim(),
          'phone': '',
        }),
      );

      debugPrint(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return Map<String, dynamic>.from(jsonDecode(response.body));
      }

      return null;
    } catch (e) {
      debugPrint('REGISTER API ERROR: $e');
      return null;
    }
  }

  static Future<List<dynamic>> getProducts() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/products'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is Map<String, dynamic> && data['ok'] == true) {
          return List<dynamic>.from(data['products'] ?? []);
        }
      }

      return [];
    } catch (e) {
      debugPrint('PRODUCTS API ERROR: $e');
      return [];
    }
  }
}