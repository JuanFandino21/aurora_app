class Product {
  final int id;
  final String name;
  final String category;
  final double price;
  final String imageUrl;
  final String description;
  final String brand;
  final int stock;
  final bool active;

  const Product({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.imageUrl,
    required this.description,
    this.brand = '',
    this.stock = 0,
    this.active = true,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: _toInt(json['id']),
      name: json['name']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      price: _toDouble(json['price']),
      imageUrl: json['imageUrl']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      brand: json['brand']?.toString() ?? '',
      stock: _toInt(json['stock']),
      active: _toBool(json['active']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'price': price,
      'imageUrl': imageUrl,
      'description': description,
      'brand': brand,
      'stock': stock,
      'active': active,
    };
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  static bool _toBool(dynamic value) {
    if (value == null) return true;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is num) return value.toInt() == 1;
    return value.toString() == '1' || value.toString().toLowerCase() == 'true';
  }
}
