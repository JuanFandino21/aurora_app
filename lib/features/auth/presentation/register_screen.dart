import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../provider/auth_provider.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool obscure = true;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Completa todos los campos'),
        ),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La contraseña debe tener mínimo 6 caracteres'),
        ),
      );
      return;
    }

    final auth = context.read<AuthProvider>();

    final ok = await auth.register(
      name,
      email,
      password,
    );

    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cuenta creada correctamente en MySQL'),
        ),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        ),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No fue posible crear la cuenta'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFD1A0D0),
      body: SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top,
            ),
            child: Column(
              children: [
                const SizedBox(height: 70),
                Image.asset(
                  'assets/logo.png',
                  height: 130,
                ),
                const SizedBox(height: 170),
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 18),
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(36),
                      bottom: Radius.circular(36),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const LoginScreen(),
                                  ),
                                );
                              },
                              child: Container(
                                height: 44,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0D6F3),
                                  borderRadius: BorderRadius.circular(22),
                                ),
                                child: const Center(
                                  child: Text(
                                    'Iniciar sesión',
                                    style: TextStyle(
                                      color: Color(0xFFE91E63),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Container(
                              height: 44,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE785EF),
                                borderRadius: BorderRadius.circular(22),
                              ),
                              child: const Center(
                                child: Text(
                                  'Registrarse',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Bienvenido a Aurora',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 34),
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          hintText: 'Nombre',
                          border: UnderlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 22),
                      TextField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          hintText: 'Email',
                          border: UnderlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 22),
                      TextField(
                        controller: passwordController,
                        obscureText: obscure,
                        decoration: InputDecoration(
                          hintText: 'Contraseña',
                          border: const UnderlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscure
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                obscure = !obscure;
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 34),
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: auth.isLoading ? null : _register,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE785EF),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: auth.isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text(
                                  'Crear cuenta',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        '',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}