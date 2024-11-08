import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shop_app/business%20logic/firebase_service.dart';
import 'package:shop_app/business%20logic/models/wholesaler_model.dart';
import 'package:shop_app/business_logic_rest_api/Services/product_service.dart';
import 'package:shop_app/business_logic_rest_api/models/product.dart';
import 'package:shop_app/screens/Product%20Detail%20Screen/product_detail_screen.dart';
import 'package:shop_app/screens/details/components/expandable_about.dart';
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
  final ProductServiceRestApi _productService = ProductServiceRestApi();
  final FirebaseService _firebaseService = FirebaseService();
  String? selectedCategory;
  Set<String> categories = {};
  bool _isLoading = true;
  List<ProductRestApi> _products = [];
  String? _error;

  static const int _pageSize = 6;
  bool _isLoadingMore = false;
  int _currentPage = 0;
  List<ProductRestApi> _displayedProducts = [];

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(_onScroll);
    _loadInitialProducts();
  }

  @override
  void dispose() {
    ImageCacheManager.clearMemory();
    _scrollController.dispose();
    super.dispose();
  }

  void _loadInitialProducts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final products = await _productService.fetchProducts();
      if (mounted) {
        setState(() {
          _products = products;
          categories = _getCategoriesWithStock();
          _loadNextPage();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _loadNextPage() {
    if (_isLoadingMore || _products.isEmpty) return;

    final filteredProducts = _getFilteredProducts();
    final startIndex = _currentPage * _pageSize;
    if (startIndex >= filteredProducts.length) return;

    final endIndex = (startIndex + _pageSize <= filteredProducts.length)
        ? startIndex + _pageSize
        : filteredProducts.length;

    setState(() {
      _displayedProducts.addAll(filteredProducts.sublist(startIndex, endIndex));
      _currentPage++;
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 500) {
      _loadNextPage();
    }
  }

  void _resetPagination() {
    setState(() {
      _currentPage = 0;
      _displayedProducts.clear();
      _loadNextPage();
    });
  }

  List<ProductRestApi> _getFilteredProducts() {
    final inStockProducts =
        _products.where((product) => product.stock > 0).toList();

    if (selectedCategory == null) {
      return inStockProducts;
    }

    return inStockProducts
        .where((product) =>
            product.categoryName.toLowerCase() ==
            selectedCategory?.toLowerCase())
        .toList();
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
        leading: CupertinoNavigationBarBackButton(
          color: AppColors.text,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      child: SafeArea(
        child: _isLoading
            ? const Center(child: CupertinoActivityIndicator())
            : _error != null
                ? _buildErrorWidget()
                : _products.isEmpty
                    ? const Center(child: Text('No products available'))
                    : CustomScrollView(
                        controller: _scrollController,
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
      future:
          _firebaseService.fetchWholesalerById(widget.wholesaler['seller_id']),
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
            ExpandableWholesalerInfo(
                wholesalerData: wholesalerData as WholesalerModel),
          ],
        );
      },
    );
  }

  Widget _buildProductsGrid() {
    final filteredProducts = _getFilteredProducts();
    final displayCount = _displayedProducts.length;

    if (selectedCategory != null && filteredProducts.isEmpty) {
      return SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.cube_box,
                    size: 48, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No products available in this category',
                  style: AppTypography.bodyLight,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                CupertinoButton(
                  child: const Text('Show all products'),
                  onPressed: () => _handleCategoryChange(null),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildListDelegate([
        _buildCategoryFilters(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProductCount(filteredProducts.length),
              LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;
                  final aspectRatio = constraints.maxWidth > 600 ? 0.7 : 0.6;

                  return MediaQuery.removePadding(
                    context: context,
                    removeTop: true,
                    child: GridView.builder(
                      key: const PageStorageKey('products_grid'),
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: aspectRatio,
                      ),
                      itemCount: displayCount + (_isLoadingMore ? 2 : 0),
                      itemBuilder: (context, index) {
                        if (index >= displayCount) {
                          return const Center(
                            child: CupertinoActivityIndicator(),
                          );
                        }

                        return ProductCard(
                          product: _displayedProducts[index],
                          onTap: () => _navigateToProductDetail(
                            context,
                            _displayedProducts[index],
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ]),
    );
  }

  void _navigateToProductDetail(BuildContext context, ProductRestApi product) {
    Navigator.push(
      context,
      CupertinoPageRoute(builder: (context) {
        // TODO: add product detail screen here.
        // ProductDetailScreen(product: product),
        return Container();
      }),
    );
  }

// Add this to your ScrollController initialization
  final ScrollController _scrollController = ScrollController();

// Add scroll to top functionality
  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

// Memory management helper

  Widget _buildCategoryFilters() {
    if (categories.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildCategoryButton(null, 'All'),
          ...categories
              .map((category) => _buildCategoryButton(category, category)),
        ],
      ),
    );
  }

  Widget _buildCategoryButton(String? category, String label) {
    final isSelected = selectedCategory == category;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: CupertinoButton(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        color:
            isSelected ? AppColors.accent : AppColors.accent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(25),
        onPressed: () => _handleCategoryChange(category),
        child: Text(
          label,
          style: AppTypography.body.copyWith(
            color: isSelected ? Colors.white : AppColors.accent,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  void _handleCategoryChange(String? newCategory) {
    setState(() {
      selectedCategory = newCategory;
      _currentPage = 0;
      _displayedProducts.clear();
      _loadFilteredPage();
    });
  }

  void _loadFilteredPage() {
    if (_isLoadingMore || _products.isEmpty) return;

    final filteredProducts = _getFilteredProducts();
    final startIndex = _currentPage * _pageSize;

    if (startIndex >= filteredProducts.length) return;

    final endIndex = (startIndex + _pageSize <= filteredProducts.length)
        ? startIndex + _pageSize
        : filteredProducts.length;

    setState(() {
      _displayedProducts.addAll(filteredProducts.sublist(startIndex, endIndex));
      _currentPage++;
    });
  }

  Widget _buildProductCount(int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (selectedCategory != null)
            Text(
              'Category: ${selectedCategory!}',
              style: AppTypography.bodyLight,
            ),
          const SizedBox(height: 4),
          Text(
            '${count} Products',
            style: AppTypography.bodyLight,
          ),
        ],
      ),
    );
  }

  Widget _buildProductItem(ProductRestApi product, BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          CupertinoPageRoute(
            builder: (context) {
              // TODO: add product detail screen here.
              return ProductDetailScreen(product: product);
            },
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
                        image: CachedNetworkImageProvider(
                            cacheManager:
                                CachedNetworkImageProvider.defaultCacheManager,
                            maxHeight: 100,
                            maxWidth: 100,
                            product.imageUrl),
                        fit: BoxFit.cover,
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
                    product.name,
                    style: AppTypography.heading3,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  if (product.description != null) ...[
                    Text(
                      product.description!,
                      style: AppTypography.bodyLight,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                  ],

                  // Updated price display
                  Row(
                    children: [
                      if (product.salePrice < product.price) ...[
                        Text(
                          "${product.price.toStringAsFixed(2)} PLN",
                          style: AppTypography.bodyLight.copyWith(
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        "${product.salePrice.toStringAsFixed(2)} PLN",
                        style: AppTypography.price.copyWith(
                          color: product.salePrice < product.price
                              ? Colors.red
                              : AppColors.accent,
                        ),
                      ),
                    ],
                  ),

                  Text(
                    "In Stock: ${product.stock}",
                    style: AppTypography.caption.copyWith(
                      color: product.stock > 10 ? Colors.green : Colors.orange,
                    ),
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

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Error: $_error'),
          CupertinoButton(
            onPressed: _loadInitialProducts,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  // Add this helper method to get categories with in-stock products
  Set<String> _getCategoriesWithStock() {
    return _products
        .where((product) => product.stock > 0)
        .map((product) => product.categoryName)
        .where((name) => name.isNotEmpty)
        .toSet();
  }
}

class ProductCard extends StatelessWidget {
  final ProductRestApi product;
  final VoidCallback? onTap;

  const ProductCard({
    Key? key,
    required this.product,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 4,
                  child: ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(12)),
                    child: Image.network(
                      product.imageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: EdgeInsets.all(constraints.maxWidth * 0.04),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          height: constraints.maxWidth * 0.2,
                          child: Text(
                            product.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.heading3.copyWith(
                              fontSize: constraints.maxWidth * 0.07,
                            ),
                          ),
                        ),
                        _buildPriceSection(constraints),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPriceSection(BoxConstraints constraints) {
    final isOnSale = product.salePrice < product.price;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isOnSale)
          Text(
            "${product.price.toStringAsFixed(2)} PLN",
            style: AppTypography.bodyLight.copyWith(
              decoration: TextDecoration.lineThrough,
              fontSize: constraints.maxWidth * 0.06,
            ),
          ),
        Text(
          "${product.salePrice.toStringAsFixed(2)} PLN",
          style: AppTypography.price.copyWith(
            color: isOnSale ? Colors.red : AppColors.accent,
            fontSize: constraints.maxWidth * 0.07,
          ),
        ),
      ],
    );
  }
}

class ImageCacheManager {
  static void init() {
    // Set very conservative cache limits
    PaintingBinding.instance.imageCache.maximumSize = 50; // Number of images
    PaintingBinding.instance.imageCache.maximumSizeBytes = 20 << 20; // 20 MB
  }

  static void clearCache() {
    imageCache.clear();
    imageCache.clearLiveImages();
    PaintingBinding.instance.imageCache.clear();
  }

  static void clearMemory() {
    imageCache.clear();
    imageCache.clearLiveImages();
  }
}
