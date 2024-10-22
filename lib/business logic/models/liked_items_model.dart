import 'package:cloud_firestore/cloud_firestore.dart';

class LikedProduct {
  final String categoryPath;
  final String currency;
  final String id;
  final bool isVisible;
  final DateTime likedAt;
  final String name;
  final double price;
  final String productDescription;
  final String productId;
  final String productImage;

  LikedProduct({
    required this.categoryPath,
    required this.currency,
    required this.id,
    required this.isVisible,
    required this.likedAt,
    required this.name,
    required this.price,
    required this.productDescription,
    required this.productId,
    required this.productImage,
  });

  factory LikedProduct.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return LikedProduct(
      categoryPath: data['category_path'] ?? '',
      currency: data['currency'] ?? '',
      id: data['id'] ?? '',
      isVisible: data['is_visible'] ?? false,
      likedAt: data['liked_at'] != null 
          ? DateTime.parse(data['liked_at']) 
          : DateTime.now(),
      name: data['name'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      productDescription: data['product_description'] ?? '',
      productId: data['product_id'] ?? '',
      productImage: data['product_image'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'category_path': categoryPath,
      'currency': currency,
      'id': id,
      'is_visible': isVisible,
      'liked_at': likedAt.toIso8601String(),
      'name': name,
      'price': price,
      'product_description': productDescription,
      'product_id': productId,
      'product_image': productImage,
    };
  }
}