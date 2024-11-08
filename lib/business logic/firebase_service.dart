import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shop_app/business%20logic/models/cart_model.dart';
import 'package:shop_app/business%20logic/models/liked_items_model.dart';
import 'package:shop_app/business%20logic/models/product_model.dart';
import 'package:shop_app/business%20logic/models/wholesaler_model.dart';
import 'package:shop_app/business_logic_rest_api/models/product.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth =
      FirebaseAuth.instance; // Added Firebase Auth instance

  // Alternative method using doc() directly if you have the ID
  Future<WholesalerModel?> fetchWholesalerByIdDirect(String salerId) async {
    // New method added
    try {
      DocumentSnapshot doc = await _firestore
          .collection('sellers') // Updated collection name
          .doc(salerId)
          .get();

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return WholesalerModel.fromFirestore(data, doc.id);
      }
      return null;
    } catch (e) {
      print('Error fetching wholesaler: $e');
      throw Exception('Failed to fetch wholesaler data');
    }
  }

  // Stream version for real-time updates
  Stream<WholesalerModel?> wholesalerStream(String salerId) {
    // New method added
    return _firestore
        .collection('sellers') // Updated collection name
        .doc(salerId)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return WholesalerModel.fromFirestore(data, doc.id);
      }
      return null;
    });
  }

  Future<List<Product>> fetchAllProductsWithSalerId(String sellerId) async {
    try {
      print('Fetching products for seller: $sellerId'); // Debug log
      QuerySnapshot querySnapshot = await _firestore
          .collection('products')
          .doc(sellerId)
          .collection('product_items')
          .get();

      return querySnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        // Ensure seller ID is included in the data
        data['seller_id'] = sellerId; // Add seller ID to the data

        Product product = Product.fromFirestore(doc);
        print(
            'Fetched product: ${product.name} with seller ID: ${product.salerId}'); // Debug log
        return product;
      }).toList();
    } catch (e) {
      print('Error fetching products: $e');
      return [];
    }
  }

  Future<void> toggleLikeProduct(
    String productId,
  ) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final userRef = _firestore.collection('users').doc(user.uid);
    final likedItemsRef = userRef.collection('liked_items');
    final productDocRef =
        likedItemsRef.doc(productId); // Updated to use productDocRef

    final likedDoc = await productDocRef.get();

    if (likedDoc.exists) {
      // If the product is already liked, unlike it by deleting the document
      await productDocRef.delete();
    } else {
      // If the product is not liked, like it by creating the document
      await productDocRef.set({
        'id': productId,
        'liked_at': FieldValue.serverTimestamp(),
      });
    }
  }

  Stream<bool> isProductLiked(String productId) {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(false);

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('liked_items')
        .doc(productId)
        .snapshots()
        .map((snapshot) => snapshot.exists);
  }

  Future<void> initializeLikedItems() async {
    // New method added
    final user = _auth.currentUser;
    if (user == null) return;

    final userRef = _firestore.collection('users').doc(user.uid);
    final likedItemsRef = userRef.collection('liked_items');

    // Check if the liked_items collection exists
    final likedItemsDoc = await likedItemsRef.limit(1).get();
    if (likedItemsDoc.docs.isEmpty) {
      // If the collection doesn't exist, create an empty document to initialize it
      await likedItemsRef.doc('placeholder').set({'initialized': true});
    }
  }

  Stream<List<LikedProduct>> getLikedProductsStream() {
    final user = _auth.currentUser;
    if (user == null) {
      // If there's no logged in user, return an empty stream
      return Stream.value([]);
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('liked_items')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => LikedProduct.fromFirestore(doc))
          .toList();
    });
  }

  Future<Product?> fetchProductById(String productId, String salerId) async {
    // New method added
    try {
      DocumentSnapshot doc = await _firestore
          .collection('products')
          .doc(salerId)
          .collection('product_items')
          .doc(productId)
          .get();

      if (doc.exists) {
        return Product.fromFirestore(doc);
      }
      return null; // No product found
    } catch (e) {
      print('Error fetching product by ID: $e');
      return null;
    }
  }

  // Add this getter for user cart reference
  DocumentReference get userCartRef {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('cart')
        .doc('current_cart');
  }

  Future<void> addToCart(
      ProductRestApi product, int quantity, BuildContext context) async {
    try {
      print('Adding product to cart:');
      print('Product ID: ${product.id}');

      // if (product.salerId.isEmpty) {
      //   throw Exception('Product has no seller ID');
      // }

      final cartDoc = await userCartRef.get();
      final List<dynamic> currentItems = cartDoc.exists
          ? (cartDoc.data() as Map<String, dynamic>)['cart_items'] ?? []
          : [];

      final existingItemIndex =
          currentItems.indexWhere((item) => item['product_id'] == product.id);

      final itemData = {
        'product_id': product.id,
        'name': product.name,
        'price': product.price,
        'sale_price': product.salePrice,
        'image': product.imageUrl,
        'quantity': quantity,
        'category': product.categoryName,
        'updated_at': FieldValue.serverTimestamp(),
      };

      print('Cart item data: $itemData');

      if (existingItemIndex != -1) {
        print('Updating existing item');
        currentItems[existingItemIndex] = {
          ...currentItems[existingItemIndex],
          'quantity': quantity,
        };
      } else {
        print('Adding new item');
        currentItems.add(itemData);
      }

      // Update cart document - remove top-level seller_id
      await userCartRef.set({
        'cart_items': currentItems,
        'updated_at': FieldValue.serverTimestamp(),
      });

      print('Successfully added/updated item in cart');
    } catch (e) {
      print('Error adding to cart: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add item to cart: $e'),
          backgroundColor: Colors.red,
        ),
      );
      rethrow;
    }
  }

  // Update the cart stream to include seller ID
  Stream<Cart> getCartStream() {
    return userCartRef.snapshots().map((snapshot) {
      try {
        if (!snapshot.exists) {
          print('Cart document does not exist');
          return Cart.empty();
        }

        final data = snapshot.data() as Map<String, dynamic>;
        return Cart.fromFirestore(data);
      } catch (e, stackTrace) {
        print('Error in getCartStream: $e');
        print('Stack trace: $stackTrace');
        return Cart.empty();
      }
    });
  }

  // Get cart once
  Future<Cart> getCart() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return Cart(items: []);

      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('cart')
          .doc('current_cart')
          .get();

      if (!doc.exists) return Cart(items: []);
      return Cart.fromFirestore(doc.data() ?? {});
    } catch (e) {
      print('Error getting cart: $e');
      return Cart(items: []);
    }
  }

  // Add item to cart
  Future<void> addToCartForCartScreen(
      ProductRestApi product, int quantity) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw 'User not authenticated';

      final cartRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('cart')
          .doc('current_cart');

      final cart = await getCart();
      final existingItemIndex =
          cart.items.indexWhere((item) => item.productId == product.id);

      if (existingItemIndex != -1) {
        // Update existing item
        cart.items[existingItemIndex].quantity += quantity;
      } else {
        // Add new item
        cart.items.add(
          CartItem(
            productId: product.id.toString(),
            name: product.name ?? '',
            image: product.imageUrl,
            price: product.price,
            salePrice: product.salePrice,
            quantity: quantity,
            categoryName: product.categoryName,
          ),
        );
      }

      await cartRef.set(cart.toFirestore());
    } catch (e) {
      print('Error adding to cart: $e');
      rethrow;
    }
  }

  // Update cart item quantity
  Future<void> updateCartItemQuantity(String productId, int newQuantity) async {
    try {
      final cartDoc = await userCartRef.get();
      if (!cartDoc.exists) return;

      final cart = Cart.fromFirestore(cartDoc.data() as Map<String, dynamic>);
      final updatedItems = cart.items.map((item) {
        if (item.productId == productId) {
          return item.copyWith(quantity: newQuantity);
        }
        return item;
      }).toList();

      await userCartRef.set(Cart(items: updatedItems).toFirestore());
    } catch (e) {
      print('Error updating cart quantity: $e');
      rethrow;
    }
  }

  // Remove item from cart
  Future<void> removeFromCart(String productId) async {
    try {
      final cartDoc = await userCartRef.get();
      if (!cartDoc.exists) return;

      final List<dynamic> items =
          (cartDoc.data() as Map<String, dynamic>)['cart_items'];
      items.removeWhere((item) => item['product_id'] == productId);

      await userCartRef.update({
        'cart_items': items,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error removing item from cart: $e');
      rethrow;
    }
  }

  // Clear cart
  Future<void> clearCart() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw 'User not authenticated';

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('cart')
          .doc('current_cart')
          .set({'cart_items': []});
    } catch (e) {
      print('Error clearing cart: $e');
      rethrow;
    }
  }

  // Fetch current user data
  Future<Map<String, dynamic>?> getUserData() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('No user logged in');

      final doc = await _firestore.collection('users').doc(userId).get();

      return doc.data();
    } catch (e) {
      print('Error fetching user data: $e');
      return null;
    }
  }

  // Update user profile
  Future<void> updateUserProfile(Map<String, dynamic> userData) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('No user logged in');

      // Update timestamp
      userData['last_updated'] = FieldValue.serverTimestamp();

      await _firestore.collection('users').doc(userId).update(userData);
    } catch (e) {
      print('Error updating user profile: $e');
      throw Exception('Failed to update profile');
    }
  }

  // Updated to handle both buyer and seller orders
  Future<String> saveOrder({
    required Cart cart,
    required Map<String, dynamic> userData,
    required Map<String, dynamic> deliveryAddress,
  }) async {
    try {
      print('Starting saveOrder process...');

      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      print('Authenticated user ID: $userId');
      print('Cart items count: ${cart.items.length}');
      print('Total order value: ${cart.total}');

      // Group items by seller and validate seller IDs
      final Map<String, List<CartItem>> itemsBySeller = {};
      for (var item in cart.items) {
        // Validate seller ID
        if (item.categoryName.isEmpty) {
          throw Exception('Invalid seller ID for product: ${item.name}');
        }

        print(
            'Processing item: ${item.name} with seller ID: ${item.categoryName}'); // Debug log

        if (!itemsBySeller.containsKey(item.categoryName)) {
          itemsBySeller[item.categoryName] = [];
        }
        itemsBySeller[item.categoryName]!.add(item);
      }

      if (itemsBySeller.isEmpty) {
        throw Exception('No valid sellers found in cart items');
      }

      print('Orders grouped by ${itemsBySeller.length} sellers');

      final batch = _firestore.batch();
      final baseOrderId = 'ORD${DateTime.now().millisecondsSinceEpoch}';
      final orderIds = <String>[];

      // Process each seller's order
      for (var entry in itemsBySeller.entries) {
        final sellerId = entry.key;

        // Validate seller ID again
        if (sellerId.isEmpty) {
          continue; // Skip invalid seller IDs
        }

        final sellerItems = entry.value;
        final orderId = '${baseOrderId}_$sellerId';
        orderIds.add(orderId);

        print('Processing order for seller: $sellerId');

        // Create order document
        final orderData = {
          'order_id': orderId,
          'user_id': userId,
          'seller_id': sellerId,
          'items': sellerItems.map((item) => item.toFirestore()).toList(),
          'delivery_address': deliveryAddress,
          'user_data': userData,
          'total': sellerItems.fold(
              0.0, (sum, item) => sum + (item.price * item.quantity)),
          'status': 'pending',
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        };

        // Verify seller exists before adding to batch
        final sellerDoc =
            await _firestore.collection('sellers').doc(sellerId).get();
        if (!sellerDoc.exists) {
          print('Warning: Seller $sellerId does not exist');
          continue; // Skip non-existent sellers
        }

        // Save to seller's orders
        batch.set(_firestore.collection('orders').doc(orderId), orderData);
      }

      if (orderIds.isEmpty) {
        throw Exception('No valid orders could be created');
      }

      print('Committing batch write...');
      await batch.commit();
      print('Batch write successful');

      // Clear the cart after successful order
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('cart')
          .doc('current_cart')
          .set({'cart_items': []});

      print('Cart cleared successfully');
      return orderIds.join(', ');
    } catch (e, stackTrace) {
      print('Error in saveOrder: $e');
      print('Stack trace: $stackTrace');
      throw e;
    }
  }

  Stream<List<WholesalerModel>> wholesalersStream() {
    return _firestore.collection('sellers').snapshots().map((snapshot) {
      print('Stream received ${snapshot.docs.length} wholesalers');

      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data();
        print('Processing wholesaler: ${doc.id}');
        // Added print statement to log raw address data
        print(
            'Raw address data: ${data['adress_of_company']}, ${data['city']}, ${data['country']}');

        try {
          WholesalerModel wholesaler =
              WholesalerModel.fromFirestore(data, doc.id);
          // Added print statement to log processed address data
          print(
              'Processed address: ${wholesaler.address.addressOfCompany}, ${wholesaler.address.city}, ${wholesaler.address.country}');
          return wholesaler;
        } catch (e) {
          print('Error processing wholesaler ${doc.id}: $e');
          return _createDefaultWholesaler(doc.id, data);
        }
      }).toList();
    });
  }

  WholesalerModel _createDefaultWholesaler(
      String docId, Map<String, dynamic> data) {
    // New method added
    return WholesalerModel(
      id: docId,
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      name: data['name'] ?? '',
      surname: '',
      nipNumber: '',
      isActive: true,
      isSellerInApp: true,
      rating: 0.0,
      totalSales: 0,
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      address: AddressDetails(
        addressOfCompany: data['adress'] ?? '',
        city: data['city'] ?? '',
        country: data['country'] ?? '',
        zipNo: '',
      ),
      bankDetails: BankDetails(
        accountNumber: '',
        bankName: '',
        swiftCode: '',
      ),
      categories: [],
      paymentMethods: [],
      products: [],
      shippingMethods: [],
      workingHours: WorkingHours(
        monday: DayHours(open: '', close: ''),
        tuesday: DayHours(open: '', close: ''),
        wednesday: DayHours(open: '', close: ''),
        thursday: DayHours(open: '', close: ''),
        friday: DayHours(open: '', close: ''),
        saturday: DayHours(open: '', close: ''),
        sunday: DayHours(open: '', close: ''),
      ),
      logoUrl: '',
      sellerId: '',
    );
  }

  // Debug method to print all sellers
  Future<void> debugPrintAllSellers() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('sellers').get();
      print('Total sellers in database: ${snapshot.docs.length}');
      snapshot.docs.forEach((doc) {
        print('Seller ID: ${doc.id}');
        print('Data: ${doc.data()}');
      });
    } catch (e) {
      print('Debug print error: $e');
    }
  }

  Future<List<WholesalerModel>> fetchWholesalers() async {
    // New method added
    try {
      final QuerySnapshot querySnapshot = await _firestore
          .collection('users')
          .where('is_seller_in_app', isEqualTo: true)
          .where('is_active', isEqualTo: true)
          .get();

      return querySnapshot.docs.map((doc) {
        return WholesalerModel.fromFirestore(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
    } catch (e) {
      print('Error fetching wholesalers: $e');
      rethrow;
    }
  }

  Future<WholesalerModel?> fetchWholesalerById(String wholesalerId) async {
    // New method added
    try {
      final DocumentSnapshot doc =
          await _firestore.collection('sellers').doc(wholesalerId).get();

      if (!doc.exists) {
        return null;
      }

      return WholesalerModel.fromFirestore(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );
    } catch (e) {
      print('Error fetching wholesaler by ID: $e');
      rethrow;
    }
  }

  // Helper method to validate working hours // New method added
  bool isOpenNow(WorkingHours workingHours) {
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

    final openTime = _parseTimeString(dayHours!.open);
    final closeTime = _parseTimeString(dayHours.close);
    final currentTime =
        DateTime(now.year, now.month, now.day, now.hour, now.minute);

    return currentTime.isAfter(openTime) && currentTime.isBefore(closeTime);
  }

  DateTime _parseTimeString(String timeString) {
    // New method added
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
}
