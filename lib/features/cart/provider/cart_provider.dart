import 'package:flutter/material.dart';

import '../../products/models/product_model.dart';

class CartItem {
  final int id;
  final String name;
  final double price;
  final String imageUrl;
  final String productType;
  final Color? tone;
  int quantity;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
    this.productType = '',
    this.tone,
    this.quantity = 1,
  });

  double get subtotal => price * quantity;

  String get toneHex {
    if (tone == null) return '';
    final value = tone!.value.toRadixString(16).padLeft(8, '0');
    return '#$value';
  }

  String get cartKey => '$id-${productType.toLowerCase()}-$toneHex';

  Map<String, dynamic> toOrderJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'imageUrl': imageUrl,
      'quantity': quantity,
      'productType': productType,
      'selectedTone': toneHex,
      'tone': toneHex,
    };
  }
}

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);

  bool get isEmpty => _items.isEmpty;

  int get totalItems {
    return _items.fold(0, (sum, item) => sum + item.quantity);
  }

  double get total {
    return _items.fold(0, (sum, item) => sum + item.subtotal);
  }

  void addProduct(dynamic product, {Color? tone, String? productType}) {
    final normalized = _normalizeProduct(product);
    if (normalized == null) return;

    final type = (productType?.trim().isNotEmpty ?? false)
        ? productType!.trim().toLowerCase()
        : normalized.category.trim().toLowerCase();

    final toneHex = tone == null
        ? ''
        : '#${tone.value.toRadixString(16).padLeft(8, '0')}';

    final index = _items.indexWhere(
      (item) =>
          item.id == normalized.id &&
          item.productType.toLowerCase() == type &&
          item.toneHex == toneHex,
    );

    if (index >= 0) {
      _items[index].quantity++;
    } else {
      _items.add(
        CartItem(
          id: normalized.id,
          name: normalized.name,
          price: normalized.price,
          imageUrl: normalized.imageUrl,
          productType: type,
          tone: tone,
        ),
      );
    }

    notifyListeners();
  }

  void addItem(Map<String, dynamic> product) {
    addProduct(product);
  }

  void addToCart(Map<String, dynamic> product) {
    addProduct(product);
  }

  void increaseItem(CartItem item) {
    final index = _items.indexWhere(
      (cartItem) => cartItem.cartKey == item.cartKey,
    );
    if (index < 0) return;

    _items[index].quantity++;
    notifyListeners();
  }

  void decreaseItem(CartItem item) {
    final index = _items.indexWhere(
      (cartItem) => cartItem.cartKey == item.cartKey,
    );
    if (index < 0) return;

    if (_items[index].quantity > 1) {
      _items[index].quantity--;
    } else {
      _items.removeAt(index);
    }

    notifyListeners();
  }

  void removeItem(CartItem item) {
    _items.removeWhere((cartItem) => cartItem.cartKey == item.cartKey);
    notifyListeners();
  }

  void increase(int productId) {
    final index = _items.indexWhere((item) => item.id == productId);
    if (index < 0) return;

    _items[index].quantity++;
    notifyListeners();
  }

  void decrease(int productId) {
    final index = _items.indexWhere((item) => item.id == productId);
    if (index < 0) return;

    if (_items[index].quantity > 1) {
      _items[index].quantity--;
    } else {
      _items.removeAt(index);
    }

    notifyListeners();
  }

  void removeProduct(int productId) {
    _items.removeWhere((item) => item.id == productId);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }

  List<Map<String, dynamic>> toOrderItems() {
    return _items.map((item) => item.toOrderJson()).toList();
  }

  Product? _normalizeProduct(dynamic product) {
    if (product is Product) {
      return product;
    }

    if (product is Map<String, dynamic>) {
      return Product.fromJson(product);
    }

    if (product is Map) {
      return Product.fromJson(Map<String, dynamic>.from(product));
    }

    return null;
  }
}
