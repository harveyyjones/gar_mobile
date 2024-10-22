import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String barcode;
  final String categoryPath;
  final DateTime createdAt;
  final List<String> images;
  final bool isVisible;
  final String name;
  final String productDescription;
  final DateTime updatedAt;
  final String currency;
  final double price;

  Product({
    required this.categoryPath,
    required this.id,
    required this.barcode,
    required this.createdAt,
    required this.images,
    required this.isVisible,
    required this.name,
    required this.productDescription,
    required this.updatedAt,
    required this.currency,
    required this.price,
  });

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['product_id'] ?? '',
      barcode: map['barcode'] ?? '',
      categoryPath: map['category'] ?? '',
      createdAt: (map['created_at'] as Timestamp).toDate(),
      images: List<String>.from(map['images'] ?? []),
      isVisible: map['is_visible'] is bool ? map['is_visible'] : (map['is_visible'] == 'true'), // Ensure boolean type
      name: map['name'] ?? '',
      productDescription: map['description'] ?? '',
      updatedAt: (map['updated_at'] as Timestamp).toDate(),
      // New fields
      currency: map['currency'] ?? '', // Added currency mapping
      price: (map['price'] ?? 0.0).toDouble(), // Added price mapping
    );
  }

  factory Product.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Product(
      id: doc.id,
      barcode: data['barcode'] ?? '',
      categoryPath: data['category'] ?? '',
      createdAt: (data['created_at'] as Timestamp).toDate(),
      images: List<String>.from(data['images'] ?? []),
      isVisible: data['is_visible'] is bool ? data['is_visible'] : (data['is_visible'] == 'true'), // Ensure boolean type
      name: data['name'] ?? '',
      productDescription: data['description'] ?? '',
      updatedAt: (data['updated_at'] as Timestamp).toDate(),
      // New fields
      currency: data['currency'] ?? '', // Added currency mapping
      price: (data['price'] ?? 0.0).toDouble(), // Added price mapping
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'product_id': id,
      'barcode': barcode,
      'category': categoryPath,
      'created_at': createdAt.toIso8601String(),
      'images': images,
      'is_visible': isVisible,
      'name': name,
      'product_description': productDescription,
      'updated_at': updatedAt.toIso8601String(),
      // New fields
      'currency': currency,
      'price': price,
      'liked_at': DateTime.now().toIso8601String(), // Adding liked_at for liked items collection
    };
  }

  Product copyWith({
    String? id,
    String? barcode,
    String? categoryPath,
    DateTime? createdAt,
    List<String>? images,
    bool? isVisible,
    String? name,
    String? productDescription,
    DateTime? updatedAt,
    String? currency,
    double? price,
  }) {
    return Product(
      id: id ?? this.id,
      barcode: barcode ?? this.barcode,
      categoryPath: categoryPath ?? this.categoryPath,
      createdAt: createdAt ?? this.createdAt,
      images: images ?? this.images,
      isVisible: isVisible ?? this.isVisible,
      name: name ?? this.name,
      productDescription: productDescription ?? this.productDescription,
      updatedAt: updatedAt ?? this.updatedAt,
      // New fields
      currency: currency ?? this.currency,
      price: price ?? this.price,
    );
  }
}
