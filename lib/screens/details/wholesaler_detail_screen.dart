import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shop_app/business%20logic/firebase_service.dart';
import 'package:shop_app/business%20logic/models/product_model.dart';
import 'package:shop_app/screens/Product%20Detail%20Screen/product_detail_screen.dart';
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
            // Add some bottom padding
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
      future: _firebaseService.fetchWholesalerById(widget.wholesaler['saler_id']),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
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
        return Container(
          color: AppColors.background,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  image: DecorationImage(
                    image: NetworkImage(wholesalerData!.logo),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'About',
                      style: AppTypography.heading2,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      wholesalerData.description,
                      style: AppTypography.bodyLight,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            CupertinoIcons.location_solid,
                            color: AppColors.accent,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              wholesalerData.address,
                              style: AppTypography.body,
                            ),
                          ),


                          Text(
                            wholesalerData.zip,
                            style: AppTypography.bodyLight,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            wholesalerData.country,
                            style: AppTypography.bodyLight,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Products',
                  style: AppTypography.heading2,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProductsGrid() {
    return SliverToBoxAdapter(
      child: FutureBuilder<List<Product>>(
        future: _firebaseService.fetchAllProductsWithSalerId(
          widget.wholesaler['saler_id'],
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
                  'Error loading products',
                  style: AppTypography.body.copyWith(
                    color: CupertinoColors.destructiveRed,
                  ),
                ),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'No products available',
                  style: AppTypography.bodyLight,
                ),
              ),
            );
          }

          final products = snapshot.data!;
          
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
              ),
              itemCount: products.length,
              itemBuilder: (context, index) {
                return _buildProductItem(products[index], context);
              },
            ),
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
                  Positioned(
                    top: 8,
                    right: 8,
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
                      },
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
