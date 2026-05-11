import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/api_config.dart';

class AuthProvider extends ChangeNotifier {
  Map<String, dynamic>? user;
  String? token;
  String? profileImagePath;

  bool isLoading = false;
  bool isInitialized = false;

  bool get isLoggedIn => user != null && token != null;

  int? get userId {
    final raw = user?['id'] ?? user?['uid'] ?? user?['userId'];

    if (raw == null) return null;

    return int.tryParse(raw.toString());
  }

  Future<void> loadUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final savedToken = prefs.getString('auth_token');
      final savedUser = prefs.getString('auth_user');

      if (savedToken != null && savedUser != null) {
        token = savedToken;
        user = Map<String, dynamic>.from(jsonDecode(savedUser));

        final id = userId?.toString() ?? '';

        profileImagePath = prefs.getString('profile_${id}_image_path');

        user = {
          ...(user ?? {}),
          'uid': id,
          'profileImagePath': profileImagePath ?? '',
        };
      } else {
        token = null;
        user = null;
        profileImagePath = null;
      }
    } catch (e) {
      debugPrint('LOAD USER ERROR: $e');

      token = null;
      user = null;
      profileImagePath = null;
    } finally {
      isInitialized = true;
      notifyListeners();
    }
  }

  Future<bool> register(
    String name,
    String email,
    String password, {
    String identification = '',
    String phone = '',
  }) async {
    try {
      isLoading = true;
      notifyListeners();

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name.trim(),
          'email': email.trim(),
          'password': password.trim(),
          'identification': identification.trim(),
          'phone': phone.trim(),
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['ok'] == true) {
        return true;
      }

      debugPrint('REGISTER ERROR: ${data['message']}');
      return false;
    } catch (e) {
      debugPrint('REGISTER ERROR: $e');
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      isLoading = true;
      notifyListeners();

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email.trim(), 'password': password.trim()}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['ok'] == true) {
        token = data['token'].toString();

        final apiUser = Map<String, dynamic>.from(data['user']);
        final id = apiUser['id'].toString();

        final prefs = await SharedPreferences.getInstance();

        profileImagePath = prefs.getString('profile_${id}_image_path');

        user = {
          ...apiUser,
          'uid': id,
          'profileImagePath': profileImagePath ?? '',
        };

        await prefs.setString('auth_token', token!);
        await prefs.setString('auth_user', jsonEncode(user));

        notifyListeners();
        return true;
      }

      debugPrint('LOGIN ERROR: ${data['message']}');
      return false;
    } catch (e) {
      debugPrint('LOGIN ERROR: $e');
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateProfile({
    required String name,
    required String identification,
    required String phone,
    String? imagePath,
  }) async {
    final id = userId;

    if (id == null || id <= 0) {
      debugPrint('UPDATE PROFILE ERROR: usuario sin id');
      return false;
    }

    try {
      isLoading = true;
      notifyListeners();

      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/auth/profile/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name.trim(),
          'identification': identification.trim(),
          'phone': phone.trim(),
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode != 200 || data['ok'] != true) {
        debugPrint('UPDATE PROFILE ERROR: ${data['message']}');
        return false;
      }

      final apiUser = Map<String, dynamic>.from(data['user']);

      final prefs = await SharedPreferences.getInstance();

      if (imagePath != null && imagePath.trim().isNotEmpty) {
        profileImagePath = imagePath.trim();
        await prefs.setString('profile_${id}_image_path', profileImagePath!);
      }

      user = {
        ...(user ?? {}),
        ...apiUser,
        'uid': id.toString(),
        'profileImagePath': profileImagePath ?? '',
      };

      await prefs.setString('auth_user', jsonEncode(user));

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('UPDATE PROFILE ERROR: $e');
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateUser(Map<String, dynamic> updated) async {
    final prefs = await SharedPreferences.getInstance();

    final id =
        updated['uid']?.toString() ??
        updated['id']?.toString() ??
        userId?.toString() ??
        '';

    final imagePath = updated['profileImagePath']?.toString() ?? '';

    if (imagePath.isNotEmpty && id.isNotEmpty) {
      profileImagePath = imagePath;
      await prefs.setString('profile_${id}_image_path', imagePath);
    }

    user = {
      ...(user ?? {}),
      ...updated,
      'uid': id,
      'profileImagePath': profileImagePath ?? '',
    };

    await prefs.setString('auth_user', jsonEncode(user));

    notifyListeners();
  }

  Future<bool> signInWithGoogle() async {
    debugPrint('GOOGLE LOGIN: desactivado temporalmente usando MySQL');
    return false;
  }

  Future<bool> sendPasswordReset(String email) async {
    debugPrint('RESET PASSWORD: pendiente backend MySQL');
    return false;
  }

  Future<void> logout() async {
    try {
      await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/logout'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': userId}),
      );
    } catch (e) {
      debugPrint('LOGOUT API ERROR: $e');
    }

    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('auth_token');
    await prefs.remove('auth_user');

    token = null;
    user = null;
    profileImagePath = null;

    notifyListeners();
  }
}
