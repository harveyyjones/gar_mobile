import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shop_app/business%20logic/firebase_service.dart';
import 'package:shop_app/business%20logic/models/product_model.dart';
import 'package:shop_app/screens/Product%20Detail%20Screen/product_detail_screen.dart';
import 'package:shop_app/screens/details/components/expandable_about.dart';
import 'package:shop_app/screens/details/components/like_button.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

// Add this color palette at the top of your file
class AppColors {
  static const primary = Color(0xFF000000);
  static const secondary = Color(0xFF333333);
  static const accent = Color(0xFF0066FF);
  static const background = CupertinoColors.systemBackground;
  static const cardBackground = Color(0xFFFFFFFF);
  static const text = Color(0xFF000000);
  static const textLight = Color(0xFF666666);
  static const border = Color(0xFFEEEEEE);
}

class AppTypography {
  static final heading1 = GoogleFonts.poppins(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.text,
    decoration: TextDecoration.none,
  );

  static final heading2 = GoogleFonts.poppins(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.text,
    decoration: TextDecoration.none,
  );

  static final heading3 = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.text,
    decoration: TextDecoration.none,
  );

  static final body = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.text,
    decoration: TextDecoration.none,
  );

  static final bodyLight = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textLight,
    decoration: TextDecoration.none,
  );

  static final price = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.accent,
    decoration: TextDecoration.none,
  );

  static final caption = GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textLight,
    decoration: TextDecoration.none,
  );
}

class CategoryLevel {
  final String name;
  final int level;
  final String fullPath;

  CategoryLevel({
    required this.name,
    required this.level,
    required this.fullPath,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoryLevel &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          level == other.level;

  @override
  int get hashCode => name.hashCode ^ level.hashCode;
}

class WholesalerDetailScreen extends StatefulWidget {
  final Map<String, dynamic> wholesaler;
  WholesalerDetailScreen({required this.wholesaler});

  @override
  _WholesalerDetailScreenState createState() => _WholesalerDetailScreenState();
}

class _WholesalerDetailScreenState extends State<WholesalerDetailScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late Map<String, TextEditingController> quantityControllers;
  String? selectedCategory;
  Set<String> categories = {};

  @override
  void initState() {
    super.initState();
    quantityControllers = {};
  }

  @override
  void dispose() {
    quantityControllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  TextEditingController _getQuantityController(String productId) {
    if (!quantityControllers.containsKey(productId)) {
      quantityControllers[productId] = TextEditingController(text: '1');
    }
    return quantityControllers[productId]!;
  }

  // Extract the last category from path
  String _getLastCategory(String path) {
    if (path.isEmpty) return '';
    final parts = path.split('>');
    return parts.isNotEmpty ? parts.last.trim() : '';
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AppColors.background.withOpacity(0.9),
        border: null,
        middle: Text(
          widget.wholesaler['company_name'] ?? 'Wholesaler',
          style: AppTypography.heading2,
        ),
      ),
      child: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: _buildWholesalerInfo(),
            ),
            _buildProductsGrid(),
            const SliverPadding(
              padding: EdgeInsets.only(bottom: 20),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWholesalerInfo() {
    return FutureBuilder(
      future: _firebaseService.fetchWholesalerById(widget.wholesaler['seller_id']),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CupertinoActivityIndicator(),
            ),
          );
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: GoogleFonts.poppins(color: CupertinoColors.destructiveRed),
            ),
          );
        }
        
        final wholesalerData = snapshot.data;
        return Column(
          children: [
            ExpandableWholesalerInfo(wholesalerData: wholesalerData! ),
          ],
        );
      },
    );
  }

  Widget _buildProductsGrid() {
    return SliverToBoxAdapter(
      child: FutureBuilder<List<Product>>(
        future: _firebaseService.fetchAllProductsWithSalerId(
          widget.wholesaler['seller_id'],
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CupertinoActivityIndicator(),
              ),
            );
          }
          
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Error loading products: ${snapshot.error}',
                  style: AppTypography.body.copyWith(
                    color: CupertinoColors.destructiveRed,
                  ),
                ),
              ),
            );
          }

          final products = snapshot.data ?? [];

          // Extract only the last category from each product's path
          categories = products.fold<Set<String>>({}, (set, product) {
            final lastCategory = _getLastCategory(product.categoryPath);
            if (lastCategory.isNotEmpty) {
              set.add(lastCategory);
            }
            return set;
          });

          // Filter products based on the last category
          final filteredProducts = selectedCategory == null
              ? products
              : products.where((product) => 
                  _getLastCategory(product.categoryPath) == selectedCategory)
                  .toList();

          return Column(
            children: [
              // Categories list
              if (categories.isNotEmpty) ...[
                Container(
                  height: 50,
                  margin: const EdgeInsets.symmetric(vertical: 16),
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      // "All" category
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: CupertinoButton(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          color: selectedCategory == null
                              ? AppColors.accent
                              : AppColors.accent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(25),
                          onPressed: () {
                            setState(() => selectedCategory = null);
                          },
                          child: Text(
                            'All',
                            style: AppTypography.body.copyWith(
                              color: selectedCategory == null
                                  ? Colors.white
                                  : AppColors.accent,
                              fontWeight: selectedCategory == null
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                      // Add this part to create category buttons
                      ...categories.map((category) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: CupertinoButton(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          color: selectedCategory == category
                              ? AppColors.accent
                              : AppColors.accent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(25),
                          onPressed: () {
                            setState(() => selectedCategory = category);
                          },
                          child: Text(
                            category,
                            style: AppTypography.body.copyWith(
                              color: selectedCategory == category
                                  ? Colors.white
                                  : AppColors.accent,
                              fontWeight: selectedCategory == category
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      )).toList(),
                    ],
                  ),
                ),
              ],
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Category path and product count
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (selectedCategory != null)
                            Text(
                              'Category: ${selectedCategory!}',
                              style: AppTypography.bodyLight,
                            ),
                          SizedBox(height: 4),
                          Text(
                            '${filteredProducts.length} Products',
                            style: AppTypography.bodyLight,
                          ),
                        ],
                      ),
                    ),
                    // Grid
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.75,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                      ),
                      itemCount: filteredProducts.length,
                      itemBuilder: (context, index) {
                        return _buildProductItem(filteredProducts[index], context);
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProductItem(Product product, BuildContext context) {
    final quantityController = _getQuantityController(product.id);
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          CupertinoPageRoute(
            builder: (context) => ProductDetailScreen(product: product),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.text.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  // Product Image
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      image: DecorationImage(
                        image: NetworkImage(product.images.first),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  // Like Button with Background
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: LikeButton(
                        productId: product.id,
                        productDetails: {
                          "product_image": product.images.first,
                          "product_id": product.id,
                          "category_path": product.categoryPath,
                          "liked_at": product.createdAt.toIso8601String(),
                          "is_visible": product.isVisible,
                          "name": product.name,
                          "product_description": product.productDescription,
                          "currency": product.currency,
                          "price": product.price,
                          "saler_id": product.salerId, // Make sure this is included
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name ?? '',
                    style: AppTypography.heading3,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${product.price.toInt()} ${product.currency}",
                    style: AppTypography.price,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Optional: Add this method to handle scroll to top more smoothly
  Future<void> _handleRefresh() async {
    // Add your refresh logic here
    setState(() {});
    await Future.delayed(const Duration(seconds: 1));
  }
}
