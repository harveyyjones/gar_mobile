import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';

class DynamicLinkService {
  static final DynamicLinkService _instance = DynamicLinkService._internal();
  factory DynamicLinkService() => _instance;
  DynamicLinkService._internal();

  Uri? _initialLink;

  void setInitialLink(Uri link) {
    _initialLink = link;
  }

  Uri? getInitialLink() {
    final link = _initialLink;
    _initialLink = null; // Clear after getting
    return link;
  }

  // Create dynamic link for product
  Future<String> createProductLink(String productId) async {
    final dynamicLinkParams = DynamicLinkParameters(
      uriPrefix: 'https://gardeniamarket.page.link',
      link: Uri.parse('https://gardeniamarket.page.link/product?id=$productId'),
      androidParameters: const AndroidParameters(
        packageName: 'com.example.shop_app', // Your app's package name
        minimumVersion: 1,
      ),
      iosParameters: const IOSParameters(
        bundleId: 'com.example.shopApp', // Your iOS bundle ID
        minimumVersion: '1.0.0',
      ),
      socialMetaTagParameters: SocialMetaTagParameters(
        title: 'View Product',
        description: 'Check out this product on Gardenia Market!',
      ),
    );

    final shortLink = await FirebaseDynamicLinks.instance.buildShortLink(
      dynamicLinkParams,
      shortLinkType: ShortDynamicLinkType.unguessable,
    );

    return shortLink.shortUrl.toString();
  }

  // Create dynamic link for seller
  Future<String> createSellerLink(String sellerId) async {
    final dynamicLinkParams = DynamicLinkParameters(
      uriPrefix: 'https://gardeniamarket.page.link',
      link: Uri.parse('https://gardeniamarket.page.link/seller?id=$sellerId'),
      androidParameters: const AndroidParameters(
        packageName: 'com.example.shop_app', // Replace with your package name
        minimumVersion: 1,
      ),
      iosParameters: const IOSParameters(
        bundleId: 'com.example.shopApp', // Replace with your bundle ID
        minimumVersion: '1.0.0',
      ),
      socialMetaTagParameters: SocialMetaTagParameters(
        title: 'View Seller',
        description: 'Check out this seller on Gardenia Market!',
      ),
    );

    final shortLink = await FirebaseDynamicLinks.instance.buildShortLink(
      dynamicLinkParams,
      shortLinkType: ShortDynamicLinkType.unguessable,
    );

    return shortLink.shortUrl.toString();
  }

  Future<String> createDynamicLink({
    required String path,
    Map<String, String>? parameters,
  }) async {
    final DynamicLinkParameters parameters = DynamicLinkParameters(
      uriPrefix: 'https://gardeniamarket.page.link',
      link: Uri.parse('https://gardeniamarket.page.link$path'),
      androidParameters: const AndroidParameters(
        packageName: 'com.example.shop_app', // Your debug app package name
        minimumVersion: 0, // Set to 0 for development
      ),
      iosParameters: const IOSParameters(
        bundleId: 'com.example.shop_app', // Your iOS app bundle ID
        minimumVersion: '0.0.1', // Set to your minimum iOS version
      ),
    );
    final shortLink = await FirebaseDynamicLinks.instance.buildShortLink(
      parameters,
      shortLinkType: ShortDynamicLinkType.unguessable,
    );

    return shortLink.shortUrl.toString();
  }
}
