import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shop_app/business%20logic/firebase_service.dart';
import 'package:shop_app/business%20logic/models/product_model.dart';
import 'package:shop_app/business%20logic/models/wholesaler_model.dart';
import 'package:shop_app/screens/Product%20Detail%20Screen/product_detail_screen.dart';
import 'package:shop_app/screens/cart%20screen/cart_screen.dart';
import 'package:shop_app/screens/details/components/like_button.dart';
import 'package:shop_app/screens/details/wholesaler_detail_screen.dart';
import 'package:shop_app/screens/liked%20items%20screen/liked_items_screen.dart';
import 'package:google_fonts/google_fonts.dart'; // Import Google Fonts
import 'package:cached_network_image/cached_network_image.dart'; // Added Cached Network Image import
import 'package:shop_app/constants.dart';
import 'package:shop_app/screens/previous%20orders%20of%20the%20user/order_history_screen.dart';
import 'package:shop_app/screens/settings_screen.dart'; // Added constants import
import 'package:firebase_auth/firebase_auth.dart'; // Added Firebase Auth import

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

class HomePage extends StatefulWidget { // Changed from StatelessWidget to StatefulWidget
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> { // New state class for HomePage
  final FirebaseService _firebaseService = FirebaseService();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Debug print all sellers when page loads
    _firebaseService.debugPrintAllSellers();
  }

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
            // Your existing header
            SliverPersistentHeader(
              floating: true,
              delegate: _ModernHeaderDelegate(
                onCartTap: () => Navigator.push(
                  context,
                  CupertinoPageRoute(builder: (context) => CartScreen()),
                ),
                onLikedTap: () => Navigator.push(
                  context,
                  CupertinoPageRoute(builder: (context) => LikedProductsWidget()),
                ),
              ),
            ),
            
            // Updated StreamBuilder to use WholesalerModel
            SliverPadding(
              padding: const EdgeInsets.only(top: 8),
              sliver: SliverToBoxAdapter(
                child: StreamBuilder<List<WholesalerModel>>(  // Changed type from List<Map<String, dynamic>>
                  stream: _firebaseService.wholesalersStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Container(
                        height: 200,
                        alignment: Alignment.center,
                        child: const CupertinoActivityIndicator(radius: 14),
                      );
                    }

                    if (snapshot.hasError) {
                      print('Stream error: ${snapshot.error}');
                      return _buildErrorWidget(snapshot.error.toString());
                    }

                    final wholesalers = snapshot.data ?? [];

                    if (wholesalers.isEmpty) {
                      return _buildEmptyState();
                    }

                    return CupertinoScrollbar(
                      child: RefreshIndicator(
                        onRefresh: () async {
                          setState(() {}); // Force rebuild
                        },
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: wholesalers.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            final wholesaler = wholesalers[index];
                            return _buildWholesalerItem(context, wholesaler);  // Pass WholesalerModel directly
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 200,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.shopping_cart,
            size: 48,
            color: CupertinoColors.systemGrey,
          ),
          const SizedBox(height: 16),
          Text(
            'No Wholesalers Available',
            style: AppTypography.heading3,
          ),
          const SizedBox(height: 8),
          CupertinoButton(
            child: Text('Refresh'),
            onPressed: () {
              _firebaseService.debugPrintAllSellers();
              setState(() {}); // Force rebuild
            },
          ),
        ],
      ),
    );
  }

  // Updated error widget
  Widget _buildErrorWidget(String error) {
    return Container(
      height: 200,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.exclamationmark_circle,
            size: 48,
            color: CupertinoColors.systemRed,
          ),
          const SizedBox(height: 16),
          Text(
            'Error Loading Wholesalers',
            style: AppTypography.heading3,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              error,
              style: AppTypography.bodyLight,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWholesalerList(BuildContext context, List<Map<String, dynamic>> wholesalers) {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: wholesalers.length,
      itemBuilder: (context, index) {
        final wholesalerMap = wholesalers[index];
        final wholesaler = WholesalerModel.fromFirestore(wholesalerMap, wholesalerMap['id']);
        return _buildWholesalerItem(context, wholesaler);
      },
    );
  }

  // Updated wholesaler item builder
  Widget _buildWholesalerItem(BuildContext context, WholesalerModel wholesaler) {
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
                _buildOptimizedImage(wholesaler.logoUrl),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                       wholesaler.name ?? "unknown",
                        style: AppTypography.heading3,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      // Added phone display
                      if (wholesaler.phone.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          wholesaler.phone,
                          style: AppTypography.bodyLight,
                        ),
                      ],
                      // Added email display
                      if (wholesaler.email.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          wholesaler.email,
                          style: AppTypography.bodyLight,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (wholesaler.sellerId.isNotEmpty) ...[ // Changed condition
            const SizedBox(height: 16),
            FutureBuilder<List<Product>>(
              future: _firebaseService.fetchAllProductsWithSalerId(wholesaler.sellerId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CupertinoActivityIndicator(),
                    ),
                  );
                }
                
                if (snapshot.hasError) {
                  print('Error loading products: ${snapshot.error}');
                  return const SizedBox.shrink();
                }
                
                final products = snapshot.data ?? [];
                if (products.isEmpty) {
                  return const SizedBox.shrink();
                }
                
                return SizedBox(
                  height: 120, // Increased height to accommodate product info
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: products.length,
                    itemBuilder: (context, index) => _buildProductItem(
                      products[index],
                      context,
                    ),
                  ),
                );
              },
            ),
          ],
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      CupertinoIcons.location_solid,
                      color: AppColors.accent,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _formatAddress(wholesaler.address),
                        style: AppTypography.body,
                      ),
                    ),
                  ],
                ),
                if (_isOpenNow(wholesaler.workingHours)) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Open Now',
                        style: AppTypography.bodyLight.copyWith(
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      minSize: 0,
                      child: Text(
                        'View Details',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          CupertinoPageRoute(
                            builder: (context) => WholesalerDetailScreen(
                              wholesaler: wholesaler.toFirestore(),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // New method for company logo, full address, and open status
  Widget _buildCompanyLogo(WholesalerModel wholesaler) {
    String? logoUrl = wholesaler.logoUrl;
    return _buildOptimizedImage(
      logoUrl,
      width: 80,
      height: 80,
    );
  }

  String _formatAddress(AddressDetails address) {
    final parts = [
      if (address.addressOfCompany.isNotEmpty) address.addressOfCompany,
      if (address.city.isNotEmpty) address.city,
      if (address.country.isNotEmpty) address.country,
    ];
    return parts.isNotEmpty ? parts.join(', ') : 'No address available';
  }

  bool _isOpenNow(WorkingHours workingHours) {
    final now = DateTime.now();
    final currentDay = now.weekday;
    
    DayHours? dayHours;
    switch (currentDay) {
      case DateTime.monday:
        dayHours = workingHours.monday;
        break;
      case DateTime.tuesday:
        dayHours = workingHours.tuesday;
        break;
      case DateTime.wednesday:
        dayHours = workingHours.wednesday;
        break;
      case DateTime.thursday:
        dayHours = workingHours.thursday;
        break;
      case DateTime.friday:
        dayHours = workingHours.friday;
        break;
      case DateTime.saturday:
        dayHours = workingHours.saturday;
        break;
      case DateTime.sunday:
        dayHours = workingHours.sunday;
        break;
    }

    if (dayHours == null || dayHours.open.isEmpty || dayHours.close.isEmpty) {
      return false;
    }

    try {
      final openTime = _parseTimeString(dayHours!.open);
      final closeTime = _parseTimeString(dayHours.close);
      final currentTime = DateTime(now.year, now.month, now.day, now.hour, now.minute);

      return currentTime.isAfter(openTime) && currentTime.isBefore(closeTime);
    } catch (e) {
      return false;
    }
  }

  DateTime _parseTimeString(String timeString) {
    final parts = timeString.split(':');
    final now = DateTime.now();
    return DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
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

Widget _buildProductItem(Product product, BuildContext context) {
  final double itemSize = MediaQuery.of(context).size.width * 0.25; // 25% of screen width
  
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
      width: itemSize,
      height: itemSize,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.text.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              product.images.isNotEmpty ? product.images.first : 'placeholder_url',
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const Center(
                  child: CupertinoActivityIndicator(),
                );
              },
              errorBuilder: (context, error, stackTrace) => const Icon(
                CupertinoIcons.photo,
                color: AppColors.textLight,
              ),
            ),
          ),
          
          // Optional: Like button overlay
          Positioned(
            top: 4,
            right: 4,
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
                  "saler_id": product.salerId,
                },
              ),
            ),
          ),
        ],
      ),
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
                      const SizedBox(width: 12),
                      _buildIconButton(
                        onTap: onLikedTap,
                        icon: CupertinoIcons.heart,
                        badgeCount: null,
                        iconColor: CupertinoColors.systemPink,
                      ),
                         const SizedBox(width: 12),
                      _buildIconButton(
                        onTap: () {
                          Navigator.push(context, CupertinoPageRoute(builder: (context) => OrderHistoryScreen()));
                        },
                        icon: CupertinoIcons.time,
                        badgeCount: null,
                        iconColor: const Color.fromARGB(255, 0, 0, 0),
                      ),
                        const SizedBox(width: 12),

                      _buildIconButton(
                        onTap: () {
                          Navigator.push(context, CupertinoPageRoute(builder: (context) => 
                           SettingsScreen()));
                        },
                        icon: CupertinoIcons.settings,
                        badgeCount: null,
                        iconColor: const Color.fromARGB(255, 0, 0, 0),
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

