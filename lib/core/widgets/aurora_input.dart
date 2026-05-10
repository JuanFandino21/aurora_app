import 'package:flutter/material.dart';

class AuroraInput extends StatelessWidget {
  final String hint;
  final bool isPassword;
  final TextEditingController? controller;

  const AuroraInput({
    super.key,
    required this.hint,
    this.isPassword = false,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller, // 👈 AQUÍ ESTÁ LA CLAVE
      obscureText: isPassword,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.grey.shade200,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 15,
        ),
      ),
    );
  }
}
