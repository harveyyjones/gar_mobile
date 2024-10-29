import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<List<Map<String, dynamic>>> getUserOrders() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return Stream.value([]);
    }

    print('Fetching orders for user: $userId'); // Debug log

    // Query all orders where user_id matches current user
    return _firestore
        .collection('orders') // Query within the 'orders' collection
        .where('user_id', isEqualTo: userId) // Use the field name 'user_id'
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) {
          print('Found ${snapshot.docs.length} orders'); // Debug log
          
          return snapshot.docs.map((doc) {
            final data = doc.data();
            print('Processing order: ${doc.id}'); // Debug log
            
            return {
              ...data,
              'orderId': data['order_id'] ?? doc.id,
              'orderDate': data['created_at'],
              'status': data['status'] ?? 'pending',
              'items': data['items'] ?? [],
              'total': data['total'] ?? 0.0,
              'currency': (data['items'] as List<dynamic>?)?.firstOrNull?['currency'] ?? 'PLN',
            };
          }).toList();
        });
  }
}
