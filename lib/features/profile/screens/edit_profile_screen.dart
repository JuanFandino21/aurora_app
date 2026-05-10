import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../accessibility/provider/accessibility_provider.dart';
import '../../auth/provider/auth_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _picker = ImagePicker();

  final TextEditingController nicknameController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController idController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  File? profileImage;
  bool _loaded = false;

  String _key(String uid, String suffix) => 'profile_${uid}_$suffix';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      _loaded = true;
      _loadData();
    }
  }

  @override
  void dispose() {
    nicknameController.dispose();
    nameController.dispose();
    lastNameController.dispose();
    idController.dispose();
    emailController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final auth = context.read<AuthProvider>();
    final currentUser = auth.user ?? {};

    final uid = currentUser['uid']?.toString() ?? '';
    if (uid.isEmpty) return;

    nicknameController.text =
        prefs.getString(_key(uid, 'nickname')) ??
        currentUser['name']?.toString() ??
        '';
    nameController.text =
        prefs.getString(_key(uid, 'name')) ??
        currentUser['firstName']?.toString() ??
        '';
    lastNameController.text =
        prefs.getString(_key(uid, 'last_name')) ??
        currentUser['lastName']?.toString() ??
        '';
    idController.text = prefs.getString(_key(uid, 'id')) ?? '';
    emailController.text = currentUser['email']?.toString() ?? '';
    phoneController.text =
        prefs.getString(_key(uid, 'phone')) ??
        currentUser['phone']?.toString() ??
        '';

    final imagePath = prefs.getString(_key(uid, 'image_path'));
    if (imagePath != null && imagePath.isNotEmpty) {
      profileImage = File(imagePath);
    }

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    setState(() {
      profileImage = File(picked.path);
    });

    context.read<AccessibilityProvider>().speak(
      'Imagen de perfil seleccionada',
    );
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final auth = context.read<AuthProvider>();
    final accessibility = context.read<AccessibilityProvider>();

    final currentUser = auth.user ?? {};
    final uid = currentUser['uid']?.toString() ?? '';
    if (uid.isEmpty) return;

    await prefs.setString(
      _key(uid, 'nickname'),
      nicknameController.text.trim(),
    );
    await prefs.setString(_key(uid, 'name'), nameController.text.trim());
    await prefs.setString(
      _key(uid, 'last_name'),
      lastNameController.text.trim(),
    );
    await prefs.setString(_key(uid, 'id'), idController.text.trim());
    await prefs.setString(_key(uid, 'phone'), phoneController.text.trim());

    if (profileImage != null) {
      await prefs.setString(_key(uid, 'image_path'), profileImage!.path);
    }

    final fullName =
        '${nameController.text.trim()} ${lastNameController.text.trim()}'
            .trim();

    await auth.updateUser({
      'uid': uid,
      'name': nicknameController.text.trim().isNotEmpty
          ? nicknameController.text.trim()
          : fullName,
      'firstName': nameController.text.trim(),
      'lastName': lastNameController.text.trim(),
      'id': idController.text.trim(),
      'email': emailController.text.trim(),
      'phone': phoneController.text.trim(),
      'profileImagePath': profileImage?.path ?? '',
    });

    if (!mounted) return;

    accessibility.speak('Perfil guardado');

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Perfil guardado')));
  }

  @override
  Widget build(BuildContext context) {
    final accessibility = context.watch<AccessibilityProvider>();

    return Scaffold(
      backgroundColor: accessibility.appBackground,
      appBar: AppBar(
        backgroundColor: accessibility.appBarColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Image.asset('assets/logo.png', height: 40),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
        child: Column(
          children: [
            const SizedBox(height: 8),
            CircleAvatar(
              radius: 48,
              backgroundColor: accessibility.surfaceColor,
              backgroundImage: profileImage != null
                  ? FileImage(profileImage!)
                  : null,
              child: profileImage == null
                  ? Icon(
                      Icons.person,
                      size: 42,
                      color: accessibility.primaryColor,
                    )
                  : null,
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: 150,
              height: 38,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: accessibility.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                onPressed: _pickImage,
                child: const Text('Editar imagen'),
              ),
            ),
            const SizedBox(height: 20),
            _field(
              accessibility,
              '¿Cómo te llaman tus amigos?',
              nicknameController,
            ),
            _field(accessibility, 'Nombre*', nameController),
            _field(accessibility, 'Apellido*', lastNameController),
            _field(accessibility, 'Número de identificación', idController),
            _field(
              accessibility,
              'Correo electrónico*',
              emailController,
              readOnly: true,
            ),
            _field(accessibility, 'Teléfono móvil*', phoneController),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: accessibility.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                onPressed: _save,
                child: const Text(
                  'Guardar',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    AccessibilityProvider accessibility,
    String hint,
    TextEditingController controller, {
    bool readOnly = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        style: TextStyle(color: accessibility.textColor),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: accessibility.mutedTextColor),
          filled: true,
          fillColor: accessibility.surfaceColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: accessibility.highContrast
                  ? Colors.white24
                  : Colors.transparent,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: accessibility.highContrast
                  ? Colors.white24
                  : Colors.transparent,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: accessibility.primaryColor),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}
