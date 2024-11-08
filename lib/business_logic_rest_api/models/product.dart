class ProductRestApi {
  final int id;
  final String barcode;
  final int categoryId;
  final String sku;
  final String name;
  final String? ml;
  final String? description;
  final double price;
  final double salePrice;
  final int stockState;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String isWeb;
  final String isDealer;
  final String isStore;
  final String? baselinkerId;
  final String baselinkerStatus;
  final String baselinkerStatusJob;
  final DateTime? deletedAt;
  final dynamic order; // Changed to dynamic as it can be int or String
  final int isNew;
  final String? wordpressSalePriceLoris;
  final String? wordpressStatusLoris;
  final String? wordpressSalePriceZapach;
  final String? wordpressStatusZapach;
  final String isBestSeller;
  final String isBest;
  final String isPromotion;
  final String slug;
  final String webLimit;
  final String baselinkerLimit;
  final String storeLimit;
  final String toptanLimit;
  final String baselinkerStockJob;
  final String categoryName;
  final String imageUrl;
  final int stockUser;
  final String magazaPrice;
  final String image;
  final int stock;
  final int musteriPrice;
  final CategoryOfRestApi category;

  ProductRestApi({
    required this.id,
    required this.barcode,
    required this.categoryId,
    required this.sku,
    required this.name,
    this.ml,
    this.description,
    required this.price,
    required this.salePrice,
    required this.stockState,
    required this.createdAt,
    required this.updatedAt,
    required this.isWeb,
    required this.isDealer,
    required this.isStore,
    this.baselinkerId,
    required this.baselinkerStatus,
    required this.baselinkerStatusJob,
    this.deletedAt,
    this.order,
    required this.isNew,
    this.wordpressSalePriceLoris,
    this.wordpressStatusLoris,
    this.wordpressSalePriceZapach,
    this.wordpressStatusZapach,
    required this.isBestSeller,
    required this.isBest,
    required this.isPromotion,
    required this.slug,
    required this.webLimit,
    required this.baselinkerLimit,
    required this.storeLimit,
    required this.toptanLimit,
    required this.baselinkerStockJob,
    required this.categoryName,
    required this.imageUrl,
    required this.stockUser,
    required this.magazaPrice,
    required this.image,
    required this.stock,
    required this.musteriPrice,
    required this.category,
  });

  factory ProductRestApi.fromJson(Map<String, dynamic> json) {
    try {
      print('Parsing product JSON: ${json['id']}'); // Debug log

      // Helper function to safely convert numeric values
      num? safeParseNum(dynamic value) {
        if (value == null) return null;
        if (value is num) return value;
        if (value is String) {
          try {
            return num.parse(value);
          } catch (e) {
            print('Failed to parse numeric value: $value');
            return null;
          }
        }
        return null;
      }

      // Helper function to safely parse integers
      int safeParseInt(dynamic value, {int defaultValue = 0}) {
        if (value == null) return defaultValue;
        if (value is int) return value;
        if (value is String) {
          try {
            return int.parse(value);
          } catch (e) {
            print('Failed to parse int value: $value');
            return defaultValue;
          }
        }
        return defaultValue;
      }

      return ProductRestApi(
        id: safeParseInt(json['id']),
        barcode: json['barcode']?.toString() ?? '',
        categoryId: safeParseInt(json['category_id']),
        sku: json['sku']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        ml: json['ml']?.toString(),
        description: json['description']?.toString(),
        price: safeParseNum(json['price'])?.toDouble() ?? 0.0,
        salePrice: safeParseNum(json['sale_price'])?.toDouble() ?? 0.0,
        stockState: safeParseInt(json['stock_state']),
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
        isWeb: json['is_web']?.toString() ?? '',
        isDealer: json['is_dealer']?.toString() ?? '',
        isStore: json['is_store']?.toString() ?? '',
        baselinkerId: json['baselinker_id']?.toString(),
        baselinkerStatus: json['baselinker_status']?.toString() ?? '',
        baselinkerStatusJob: json['baselinker_status_job']?.toString() ?? '',
        deletedAt: json['deleted_at'] != null
            ? DateTime.parse(json['deleted_at'] as String)
            : null,
        order: json['order'], // Keep as dynamic
        isNew: safeParseInt(json['is_new']),
        wordpressSalePriceLoris: json['wordpress_sale_price_loris']?.toString(),
        wordpressStatusLoris: json['wordpress_status_loris']?.toString(),
        wordpressSalePriceZapach:
            json['wordpress_sale_price_zapach']?.toString(),
        wordpressStatusZapach: json['wordpress_status_zapach']?.toString(),
        isBestSeller: json['is_best_seller']?.toString() ?? '',
        isBest: json['is_best']?.toString() ?? '',
        isPromotion: json['is_promotion']?.toString() ?? '',
        slug: json['slug']?.toString() ?? '',
        webLimit: json['web_limit']?.toString() ?? '',
        baselinkerLimit: json['baselinker_limit']?.toString() ?? '',
        storeLimit: json['store_limit']?.toString() ?? '',
        toptanLimit: json['toptan_limit']?.toString() ?? '',
        baselinkerStockJob: json['baselinker_stock_job']?.toString() ?? '',
        categoryName: json['category_name']?.toString() ?? '',
        imageUrl: json['image_url']?.toString() ?? '',
        stockUser: safeParseInt(json['stock_user']),
        magazaPrice: json['magaza_price']?.toString() ?? '',
        image: json['image']?.toString() ?? '',
        stock: safeParseInt(json['stock']),
        musteriPrice: safeParseInt(json['MusteriPrice']),
        category: CategoryOfRestApi.fromJson(
            json['category'] as Map<String, dynamic>),
      );
    } catch (e, stackTrace) {
      print('Error parsing product: $e');
      print('Stack trace: $stackTrace');
      print('Problematic JSON: $json');
      rethrow;
    }
  }
}

class CategoryOfRestApi {
  final int id;
  final String name;
  final int? parentId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? webLimit;
  final String? baselinkerLimit;
  final String? storeLimit;
  final String? toptanLimit;
  final DateTime? deletedAt;
  final String? image;
  final String? isHomePage;
  final dynamic order; // Changed to dynamic
  final String? col;
  final String? isWeb;
  final String? grupId;

  CategoryOfRestApi({
    required this.id,
    required this.name,
    this.parentId,
    required this.createdAt,
    required this.updatedAt,
    this.webLimit,
    this.baselinkerLimit,
    this.storeLimit,
    this.toptanLimit,
    this.deletedAt,
    this.image,
    this.isHomePage,
    this.order,
    this.col,
    this.isWeb,
    this.grupId,
  });

  factory CategoryOfRestApi.fromJson(Map<String, dynamic> json) {
    try {
      return CategoryOfRestApi(
        id: json['id'] as int,
        name: json['name']?.toString() ?? '',
        parentId: json['parent_id'] as int?,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
        webLimit: json['web_limit']?.toString(),
        baselinkerLimit: json['baselinker_limit']?.toString(),
        storeLimit: json['store_limit']?.toString(),
        toptanLimit: json['toptan_limit']?.toString(),
        deletedAt: json['deleted_at'] != null
            ? DateTime.parse(json['deleted_at'] as String)
            : null,
        image: json['image']?.toString(),
        isHomePage: json['is_home_page']?.toString(),
        order: json['order'], // Keep as dynamic
        col: json['col']?.toString(),
        isWeb: json['is_web']?.toString(),
        grupId: json['grup_id']?.toString(),
      );
    } catch (e) {
      print('Error parsing category: $e');
      print('Problematic JSON: $json');
      rethrow;
    }
  }
}
