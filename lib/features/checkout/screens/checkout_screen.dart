import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../../core/constants/api_config.dart';
import '../../accessibility/provider/accessibility_provider.dart';
import '../../auth/provider/auth_provider.dart';
import '../../cart/provider/cart_provider.dart';
import '../../orders/screens/purchase_history_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String paymentMethod = 'Efectivo';
  bool loading = false;

  String _money(double value) => '\$${value.toStringAsFixed(0)}';

  Future<void> _confirmOrder() async {
    final auth = context.read<AuthProvider>();
    final cart = context.read<CartProvider>();

    final userId =
        auth.user?['id']?.toString() ?? auth.user?['uid']?.toString() ?? '';

    if (userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay usuario autenticado')),
      );
      return;
    }

    if (cart.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('El carrito está vacío')));
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/orders'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': int.tryParse(userId) ?? userId,
          'paymentMethod': paymentMethod,
          'items': cart.toOrderItems(),
        }),
      );

      final data = jsonDecode(response.body);

      if (!mounted) return;

      if (response.statusCode == 201 && data['ok'] == true) {
        cart.clear();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Compra registrada correctamente')),
        );

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const PurchaseHistoryScreen()),
          (route) => route.isFirst,
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
                      child: Row(
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
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Método de pago',
                    style: TextStyle(
                      color: accessibility.textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _paymentOption(accessibility, 'Efectivo'),
                  _paymentOption(accessibility, 'Tarjeta'),
                  _paymentOption(accessibility, 'Transferencia'),
                  const SizedBox(height: 22),
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

  Widget _paymentOption(AccessibilityProvider accessibility, String value) {
    return RadioListTile<String>(
      value: value,
      groupValue: paymentMethod,
      activeColor: accessibility.primaryColor,
      title: Text(value, style: TextStyle(color: accessibility.textColor)),
      onChanged: (selected) {
        if (selected == null) return;

        setState(() {
          paymentMethod = selected;
        });
      },
    );
  }
}
