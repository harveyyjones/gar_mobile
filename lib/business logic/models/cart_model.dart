// lib/business_logic/models/cart_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shop_app/business_logic_rest_api/models/product.dart';

class CartItem {
  final String productId;
  final String name;
  final String image;
  final double price;
  final double salePrice; // Added to handle sale prices
  int quantity;
  final String categoryName; // Added for better organization

  CartItem({
    required this.productId,
    required this.name,
    required this.image,
    required this.price,
    required this.salePrice,
    required this.quantity,
    required this.categoryName,
  });

  // Create from ProductRestApi
  factory CartItem.fromProduct(ProductRestApi product, {int quantity = 1}) {
    return CartItem(
      productId: product.id.toString(),
      name: product.name,
      image: product.imageUrl,
      price: product.price,
      salePrice: product.salePrice,
      quantity: quantity,
      categoryName: product.categoryName,
    );
  }

  // Simplified Firestore data structure
  factory CartItem.fromFirestore(Map<String, dynamic> data) {
    return CartItem(
      productId: data['product_id'] ?? '',
      name: data['name'] ?? '',
      image: data['image'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      salePrice: (data['sale_price'] ?? 0).toDouble(),
      quantity: data['quantity'] ?? 0,
      categoryName: data['category'] ?? '',
    );
  }

  // Only store essential data in Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'product_id': productId,
      'name': name,
      'image': image,
      'price': price,
      'sale_price': salePrice,
      'quantity': quantity,
      'category': categoryName,
      'updated_at': FieldValue.serverTimestamp(),
    };
  }

  CartItem copyWith({
    String? productId,
    String? name,
    String? image,
    double? price,
    double? salePrice,
    int? quantity,
    String? categoryName,
  }) {
    return CartItem(
      productId: productId ?? this.productId,
      name: name ?? this.name,
      image: image ?? this.image,
      price: price ?? this.price,
      salePrice: salePrice ?? this.salePrice,
      quantity: quantity ?? this.quantity,
      categoryName: categoryName ?? this.categoryName,
    );
  }

  // Helper to get effective price (sale price if available)
  double get effectivePrice => salePrice < price ? salePrice : price;

  // Calculate item total
  double get total => effectivePrice * quantity;
}

class Cart {
  final List<CartItem> items;

  Cart({required this.items});

  factory Cart.empty() => Cart(items: []);

  factory Cart.fromFirestore(Map<String, dynamic> data) {
    final List<dynamic> cartItems = data['cart_items'] ?? [];
    return Cart(
      items: cartItems
          .map((item) => CartItem.fromFirestore(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'cart_items': items.map((item) => item.toFirestore()).toList(),
      'updated_at': FieldValue.serverTimestamp(),
      'total_items': itemCount,
      'total_amount': total,
    };
  }

  // Helpers for cart manipulation
  double get total => items.fold(
        0,
        (sum, item) => sum + item.total,
      );

  int get itemCount => items.fold(
        0,
        (sum, item) => sum + item.quantity,
      );

  // Get items by seller
  Map<String, List<CartItem>> get itemsBySeller {
    // figure out whats the below code in case.
    return groupBy(items, (item) => item.categoryName);
  }

  // Helper to group items
  Map<K, List<T>> groupBy<T, K>(Iterable<T> items, K Function(T) key) {
    Map<K, List<T>> result = {};
    for (var item in items) {
      final itemKey = key(item);
      if (!result.containsKey(itemKey)) {
        result[itemKey] = [];
      }
      result[itemKey]!.add(item);
    }
    return result;
  }

  // Create a new cart with updated item
  Cart updateItem(CartItem updatedItem) {
    final newItems = items.map((item) {
      if (item.productId == updatedItem.productId) {
        return updatedItem;
      }
      return item;
    }).toList();
    return Cart(items: newItems);
  }

  // Remove item from cart
  Cart removeItem(String productId) {
    return Cart(
      items: items.where((item) => item.productId != productId).toList(),
    );
  }

  // Clear cart
  Cart clear() => Cart(items: []);
}
