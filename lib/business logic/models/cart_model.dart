// lib/business_logic/models/cart_model.dart

class CartItem {
  final String productId;
  final String name;
  final String image;
  final double price;
  final String currency;
  int quantity;

  CartItem({
    required this.productId,
    required this.name,
    required this.image,
    required this.price,
    required this.currency,
    required this.quantity,
  });

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      productId: map['product_id'] ?? '',
      name: map['name'] ?? '',
      image: map['image'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      currency: map['currency'] ?? 'PLN',
      quantity: map['quantity'] ?? 1,
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
    };
  }

  CartItem copyWith({
    String? productId,
    String? name,
    String? image,
    double? price,
    String? currency,
    int? quantity,
  }) {
    return CartItem(
      productId: productId ?? this.productId,
      name: name ?? this.name,
      image: image ?? this.image,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      quantity: quantity ?? this.quantity,
    );
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