import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../accessibility/provider/accessibility_provider.dart';
import '../../checkout/screens/checkout_screen.dart';
import '../provider/cart_provider.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  String _money(double value) => '\$${value.toStringAsFixed(0)}';

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final accessibility = context.watch<AccessibilityProvider>();

    return Scaffold(
      backgroundColor: accessibility.appBackground,
      appBar: AppBar(
        backgroundColor: accessibility.appBarColor,
        foregroundColor: Colors.white,
        title: const Text('Carrito'),
      ),
      body: cart.isEmpty
          ? Center(
              child: Text(
                'Tu carrito está vacío',
                style: TextStyle(
                  color: accessibility.textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: cart.items.length,
                    itemBuilder: (context, index) {
                      final item = cart.items[index];

                      return Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: accessibility.surfaceColor,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.network(
                                item.imageUrl,
                                width: 70,
                                height: 70,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 70,
                                  height: 70,
                                  color: Colors.black12,
                                  child: const Icon(Icons.image_not_supported),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: TextStyle(
                                      color: accessibility.textColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    _money(item.price),
                                    style: TextStyle(
                                      color: accessibility.primaryColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      IconButton(
                                        onPressed: () {
                                          context.read<CartProvider>().decrease(
                                            item.id,
                                          );
                                        },
                                        icon: Icon(
                                          Icons.remove_circle_outline,
                                          color: accessibility.textColor,
                                        ),
                                      ),
                                      Text(
                                        item.quantity.toString(),
                                        style: TextStyle(
                                          color: accessibility.textColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () {
                                          context.read<CartProvider>().increase(
                                            item.id,
                                          );
                                        },
                                        icon: Icon(
                                          Icons.add_circle_outline,
                                          color: accessibility.textColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                context.read<CartProvider>().removeProduct(
                                  item.id,
                                );
                              },
                              icon: const Icon(Icons.delete, color: Colors.red),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: accessibility.surfaceColor,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
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
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accessibility.primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const CheckoutScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            'Continuar al pago',
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
              ],
            ),
    );
  }
}
