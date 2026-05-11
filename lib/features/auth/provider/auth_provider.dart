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

  bool _isValidEmail(String email) {
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email.trim());
  }

  bool _isValidName(String name) {
    final cleanName = name.trim();
    return cleanName.length >= 2 && cleanName.length <= 120;
  }

  bool _isValidPassword(String password) {
    final cleanPassword = password.trim();
    return cleanPassword.length >= 6 && cleanPassword.length <= 60;
  }

  bool _isValidPhone(String phone) {
    if (phone.trim().isEmpty) return true;
    return RegExp(r'^[0-9+\-\s()]{7,40}$').hasMatch(phone.trim());
  }

  Future<void> loadUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final savedToken = prefs.getString('auth_token');
      final savedUser = prefs.getString('auth_user');

      if (savedToken != null && savedUser != null) {
        token = savedToken;
        user = Map<String, dynamic>.from(jsonDecode(savedUser));

        final userId =
            user?['uid']?.toString() ?? user?['id']?.toString() ?? '';

        profileImagePath = prefs.getString('profile_${userId}_image_path');

        user = {
          ...(user ?? {}),
          'id': int.tryParse(userId) ?? userId,
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

  Future<bool> register(String name, String email, String password) async {
    try {
      final cleanName = name.trim();
      final cleanEmail = email.trim().toLowerCase();
      final cleanPassword = password.trim();

      if (!_isValidName(cleanName)) return false;
      if (!_isValidEmail(cleanEmail)) return false;
      if (!_isValidPassword(cleanPassword)) return false;

      isLoading = true;
      notifyListeners();

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': cleanName,
          'email': cleanEmail,
          'password': cleanPassword,
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

  Future<bool> login(String email, String password) async {
    try {
      final cleanEmail = email.trim().toLowerCase();
      final cleanPassword = password.trim();

      if (!_isValidEmail(cleanEmail)) return false;
      if (!_isValidPassword(cleanPassword)) return false;

      isLoading = true;
      notifyListeners();

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': cleanEmail, 'password': cleanPassword}),
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
          'id': apiUser['id'],
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

  Future<bool> updateUser(Map<String, dynamic> updated) async {
    final prefs = await SharedPreferences.getInstance();

    final currentUser = user ?? {};

    final userId =
        currentUser['id']?.toString() ??
        currentUser['uid']?.toString() ??
        updated['uid']?.toString() ??
        '';

    if (userId.isEmpty) return false;

    final newName =
        updated['name']?.toString().trim() ??
        currentUser['name']?.toString().trim() ??
        '';

    final newPhone =
        updated['phone']?.toString().trim() ??
        currentUser['phone']?.toString().trim() ??
        '';

    if (!_isValidName(newName)) return false;
    if (!_isValidPhone(newPhone)) return false;

    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/auth/profile/$userId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': newName, 'phone': newPhone}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode != 200 || data['ok'] != true) {
        debugPrint('UPDATE PROFILE ERROR: ${data['message']}');
        return false;
      }
    } catch (e) {
      debugPrint('UPDATE PROFILE API ERROR: $e');
      return false;
    }

    final imagePath = updated['profileImagePath']?.toString() ?? '';

    if (imagePath.isNotEmpty) {
      profileImagePath = imagePath;
      await prefs.setString('profile_${userId}_image_path', imagePath);
    }

    final documentNumber =
        updated['documentNumber']?.toString() ??
        updated['documentId']?.toString() ??
        currentUser['documentNumber']?.toString() ??
        '';

    user = {
      ...currentUser,
      ...updated,
      'id': int.tryParse(userId) ?? userId,
      'uid': userId,
      'name': newName,
      'phone': newPhone,
      'documentNumber': documentNumber,
      'profileImagePath': profileImagePath ?? '',
    };

    await prefs.setString('auth_user', jsonEncode(user));

    notifyListeners();
    return true;
  }

  Future<void> logout() async {
    try {
      await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/logout'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': user?['id']}),
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
