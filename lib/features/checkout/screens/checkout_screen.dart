import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/api_config.dart';
import '../../accessibility/provider/accessibility_provider.dart';
import '../../auth/provider/auth_provider.dart';
import '../../cart/provider/cart_provider.dart';
import 'order_success_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  static const String defaultPaymentMethod = 'Pago contra entrega';

  final TextEditingController addressController = TextEditingController();

  String paymentMethod = defaultPaymentMethod;
  bool loading = false;

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
    _loadPaymentMethod();
  }

  @override
  void dispose() {
    addressController.dispose();
    super.dispose();
  }

  Future<void> _loadPaymentMethod() async {
    final prefs = await SharedPreferences.getInstance();

    final saved =
        prefs.getString('preferred_payment_method') ?? defaultPaymentMethod;

    if (!mounted) return;

    setState(() {
      paymentMethod = _normalizeMethod(saved);
    });
  }

  String _normalizeMethod(String value) {
    if (value == 'Efectivo' || value == 'Contra entrega') {
      return defaultPaymentMethod;
    }

    final exists = methods.any((item) => item['value'] == value);

    return exists ? value : defaultPaymentMethod;
  }

  Future<void> _savePreferredMethod(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('preferred_payment_method', value);
  }

  String _money(double value) => '\$${value.toStringAsFixed(0)}';

  int? _getUserId(AuthProvider auth) {
    final raw = auth.user?['id'] ?? auth.user?['uid'] ?? auth.user?['userId'];

    if (raw == null) return null;

    final id = int.tryParse(raw.toString());

    if (id == null || id <= 0) return null;

    return id;
  }

  Future<void> _confirmOrder() async {
    final auth = context.read<AuthProvider>();
    final cart = context.read<CartProvider>();

    final userId = _getUserId(auth);
    final address = addressController.text.trim();

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No hay usuario autenticado. Cierra sesión e inicia nuevamente.',
          ),
        ),
      );
      return;
    }

    if (cart.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('El carrito está vacío')));
      return;
    }

    if (address.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa una dirección de entrega válida'),
        ),
      );
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      await _savePreferredMethod(paymentMethod);

      final totalBeforeClear = cart.total;

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/orders'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'paymentMethod': paymentMethod,
          'address': address,
          'deliveryAddress': address,
          'items': cart.toOrderItems(),
        }),
      );

      final data = jsonDecode(response.body);

      if (!mounted) return;

      if (response.statusCode == 201 && data['ok'] == true) {
        cart.clear();

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => OrderSuccessScreen(
              orderId: int.tryParse(data['orderId'].toString()),
              total: totalBeforeClear,
              paymentMethod: paymentMethod,
              address: address,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              data['message']?.toString() ??
                  'No fue posible registrar la compra',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No fue posible conectar con la API')),
      );
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final accessibility = context.watch<AccessibilityProvider>();

    return Scaffold(
      backgroundColor: accessibility.appBackground,
      appBar: AppBar(
        backgroundColor: accessibility.appBarColor,
        foregroundColor: Colors.white,
        title: const Text('Confirmar compra'),
      ),
      body: cart.isEmpty
          ? Center(
              child: Text(
                'No hay productos para comprar',
                style: TextStyle(
                  color: accessibility.textColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Resumen de compra',
                    style: TextStyle(
                      color: accessibility.textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...cart.items.map(
                    (item) => Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: accessibility.surfaceColor,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${item.name} x${item.quantity}',
                                  style: TextStyle(
                                    color: accessibility.textColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Text(
                                _money(item.subtotal),
                                style: TextStyle(
                                  color: accessibility.primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          if (item.tone != null) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text(
                                  'Tono seleccionado',
                                  style: TextStyle(
                                    color: accessibility.mutedTextColor,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: item.tone,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: accessibility.textColor
                                          .withOpacity(0.25),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Dirección de entrega',
                    style: TextStyle(
                      color: accessibility.textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: addressController,
                    minLines: 1,
                    maxLines: 2,
                    style: TextStyle(color: accessibility.textColor),
                    decoration: InputDecoration(
                      hintText: 'Ej: Calle 10 # 5-20, barrio...',
                      hintStyle: TextStyle(color: accessibility.mutedTextColor),
                      filled: true,
                      fillColor: accessibility.surfaceColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    'Método de pago',
                    style: TextStyle(
                      color: accessibility.textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...methods.map(
                    (item) => Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: accessibility.surfaceColor,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: RadioListTile<String>(
                        value: item['value']!,
                        groupValue: paymentMethod,
                        activeColor: accessibility.primaryColor,
                        title: Text(
                          item['title']!,
                          style: TextStyle(
                            color: accessibility.textColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          item['subtitle']!,
                          style: TextStyle(color: accessibility.mutedTextColor),
                        ),
                        onChanged: (selected) async {
                          if (selected == null) return;

                          setState(() {
                            paymentMethod = selected;
                          });

                          await _savePreferredMethod(selected);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: accessibility.surfaceColor,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total',
                          style: TextStyle(
                            color: accessibility.textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                        Text(
                          _money(cart.total),
                          style: TextStyle(
                            color: accessibility.primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Tu pedido tardará de 1 a 4 días en llegar después de confirmarlo.',
                    style: TextStyle(
                      color: accessibility.mutedTextColor,
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accessibility.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      onPressed: loading ? null : _confirmOrder,
                      child: loading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Confirmar compra',
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
}
