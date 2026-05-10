import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:4000';

  static Map<String, String> get headers => {
        'Content-Type': 'application/json',
      };

  // LOGIN
  static Future<Map<String, dynamic>?> login(
    String email,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/login'),
        headers: headers,
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      print(response.body);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      return null;
    } catch (e) {
      print(e);
      return null;
    }
  }

  // REGISTER
  static Future<Map<String, dynamic>?> register(
    String name,
    String email,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/register'),
        headers: headers,
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
        }),
      );

      print(response.body);

      if (response.statusCode == 200 ||
          response.statusCode == 201) {
        return jsonDecode(response.body);
      }

      return null;
    } catch (e) {
      print(e);
      return null;
    }
  }

  // PRODUCTS
  static Future<List<dynamic>> getProducts() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/products'),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      return [];
    } catch (e) {
      print(e);
      return [];
    }
  }
}