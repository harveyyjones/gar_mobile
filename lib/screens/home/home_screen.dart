import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shop_app/business%20logic/firebase_service.dart';
import 'package:shop_app/business%20logic/models/product_model.dart';
import 'package:shop_app/screens/cart%20screen/cart_screen.dart';
import 'package:shop_app/screens/details/wholesaler_detail_screen.dart';
import 'package:shop_app/screens/liked%20items%20screen/liked_items_screen.dart';
import 'package:google_fonts/google_fonts.dart'; // Import Google Fonts
import 'package:cached_network_image/cached_network_image.dart'; // Added Cached Network Image import
import 'package:shop_app/constants.dart'; // Added constants import

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

  static final caption = GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textLight,
    decoration: TextDecoration.none,
  );
}

class HomePage extends StatelessWidget {
  final FirebaseService _firebaseService = FirebaseService();
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: CupertinoPageScaffold(
        backgroundColor: CupertinoColors.systemBackground,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            SliverPersistentHeader(
              floating: true,
              delegate: _ModernHeaderDelegate( // New header delegate
                onCartTap: () {
                  // TODO: Navigate to cart screen
                  Navigator.push(
                    context,
                    CupertinoPageRoute(builder: (context) => CartScreen()),
                  );
                },
                onLikedTap: () {
                  Navigator.push(
                    context,
                    CupertinoPageRoute(builder: (context) => LikedProductsWidget()),
                  );
                },
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.only(top: 8),
              sliver: SliverToBoxAdapter(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _firebaseService.fetchWholesalers(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CupertinoActivityIndicator(radius: 14),
                      );
                    } else if (snapshot.hasError) {
                      return _buildErrorWidget(snapshot.error.toString());
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return _buildEmptyStateWidget();
                    } else {
                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: snapshot.data!.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 1),
                        itemBuilder: (context, index) => _buildWholesalerItem(
                          context,
                          snapshot.data![index],
                        ),
                      );
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String error) { // New method for error widget
    return Center(child: Text('Error: $error'));
  }

  Widget _buildEmptyStateWidget() { // New method for empty state widget
    return const Center(child: Text('No wholesalers found'));
  }

  Widget _buildWholesalerList(BuildContext context, List<Map<String, dynamic>> wholesalers) {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: wholesalers.length,
      itemBuilder: (context, index) {
        final wholesaler = wholesalers[index];
        return _buildWholesalerItem(context, wholesaler);
      },
    );
  }

  Widget _buildWholesalerItem(BuildContext context, Map<String, dynamic> wholesaler) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildOptimizedImage(wholesaler['logo']),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        wholesaler['company_name'] ?? 'Unknown',
                        style: AppTypography.heading3,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FutureBuilder<List<Product>>(
            future: _firebaseService.fetchAllProductsWithSalerId(wholesaler['saler_id']),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CupertinoActivityIndicator());
              } else if (snapshot.hasError) {
                return const Text('Error loading products');
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Text('No products available');
              } else {
                return SizedBox(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      final product = snapshot.data![index];
                      return _buildProductItem(product, context);
                    },
                  ),
                );
              }
            },
          ),
          const SizedBox(height: 8), // Added spacing before address
          // New container for address, zip, and country
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(
                  CupertinoIcons.location_solid,
                  color: AppColors.accent,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    wholesaler['adress'] ?? 'No address', // Use wholesaler address
                    style: AppTypography.body,
                  ),
                ),
                Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const SizedBox(),
              CupertinoButton(
                
                padding: EdgeInsets.zero,
                minSize: 0,
                child: Text('View Details', style: GoogleFonts.poppins( // Updated to use Poppins
                  fontSize: 16, // Font size
                  fontWeight: FontWeight.bold, // Set to bold for a modern look
                  color: Colors.black, // Set text color to black
                  decoration: TextDecoration.underline, // Add underline
                )),
                onPressed: () {
                  Navigator.push(context, CupertinoPageRoute(builder: (context) => WholesalerDetailScreen(wholesaler: wholesaler))); // Changed to CupertinoPageRoute
                },
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.06, width: MediaQuery.of(context).size.width * 0.06,)
            ],
          ),
              ],
            ),
          ),
         
        ],
      ),
    );
  }

  Widget _buildOptimizedImage(String? imageUrl, {double? width, double? height}) { // New method for optimized image loading
    return Container(
      width: width ?? 60,
      height: height ?? 60,
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: imageUrl != null && imageUrl.isNotEmpty
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                cacheWidth: (width ?? 60 * 2).toInt(), // 2x for high DPI displays
                cacheHeight: (height ?? 60 * 2).toInt(),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(
                    child: CupertinoActivityIndicator(
                      radius: 10,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) => const Icon(
                  CupertinoIcons.photo,
                  size: 30,
                  color: CupertinoColors.systemGrey,
                ),
              )
            : const Icon(
                CupertinoIcons.photo,
                size: 30,
                color: CupertinoColors.systemGrey,
              ),
      ),
    );
  }

  Widget _buildProductItem(Product product, BuildContext context) { // Updated to use _buildOptimizedImage
    return Container(
      width: MediaQuery.of(context).size.width * 0.9,
      margin: const EdgeInsets.only(right: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: product.images.map((image) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _buildOptimizedImage( // Updated to use optimized image method
                      image,
                      width: 100,
                      height: 100,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductImage(String imageUrl) { // Updated method for product image
    return Container(
      width: 100,
      height: 100,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [ // Added shadow for elevation effect
          BoxShadow(
            color: CupertinoColors.systemGrey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CachedNetworkImage( // Updated to use CachedNetworkImage
          imageUrl: imageUrl,
          fit: BoxFit.cover,
          placeholder: (context, url) => const Center(
            child: CupertinoActivityIndicator(radius: 10),
          ),
          errorWidget: (context, url, error) => const Icon(
            CupertinoIcons.photo,
            size: 30,
            color: CupertinoColors.systemGrey,
          ),
        ),
      ),
    );
  }
}

class _ModernHeaderDelegate extends SliverPersistentHeaderDelegate { // New class for header
  final VoidCallback onCartTap;
  final VoidCallback onLikedTap;

  _ModernHeaderDelegate({
    required this.onCartTap,
    required this.onLikedTap,
  });

  @override
  double get maxExtent => 100; // Set max extent

  @override
  double get minExtent => 100; // Set min extent

  @override
  bool shouldRebuild(SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final progress = shrinkOffset / maxExtent;
    return Container(
      color: CupertinoColors.systemBackground.withOpacity(0.8), // Added background with opacity
      child: ClipRRect(
        child: BackdropFilter( // Added blur effect
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: SafeArea(
            bottom: false,
            child: Container(
              height: maxExtent,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Logo or Title
                  Text(
                    'Witaj!',
                    style: GoogleFonts.poppins(
                      fontSize: 24 - (4 * progress),
                      fontWeight: FontWeight.w600,
                      color: CupertinoColors.label,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  // Action Buttons
                  Row(
                    children: [
                      _buildIconButton(
                        onTap: onCartTap,
                        icon: CupertinoIcons.cart,
                        badgeCount: 0, // Replace with actual cart count
                      ),
                      const SizedBox(width: 8),
                      _buildIconButton(
                        onTap: onLikedTap,
                        icon: CupertinoIcons.heart,
                        badgeCount: null,
                        iconColor: CupertinoColors.systemPink,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// New method for building icon buttons
Widget _buildIconButton({
  required VoidCallback onTap,
  required IconData icon,
  int? badgeCount,
  Color? iconColor,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Stack(
      alignment: Alignment.center,
      children: [
        Icon(icon, color: iconColor ?? CupertinoColors.label),
        if (badgeCount != null && badgeCount > 0)
          Positioned(
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: CupertinoColors.systemRed,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                '$badgeCount',
                style: const TextStyle(
                  color: CupertinoColors.white,
                  fontSize: 12,
                ),
              ),
            ),
          ),
      ],
    ),
  );
}