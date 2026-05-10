import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../core/constants/api_config.dart';
import '../models/product_model.dart';

class ProductProvider extends ChangeNotifier {
  List<Product> products = [];
  bool isLoading = false;
  String? errorMessage;

  Future<void> fetchProducts() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/products'),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['ok'] == true) {
        final list = data['products'] as List<dynamic>;

        products = list
            .map((item) => Product.fromJson(Map<String, dynamic>.from(item)))
            .toList();

        errorMessage = null;
      } else {
        errorMessage =
            data['message']?.toString() ?? 'No fue posible cargar productos';
      }
    } catch (e) {
      errorMessage = 'No fue posible conectar con la API de productos';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  List<Product> byCategory(String category) {
    return products
        .where(
          (product) => product.category.toLowerCase() == category.toLowerCase(),
        )
        .toList();
  }

  List<Product> search(String query, String category) {
    final cleanQuery = query.trim().toLowerCase();
    final cleanCategory = category.trim().toLowerCase();

    return products.where((product) {
      final matchesCategory = product.category.toLowerCase() == cleanCategory;
      final matchesSearch =
          cleanQuery.isEmpty ||
          product.name.toLowerCase().contains(cleanQuery) ||
          product.description.toLowerCase().contains(cleanQuery);

      return matchesCategory && matchesSearch;
    }).toList();
  }
}
