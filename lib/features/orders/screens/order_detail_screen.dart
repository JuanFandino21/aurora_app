import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../accessibility/provider/accessibility_provider.dart';
import '../../products/screens/home_screen.dart';

class OrderDetailScreen extends StatelessWidget {
  final Map<String, dynamic> order;

  const OrderDetailScreen({super.key, required this.order});

  String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw).toLocal();
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    final accessibility = context.watch<AccessibilityProvider>();
    final items = List<Map<String, dynamic>>.from(order['items'] ?? []);

    final subtotal = (order['subtotal'] as num?)?.toDouble() ?? 0;
    final shipping = (order['shipping'] as num?)?.toDouble() ?? 0;
    final total = (order['total'] as num?)?.toDouble() ?? 0;

    return Scaffold(
      backgroundColor: accessibility.appBackground,
      appBar: AppBar(
        backgroundColor: accessibility.appBarColor,
        elevation: 0,
        title: Text(
          'Detalle de compra',
          style: TextStyle(color: accessibility.textColor),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: accessibility.surfaceColor,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order['id']?.toString() ?? 'Pedido',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: accessibility.textColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _formatDate(order['date']?.toString() ?? ''),
                  style: TextStyle(color: accessibility.mutedTextColor),
                ),
                const SizedBox(height: 12),
                Text(
                  'Estado: ${order['status'] ?? 'Completado'}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: accessibility.textColor,
                  ),
                ),
                Text(
                  'Pago: ${order['paymentMethod'] ?? '-'}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: accessibility.textColor,
                  ),
                ),
                if ((order['address'] ?? '').toString().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Dirección: ${order['address']}',
                    style: TextStyle(color: accessibility.textColor),
                  ),
                ],
                const Divider(height: 28),
                ...items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            item['imageUrl']?.toString() ?? '',
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '${item['name']} x${item['quantity']}',
                            style: TextStyle(color: accessibility.textColor),
                          ),
                        ),
                        Text(
                          '\$${((item['price'] as num?)?.toDouble() ?? 0).toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Subtotal'),
                    Text('\$${subtotal.toStringAsFixed(0)}'),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Envío'),
                    Text('\$${shipping.toStringAsFixed(0)}'),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '\$${total.toStringAsFixed(0)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE91E63),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                'Seguir comprando',
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
}
