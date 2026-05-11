import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../../auth/provider/auth_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final identificationController = TextEditingController();
  final phoneController = TextEditingController();

  String? imagePath;
  bool saving = false;

  @override
  void initState() {
    super.initState();

    final auth = context.read<AuthProvider>();

    nameController.text = auth.user?['name']?.toString() ?? '';
    emailController.text = auth.user?['email']?.toString() ?? '';
    identificationController.text =
        auth.user?['identification']?.toString() ?? '';
    phoneController.text = auth.user?['phone']?.toString() ?? '';

    imagePath =
        auth.profileImagePath ?? auth.user?['profileImagePath']?.toString();
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    identificationController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();

    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
    );

    if (picked == null) return;

    final appDir = await getApplicationDocumentsDirectory();
    final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final savedFile = await File(picked.path).copy('${appDir.path}/$fileName');

    setState(() {
      imagePath = savedFile.path;
    });
  }

  bool _validName(String name) {
    final clean = name.trim();

    return clean.length >= 2 && clean.length <= 120;
  }

  bool _validIdentification(String value) {
    final clean = value.trim();

    return RegExp(r'^[0-9A-Za-z.-]{5,30}$').hasMatch(clean);
  }

  bool _validPhone(String phone) {
    final clean = phone.trim();

    if (clean.isEmpty) return true;

    return RegExp(r'^[0-9+\-\s()]{7,40}$').hasMatch(clean);
  }

  Future<void> _save() async {
    final name = nameController.text.trim();
    final identification = identificationController.text.trim();
    final phone = phoneController.text.trim();

    if (!_validName(name)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El nombre debe tener entre 2 y 120 caracteres'),
        ),
      );
      return;
    }

    if (!_validIdentification(identification)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La identificación debe tener entre 5 y 30 caracteres'),
        ),
      );
      return;
    }

    if (!_validPhone(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa un teléfono válido')),
      );
      return;
    }

    setState(() {
      saving = true;
    });

    final ok = await context.read<AuthProvider>().updateProfile(
      name: name,
      identification: identification,
      phone: phone,
      imagePath: imagePath,
    );

    if (!mounted) return;

    setState(() {
      saving = false;
    });

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil actualizado correctamente')),
      );

      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No fue posible actualizar el perfil. Revisa que el backend ya esté desplegado.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    final imageExists =
        imagePath != null &&
        imagePath!.isNotEmpty &&
        File(imagePath!).existsSync();

    return Scaffold(
      backgroundColor: const Color(0xFFF6E7F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF48FB1),
        foregroundColor: Colors.white,
        title: const Text('Editar perfil'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 58,
                backgroundColor: const Color(0xFFE9B8DF),
                backgroundImage: imageExists
                    ? FileImage(File(imagePath!))
                    : null,
                child: imageExists
                    ? null
                    : const Icon(
                        Icons.camera_alt,
                        size: 42,
                        color: Colors.white,
                      ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Center(
            child: Text(
              'Toca la imagen para cambiarla',
              style: TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 28),
          _field(
            controller: nameController,
            label: 'Nombre y apellido',
            hint: 'Ej: Laura Gómez',
            icon: Icons.person,
          ),
          const SizedBox(height: 16),
          _field(
            controller: emailController,
            label: 'Correo electrónico',
            hint: 'Correo',
            icon: Icons.email,
            enabled: false,
          ),
          const SizedBox(height: 16),
          _field(
            controller: identificationController,
            label: 'Identificación',
            hint: 'Ej: 1000123456',
            icon: Icons.badge,
            keyboardType: TextInputType.text,
          ),
          const SizedBox(height: 16),
          _field(
            controller: phoneController,
            label: 'Teléfono',
            hint: 'Ej: 3001234567',
            icon: Icons.phone,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 8),
          const Text(
            'El correo no se puede editar. La identificación y el teléfono deben ser únicos.',
            style: TextStyle(color: Colors.black54, fontSize: 13, height: 1.3),
          ),
          const SizedBox(height: 28),
          SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: saving || auth.isLoading ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE91E63),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: saving || auth.isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Guardar cambios',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool enabled = true,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: enabled ? Colors.white : Colors.grey.shade200,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
