import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../../core/constants/api_config.dart';
import '../../accessibility/provider/accessibility_provider.dart';
import '../../auth/provider/auth_provider.dart';

class PurchaseHistoryScreen extends StatefulWidget {
  const PurchaseHistoryScreen({super.key});

  @override
  State<PurchaseHistoryScreen> createState() => _PurchaseHistoryScreenState();
}

class _PurchaseHistoryScreenState extends State<PurchaseHistoryScreen> {
  bool loading = true;
  String? errorMessage;
  List<Map<String, dynamic>> orders = [];

  final Map<int, List<Map<String, dynamic>>> orderItemsCache = {};

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadOrders);
  }

  String _money(dynamic value) {
    final number = value is num
        ? value.toDouble()
        : double.tryParse(value.toString()) ?? 0;
    return '\$${number.toStringAsFixed(0)}';
  }

  String _formatDate(dynamic value) {
    final raw = value?.toString() ?? '';
    if (raw.isEmpty) return '';

    try {
      final date = DateTime.parse(raw).toLocal();

      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final year = date.year.toString();

      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');

      return '$day/$month/$year $hour:$minute';
    } catch (_) {
      return raw;
    }
  }

  Future<void> _loadOrders() async {
    final auth = context.read<AuthProvider>();
    final userId =
        auth.user?['id']?.toString() ?? auth.user?['uid']?.toString() ?? '';

    if (userId.isEmpty) {
      setState(() {
        loading = false;
        errorMessage = 'No hay usuario autenticado';
      });
      return;
    }

    setState(() {
      loading = true;
      errorMessage = null;
      orders = [];
      orderItemsCache.clear();
    });

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/orders/user/$userId'),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['ok'] == true) {
        final loadedOrders = (data['orders'] as List<dynamic>)
            .map((item) => Map<String, dynamic>.from(item))
            .toList();

        for (final order in loadedOrders) {
          final orderId = int.tryParse(order['id'].toString()) ?? 0;
          if (orderId > 0) {
            orderItemsCache[orderId] = await _loadOrderItems(orderId);
          }
        }

        if (!mounted) return;

        setState(() {
          orders = loadedOrders;
          loading = false;
        });
      } else {
        if (!mounted) return;

        setState(() {
          errorMessage =
              data['message']?.toString() ??
              'No fue posible cargar el historial';
          loading = false;
        });
      }
    } catch (_) {
      if (!mounted) return;

      setState(() {
        errorMessage = 'No fue posible conectar con la API';
        loading = false;
      });
    }
  }

  Future<List<Map<String, dynamic>>> _loadOrderItems(int orderId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/orders/$orderId'),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['ok'] == true) {
        return (data['items'] as List<dynamic>)
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }

      return [];
    } catch (_) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final accessibility = context.watch<AccessibilityProvider>();

    return Scaffold(
      backgroundColor: accessibility.appBackground,
      appBar: AppBar(
        backgroundColor: accessibility.appBarColor,
        foregroundColor: Colors.white,
        title: const Text('Historial de compras'),
        actions: [
          IconButton(onPressed: _loadOrders, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: accessibility.textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            )
          : orders.isEmpty
          ? Center(
              child: Text(
                'Todavía no tienes compras registradas',
                style: TextStyle(
                  color: accessibility.textColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadOrders,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final order = orders[index];
                  final orderId = int.tryParse(order['id'].toString()) ?? 0;
                  final items = orderItemsCache[orderId] ?? [];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 18),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: accessibility.surfaceColor,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Compra #$orderId',
                                style: TextStyle(
                                  color: accessibility.textColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                            Text(
                              _money(order['total']),
                              style: TextStyle(
                                color: accessibility.primaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _formatDate(order['createdAt']),
                          style: TextStyle(
                            color: accessibility.mutedTextColor,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: accessibility.primaryColor.withValues(
                                  alpha: 0.12,
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                order['status']?.toString() ?? 'CONFIRMED',
                                style: TextStyle(
                                  color: accessibility.primaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Pago: ${order['payment_method'] ?? 'No especificado'}',
                                style: TextStyle(
                                  color: accessibility.mutedTextColor,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Divider(
                          color: accessibility.mutedTextColor.withValues(
                            alpha: 0.25,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (items.isEmpty)
                          Text(
                            'No hay detalle para esta compra',
                            style: TextStyle(
                              color: accessibility.mutedTextColor,
                            ),
                          )
                        else
                          Column(
                            children: items.map((item) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        item['imageUrl']?.toString() ?? '',
                                        width: 58,
                                        height: 58,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stack) {
                                          return Container(
                                            width: 58,
                                            height: 58,
                                            color: Colors.black12,
                                            child: const Icon(
                                              Icons.image_not_supported,
                                              size: 24,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item['product_name']?.toString() ??
                                                'Producto',
                                            style: TextStyle(
                                              color: accessibility.textColor,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 15,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Cantidad: ${item['quantity']} · Unidad: ${_money(item['unit_price'])}',
                                            style: TextStyle(
                                              color:
                                                  accessibility.mutedTextColor,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _money(item['subtotal']),
                                      style: TextStyle(
                                        color: accessibility.primaryColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }
}
