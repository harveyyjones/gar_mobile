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
  final String salerId;

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
    required this.salerId,
  });

  factory Product.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Product(
      id: doc.id,
      barcode: data['barcode'] ?? '',
      categoryPath: data['category_path'] ?? '',
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      images: List<String>.from(data['images'] ?? []),
      isVisible: data['is_visible'] is bool ? data['is_visible'] : (data['is_visible'] == 'true'),
      name: data['name'] ?? '',
      productDescription: data['product_description'] ?? '',
      updatedAt: (data['updated_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      currency: data['currency'] ?? '',
      price: (data['price'] ?? 0.0).toDouble(),
      salerId: data['seller_id'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'barcode': barcode,
      'category_path': categoryPath,
      'created_at': Timestamp.fromDate(createdAt),
      'images': images,
      'is_visible': isVisible,
      'name': name,
      'description': productDescription,
      'updated_at': Timestamp.fromDate(updatedAt),
      'currency': currency,
      'price': price,
      'seller_id': salerId,
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
    String? salerId,
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
      currency: currency ?? this.currency,
      price: price ?? this.price,
      salerId: salerId ?? this.salerId,
    );
  }
}