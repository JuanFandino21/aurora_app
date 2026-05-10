import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool notificationsEnabled = true;
  bool keepSessionEnabled = true;
  bool pricesWithSymbol = true;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      notificationsEnabled = prefs.getBool('settings_notifications') ?? true;
      keepSessionEnabled = prefs.getBool('settings_keep_session') ?? true;
      pricesWithSymbol = prefs.getBool('settings_prices_symbol') ?? true;
      loading = false;
    });
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('settings_notifications', notificationsEnabled);
    await prefs.setBool('settings_keep_session', keepSessionEnabled);
    await prefs.setBool('settings_prices_symbol', pricesWithSymbol);

    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Configuración guardada')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6E7F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF48FB1),
        elevation: 0,
        title: const Text('Configuración'),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _card(
                  child: SwitchListTile(
                    value: notificationsEnabled,
                    onChanged: (value) {
                      setState(() => notificationsEnabled = value);
                    },
                    title: const Text('Notificaciones'),
                    subtitle: const Text('Recibe avisos de tus compras'),
                  ),
                ),
                const SizedBox(height: 12),
                _card(
                  child: SwitchListTile(
                    value: keepSessionEnabled,
                    onChanged: (value) {
                      setState(() => keepSessionEnabled = value);
                    },
                    title: const Text('Mantener sesión iniciada'),
                    subtitle: const Text('Evita volver a iniciar sesión'),
                  ),
                ),
                const SizedBox(height: 12),
                _card(
                  child: SwitchListTile(
                    value: pricesWithSymbol,
                    onChanged: (value) {
                      setState(() => pricesWithSymbol = value);
                    },
                    title: const Text('Mostrar símbolo de moneda'),
                    subtitle: const Text('Formato: \$40000'),
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE91E63),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
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

  Widget _card({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: child,
    );
  }
}
