import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/product.dart';

class ProductServiceRestApi {
  static const String baseUrl = 'https://gardeniakosmetyka.com/api/v1';
  static const String token =
      'laN704E4dTtOfgqR40TY5NXrUUfGDAGBDzdgwCZG4aV9LWnF1F5DcLVMYwVq';
  final http.Client _client = http.Client();

  Future<List<ProductRestApi>> fetchProducts() async {
    try {
      print('[ProductService] Initiating API request to fetch products');

      final response = await _client.get(
        Uri.parse('$baseUrl/product/getProducts'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      print('[ProductService] API Response - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        // Decode and verify response structure
        final decodedResponse = json.decode(response.body);
        print('[ProductService] Response type: ${decodedResponse.runtimeType}');

        // Handle array response
        if (decodedResponse is List) {
          return decodedResponse
              .map((item) =>
                  ProductRestApi.fromJson(item as Map<String, dynamic>))
              .toList();
        }
        // Handle object response with data property
        else if (decodedResponse is Map<String, dynamic> &&
            decodedResponse.containsKey('data')) {
          final data = decodedResponse['data'];
          if (data is List) {
            return data
                .map((item) =>
                    ProductRestApi.fromJson(item as Map<String, dynamic>))
                .toList();
          }
        }

        print('[ProductService] Invalid response format: $decodedResponse');
        throw Exception('Unexpected response format');
      }

      throw Exception('HTTP Error: ${response.statusCode}');
    } catch (e) {
      print('[ProductService] Error fetching products: $e');
      throw Exception('Failed to fetch products: $e');
    }
  }

  List<ProductRestApi> filterProducts({
    required List<ProductRestApi> products,
    String? categoryName,
    bool onlyInStock = true,
  }) {
    return products.where((product) {
      if (onlyInStock && product.stock <= 0) return false;
      if (categoryName != null && product.categoryName != categoryName) {
        return false;
      }
      return true;
    }).toList();
  }

  // New utility methods
  static int? parseIntSafely(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) {
      try {
        return int.parse(value);
      } catch (e) {
        print('Failed to parse int value: $value');
        return null;
      }
    }
    return null;
  }

  static double? parseDoubleSafely(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        print('Failed to parse double value: $value');
        return null;
      }
    }
    return null;
  }
}
