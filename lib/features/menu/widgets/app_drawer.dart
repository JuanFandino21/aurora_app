import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../accessibility/provider/accessibility_provider.dart';
import '../../auth/provider/auth_provider.dart';
import '../../orders/screens/purchase_history_screen.dart';
import '../../payments/screens/payment_methods_screen.dart';
import '../../settings/screens/settings_screen.dart';

class AppDrawer extends StatelessWidget {
  final String userName;
  final String userEmail;
  final String? profileImagePath;

  final VoidCallback onEditProfile;
  final VoidCallback onAccessibility;
  final VoidCallback onLogout;

  const AppDrawer({
    super.key,
    required this.userName,
    required this.userEmail,
    this.profileImagePath,
    required this.onEditProfile,
    required this.onAccessibility,
    required this.onLogout,
  });

  String _imagePath(AuthProvider authProvider) {
    final fromProvider = authProvider.profileImagePath?.trim() ?? '';
    final fromUser =
        authProvider.user?['profileImagePath']?.toString().trim() ?? '';
    final fromParam = profileImagePath?.trim() ?? '';

    final path = fromProvider.isNotEmpty
        ? fromProvider
        : fromUser.isNotEmpty
        ? fromUser
        : fromParam;

    if (path.isEmpty) return '';

    final file = File(path);

    if (!file.existsSync()) return '';

    return path;
  }

  @override
  Widget build(BuildContext context) {
    final accessibility = context.watch<AccessibilityProvider>();
    final authProvider = context.watch<AuthProvider>();

    final nameFromProvider =
        authProvider.user?['name']?.toString().trim() ?? '';

    final emailFromProvider =
        authProvider.user?['email']?.toString().trim() ?? '';

    final identification =
        authProvider.user?['identification']?.toString().trim() ?? '';

    final phone = authProvider.user?['phone']?.toString().trim() ?? '';

    final cleanName = nameFromProvider.isNotEmpty
        ? nameFromProvider
        : userName.trim().isNotEmpty
        ? userName.trim()
        : 'Usuario';

    final cleanEmail = emailFromProvider.isNotEmpty
        ? emailFromProvider
        : userEmail.trim();

    final imagePath = _imagePath(authProvider);

    return Drawer(
      backgroundColor: accessibility.surfaceColor,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  icon: Icon(Icons.menu, color: accessibility.textColor),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              const SizedBox(height: 12),
              CircleAvatar(
                radius: 43,
                backgroundColor: const Color(0xFFF1B7E2),
                backgroundImage: imagePath.isNotEmpty
                    ? FileImage(File(imagePath))
                    : null,
                child: imagePath.isEmpty
                    ? Text(
                        cleanName[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: Colors.black54,
                        ),
                      )
                    : null,
              ),
              const SizedBox(height: 14),
              Text(
                cleanName,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  color: accessibility.textColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                cleanEmail,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: accessibility.mutedTextColor,
                  fontSize: 15,
                ),
              ),
              if (identification.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'ID: $identification',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: accessibility.mutedTextColor,
                    fontSize: 13,
                  ),
                ),
              ],
              if (phone.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'Tel: $phone',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: accessibility.mutedTextColor,
                    fontSize: 13,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  onEditProfile();
                },
                child: const Text(
                  'Editar perfil',
                  style: TextStyle(
                    color: Color(0xFFE91E63),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: 34),
              _drawerItem(
                accessibility,
                icon: Icons.history,
                title: 'Historial de compras',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PurchaseHistoryScreen(),
                    ),
                  );
                },
              ),
              _drawerItem(
                accessibility,
                icon: Icons.settings,
                title: 'Configuración de app',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                },
              ),
              _drawerItem(
                accessibility,
                icon: Icons.payments,
                title: 'Métodos de pago',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PaymentMethodsScreen(),
                    ),
                  );
                },
              ),
              _drawerItem(
                accessibility,
                icon: Icons.accessibility,
                title: 'Accesibilidad',
                onTap: () {
                  Navigator.pop(context);
                  onAccessibility();
                },
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE91E63),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: onLogout,
                  child: const Text(
                    'Cerrar sesión',
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
      ),
    );
  }

  Widget _drawerItem(
    AccessibilityProvider accessibility, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: accessibility.textColor),
      title: Text(
        title,
        style: TextStyle(fontSize: 18, color: accessibility.textColor),
      ),
      onTap: onTap,
    );
  }
}
