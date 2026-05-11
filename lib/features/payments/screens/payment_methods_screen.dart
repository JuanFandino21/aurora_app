import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  static const String defaultMethod = 'Pago contra entrega';

  String method = defaultMethod;
  bool loading = true;

  final List<Map<String, String>> methods = const [
    {
      'value': 'Pago contra entrega',
      'title': 'Pago contra entrega',
      'subtitle': 'Paga cuando recibas tu pedido',
    },
    {
      'value': 'Tarjeta',
      'title': 'Tarjeta',
      'subtitle': 'Simulación de pago con tarjeta',
    },
    {
      'value': 'Transferencia',
      'title': 'Transferencia',
      'subtitle': 'Simulación de transferencia bancaria',
    },
    {
      'value': 'Nequi',
      'title': 'Nequi',
      'subtitle': 'Simulación de pago móvil',
    },
    {
      'value': 'Daviplata',
      'title': 'Daviplata',
      'subtitle': 'Simulación de billetera móvil',
    },
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();

    final saved = prefs.getString('preferred_payment_method') ?? defaultMethod;

    setState(() {
      method = _normalizeMethod(saved);
      loading = false;
    });
  }

  String _normalizeMethod(String value) {
    if (value == 'Efectivo' || value == 'Contra entrega') {
      return defaultMethod;
    }

    final exists = methods.any((item) => item['value'] == value);

    return exists ? value : defaultMethod;
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('preferred_payment_method', method);

    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Método guardado: $method')));

    Navigator.pop(context, method);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6E7F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF48FB1),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Métodos de pago'),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Selecciona tu método preferido',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Esta app realiza una simulación de pago para el prototipo.',
                  style: TextStyle(color: Colors.black54, height: 1.3),
                ),
                const SizedBox(height: 18),
                ...methods.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _card(
                      child: RadioListTile<String>(
                        value: item['value']!,
                        groupValue: method,
                        activeColor: const Color(0xFFE91E63),
                        onChanged: (value) {
                          setState(() {
                            method = value ?? defaultMethod;
                          });
                        },
                        title: Text(
                          item['title']!,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(item['subtitle']!),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
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
