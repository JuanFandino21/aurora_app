import 'package:flutter/material.dart';

class OrderSuccessScreen extends StatelessWidget {
  final int? orderId;
  final double total;
  final String paymentMethod;
  final String address;

  const OrderSuccessScreen({
    super.key,
    this.orderId,
    required this.total,
    required this.paymentMethod,
    required this.address,
  });

  String _money(double value) => '\$${value.toStringAsFixed(0)}';

  String _paymentMessage() {
    switch (paymentMethod) {
      case 'Tarjeta':
        return 'Pago con tarjeta simulado correctamente.';
      case 'Transferencia':
        return 'Transferencia simulada correctamente.';
      case 'Nequi':
        return 'Pago con Nequi simulado correctamente.';
      case 'Daviplata':
        return 'Pago con Daviplata simulado correctamente.';
      default:
        return 'Pagarás cuando recibas tu pedido.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6E7F2),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 115,
                height: 115,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFE91E63),
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 72),
              ),
              const SizedBox(height: 28),
              const Text(
                'Compra confirmada',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 14),
              const Text(
                'Tu pedido fue registrado correctamente. Tu pedido tardará de 1 a 4 días en llegar.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.4,
                  color: Colors.black54,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                _paymentMessage(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFFE91E63),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 26),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    _row(
                      'Pedido',
                      orderId == null ? 'Confirmado' : '#$orderId',
                    ),
                    _row('Total', _money(total)),
                    _row('Pago', paymentMethod),
                    _row('Dirección', address),
                    _row('Entrega', '1 a 4 días'),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.popUntil(context, (route) => route.isFirst);
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
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
