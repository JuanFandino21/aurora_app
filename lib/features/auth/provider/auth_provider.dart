import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  static const String baseUrl = 'http://10.0.2.2:3000';

  Map<String, dynamic>? user;
  String? token;
  String? profileImagePath;

  bool isLoading = false;
  bool isInitialized = false;

  bool get isLoggedIn => user != null && token != null;

  Future<void> loadUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final savedToken = prefs.getString('auth_token');
      final savedUser = prefs.getString('auth_user');

      if (savedToken != null && savedUser != null) {
        token = savedToken;
        user = Map<String, dynamic>.from(jsonDecode(savedUser));

        final userId = user?['uid']?.toString() ?? user?['id']?.toString() ?? '';
        profileImagePath = prefs.getString('profile_${userId}_image_path');

        user = {
          ...(user ?? {}),
          'uid': userId,
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
    String password,
  ) async {
    try {
      isLoading = true;
      notifyListeners();

      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': name.trim(),
          'email': email.trim(),
          'password': password.trim(),
          'phone': '',
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

  Future<bool> login(
    String email,
    String password,
  ) async {
    try {
      isLoading = true;
      notifyListeners();

      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email.trim(),
          'password': password.trim(),
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['ok'] == true) {
        token = data['token'].toString();

        final apiUser = Map<String, dynamic>.from(data['user']);
        final userId = apiUser['id'].toString();

        final prefs = await SharedPreferences.getInstance();
        profileImagePath = prefs.getString('profile_${userId}_image_path');

        user = {
          ...apiUser,
          'uid': userId,
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

  Future<bool> signInWithGoogle() async {
    debugPrint('GOOGLE LOGIN: desactivado temporalmente usando MySQL');
    return false;
  }

  Future<bool> sendPasswordReset(String email) async {
    debugPrint('RESET PASSWORD: pendiente backend MySQL');
    return false;
  }

  Future<void> updateUser(Map<String, dynamic> updated) async {
    final prefs = await SharedPreferences.getInstance();

    final currentUser = user ?? {};
    final userId =
        updated['uid']?.toString() ??
        currentUser['uid']?.toString() ??
        currentUser['id']?.toString() ??
        '';

    final imagePath = updated['profileImagePath']?.toString() ?? '';

    if (imagePath.isNotEmpty && userId.isNotEmpty) {
      profileImagePath = imagePath;
      await prefs.setString('profile_${userId}_image_path', imagePath);
    }

    user = {
      ...currentUser,
      ...updated,
      'uid': userId,
      'profileImagePath': profileImagePath ?? '',
    };

    await prefs.setString('auth_user', jsonEncode(user));

    notifyListeners();
  }

  Future<void> logout() async {
    try {
      await http.post(
        Uri.parse('$baseUrl/auth/logout'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'userId': user?['id'],
        }),
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