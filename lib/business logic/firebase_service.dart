import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shop_app/business%20logic/models/cart_model.dart';
import 'package:shop_app/business%20logic/models/liked_items_model.dart';
import 'package:shop_app/business%20logic/models/product_model.dart';
import 'package:shop_app/business%20logic/models/wholesaler_model.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    final FirebaseAuth _auth = FirebaseAuth.instance;


  Future<List<Map<String, dynamic>>> fetchWholesalers() async {
    try {
      QuerySnapshot querySnapshot = await _firestore.collection('salers').get();
      return querySnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        // Exclude sensitive information
        data.remove('bank_account_details');
        data.remove('description');
        return data;
      }).toList();
    } catch (e) {
      print('Error fetching wholesalers: $e');
      return [];
    }
  }
  Future<Seller?> fetchWholesalerById(String salerId) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('salers')
          .where('saler_id', isEqualTo: salerId)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        DocumentSnapshot doc = querySnapshot.docs.first;
        Seller seller = Seller.fromFirestore(doc);
        // Exclude sensitive information if necessary
        // seller.bankAccountDetails = ''; // Example of excluding sensitive information
        // seller.description = ''; // Example of excluding sensitive information
        return seller;
      }
      return null; // No wholesaler found
    } catch (e) {
      print('Error fetching wholesaler by ID: $e');
      return null;
    }
  }

  Future<List<Product>> fetchAllProductsWithSalerId(String salerId) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('products')
          .doc(salerId)
          .collection('product_items')
          .get();

      return querySnapshot.docs.map((doc) {
        return Product.fromFirestore(doc);
      }).toList();
    } catch (e) {
      print('Error fetching products for wholesaler: $e');
      return [];
    }
  }


  Future<void> toggleLikeProduct(String productId, Map<String, dynamic> productDetails) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final userRef = _firestore.collection('users').doc(user.uid);
    final likedItemsRef = userRef.collection('liked_items');
    final productDocRef = likedItemsRef.doc(productId); // Updated to use productDocRef

    final likedDoc = await productDocRef.get();

    if (likedDoc.exists) {
      // If the product is already liked, unlike it by deleting the document
      await productDocRef.delete();
    } else {
      // If the product is not liked, like it by creating the document
      await productDocRef.set({
        'id': productId,
        'liked_at': FieldValue.serverTimestamp(),
        ...productDetails,
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

  Future<void> initializeLikedItems() async { // New method added
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

  Future<Product?> fetchProductById(String productId, String salerId) async { // New method added
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



  Future<void> addToCart(Product product, int quantity, BuildContext context) async { // Updated to accept quantity
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final cartRef = _firestore.collection('users').doc(user.uid).collection('cart').doc('current_cart');
        
        await _firestore.runTransaction((transaction) async {
          final cartDoc = await transaction.get(cartRef);
          
          if (cartDoc.exists) {
            List<dynamic> cartItems = cartDoc.data()?['cart_items'] ?? [];
            
            // Check if the product is already in the cart
            int existingIndex = cartItems.indexWhere((item) => item['product_id'] == product.id);
            
            if (existingIndex != -1) {
              // If the product is already in the cart, increase the quantity
              cartItems[existingIndex]['quantity'] = (cartItems[existingIndex]['quantity'] ?? 1) + 1;
            } else {
              // If the product is not in the cart, add it
              cartItems.add({
                'product_id': product.id,
                'name': product.name,
                'price': product.price,
                'currency': product.currency,
                'image': product.images.first,
                'quantity': quantity, // Use the passed quantity
              });
            }
            
            transaction.update(cartRef, {'cart_items': cartItems});
          } else {
            // If the cart doesn't exist, create it with the new product
            transaction.set(cartRef, {
              'cart_items': [{
                'product_id': product.id,
                'name': product.name,
                'price': product.price,
                'currency': product.currency,
                'image': product.images.first,
                'quantity': quantity, // Use the passed quantity
              }]
            });
          }
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Product added to cart')),
        );
      }
    } catch (e) {
      print('Error adding to cart: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add product to cart')),
      );
    }
  }

  // Get cart stream
  Stream<Cart> getCartStream() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value(Cart(items: []));

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('cart')
        .doc('current_cart')
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return Cart(items: []);
      return Cart.fromMap(snapshot.data() ?? {});
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
      return Cart.fromMap(doc.data() ?? {});
    } catch (e) {
      print('Error getting cart: $e');
      return Cart(items: []);
    }
  }

  // Add item to cart
  Future<void> addToCartForCartScreen(Product product, int quantity) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw 'User not authenticated';

      final cartRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('cart')
          .doc('current_cart');

      final cart = await getCart();
      final existingItemIndex = cart.items
          .indexWhere((item) => item.productId == product.id);

      if (existingItemIndex != -1) {
        // Update existing item
        cart.items[existingItemIndex].quantity += quantity;
      } else {
        // Add new item
        cart.items.add(
          CartItem(
            productId: product.id,
            name: product.name ?? '',
            image: product.images.first,
            price: product.price,
            currency: product.currency,
            quantity: quantity,
          ),
        );
      }

      await cartRef.set(cart.toMap());
    } catch (e) {
      print('Error adding to cart: $e');
      rethrow;
    }
  }

  // Update cart item quantity
  Future<void> updateCartItemQuantity(String productId, int quantity) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw 'User not authenticated';

      final cartRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('cart')
          .doc('current_cart');

      final cart = await getCart();
      final itemIndex = cart.items
          .indexWhere((item) => item.productId == productId);

      if (itemIndex != -1) {
        if (quantity <= 0) {
          cart.items.removeAt(itemIndex);
        } else {
          cart.items[itemIndex].quantity = quantity;
        }
        await cartRef.set(cart.toMap());
      }
    } catch (e) {
      print('Error updating cart item quantity: $e');
      rethrow;
    }
  }

  // Remove item from cart
  Future<void> removeFromCart(String productId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw 'User not authenticated';

      final cartRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('cart')
          .doc('current_cart');

      final cart = await getCart();
      cart.items.removeWhere((item) => item.productId == productId);
      await cartRef.set(cart.toMap());
    } catch (e) {
      print('Error removing from cart: $e');
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





}
