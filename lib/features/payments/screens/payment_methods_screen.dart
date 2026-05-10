import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  String method = 'Tarjeta';
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      method = prefs.getString('preferred_payment_method') ?? 'Tarjeta';
      loading = false;
    });
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('preferred_payment_method', method);

    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Método de pago guardado')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6E7F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF48FB1),
        elevation: 0,
        title: const Text('Métodos de pago'),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _card(
                  child: RadioListTile<String>(
                    value: 'Tarjeta',
                    groupValue: method,
                    onChanged: (value) => setState(() => method = value!),
                    title: const Text('Tarjeta'),
                    subtitle: const Text('Débito o crédito'),
                  ),
                ),
                const SizedBox(height: 12),
                _card(
                  child: RadioListTile<String>(
                    value: 'PSE',
                    groupValue: method,
                    onChanged: (value) => setState(() => method = value!),
                    title: const Text('PSE'),
                    subtitle: const Text('Pago por banco'),
                  ),
                ),
                const SizedBox(height: 12),
                _card(
                  child: RadioListTile<String>(
                    value: 'Contra entrega',
                    groupValue: method,
                    onChanged: (value) => setState(() => method = value!),
                    title: const Text('Contra entrega'),
                    subtitle: const Text('Paga al recibir'),
                  ),
                ),
                const SizedBox(height: 12),
                _card(
                  child: RadioListTile<String>(
                    value: 'Nequi',
                    groupValue: method,
                    onChanged: (value) => setState(() => method = value!),
                    title: const Text('Nequi'),
                    subtitle: const Text('Pago móvil'),
                  ),
                ),
                const SizedBox(height: 12),
                _card(
                  child: RadioListTile<String>(
                    value: 'Daviplata',
                    groupValue: method,
                    onChanged: (value) => setState(() => method = value!),
                    title: const Text('Daviplata'),
                    subtitle: const Text('Billetera móvil'),
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
                      'Guardar método',
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
