// lib/business_logic/models/cart_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class CartItem {
  final String productId;
  final String name;
  final String image;
  final double price;
  final String currency;
  int quantity;
  final String salerId; // Make sure this is properly initialized

  CartItem({
    required this.productId,
    required this.name,
    required this.image,
    required this.price,
    required this.currency,
    required this.quantity,
    required this.salerId,
  });

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      productId: map['product_id'] ?? '',
      name: map['name'] ?? '',
      image: map['image'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      currency: map['currency'] ?? '', // Ensure currency has a default value
      quantity: map['quantity'] ?? 1,
      salerId: map['seller_id'] ?? '', // Changed from 'saler_id' to 'seller_id'
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'product_id': productId,
      'name': name,
      'image': image,
      'price': price,
      'currency': currency,
      'quantity': quantity,
      'seller_id': salerId, // Changed from 'saler_id' to 'seller_id'
    };
  }

  CartItem copyWith({
    String? productId,
    String? name,
    String? image,
    double? price,
    String? currency,
    int? quantity,
    String? salerId,
  }) {
    return CartItem(
      productId: productId ?? this.productId,
      name: name ?? this.name,
      image: image ?? this.image,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      quantity: quantity ?? this.quantity,
      salerId: salerId ?? this.salerId,
    );
  }

  factory CartItem.fromFirestore(Map<String, dynamic> data) {
    return CartItem(
      productId: data['product_id'] ?? '',
      name: data['name'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      currency: data['currency'] ?? '',
      image: data['image'] ?? '',
      quantity: data['quantity'] ?? 0,
      salerId: data['seller_id'] ?? '', // Changed from 'saler_id' to 'seller_id'
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'product_id': productId,
      'name': name,
      'price': price,
      'currency': currency,
      'image': image,
      'quantity': quantity,
      'seller_id': salerId,
    };
  }
}

class Cart {
  final List<CartItem> items;

  Cart({
    required this.items,
  });

  factory Cart.fromMap(Map<String, dynamic> map) {
    final cartItems = (map['cart_items'] as List?)?.map(
          (item) => CartItem.fromMap(item as Map<String, dynamic>),
        ) ??
        [];
    return Cart(items: cartItems.toList());
  }

  Map<String, dynamic> toMap() {
    return {
      'cart_items': items.map((item) => item.toMap()).toList(),
      'updated_at': FieldValue.serverTimestamp(), // Added updated_at field
    };
  }

  double get total => items.fold(
        0,
        (sum, item) => sum + (item.price * item.quantity),
      );

  int get itemCount => items.fold(
        0,
        (sum, item) => sum + item.quantity,
      );
}
