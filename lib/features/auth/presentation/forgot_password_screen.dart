import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../provider/auth_provider.dart';
import 'login_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final emailController = TextEditingController();
  bool loading = false;

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final email = emailController.text.trim();
    if (email.isEmpty) return;

    setState(() => loading = true);

    final ok = await context.read<AuthProvider>().sendPasswordReset(email);

    if (!mounted) return;

    setState(() => loading = false);

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Te enviamos un correo para restablecer tu contraseña'),
        ),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No fue posible enviar el correo')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD5A9D8),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            Image.asset('assets/logo.png', height: 140),
            const Spacer(),
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(35),
              ),
              child: Column(
                children: [
                  const Text(
                    'Recupera tu contraseña',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                  const SizedBox(height: 40),
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      hintText: 'Correo Electrónico',
                      border: UnderlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 45),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: loading ? null : _send,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE785EF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: loading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Enviar',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (route) => false,
                      );
                    },
                    child: const Text(
                      '¿Tienes una cuenta? Inicia sesión',
                      style: TextStyle(color: Color(0xFFE91E63)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),
          ],
        ),
      ),
    );
  }
}
