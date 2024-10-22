import 'package:flutter/material.dart';
import 'package:shop_app/business%20logic/firebase_service.dart';
import 'package:shop_app/business%20logic/models/liked_items_model.dart';
import 'package:shop_app/screens/details/components/like_button.dart';


class LikedProductsWidget extends StatelessWidget {
  final FirebaseService _firebaseService = FirebaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Liked Products', style: TextStyle(color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black87),
      ),
      body: StreamBuilder<List<LikedProduct>>(
        stream: _firebaseService.getLikedProductsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _buildErrorState('Error: ${snapshot.error}');
          }

          final likedProducts = snapshot.data ?? [];

          if (likedProducts.isEmpty) {
            return _buildEmptyState();
          }

          return GridView.builder(
            padding: EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: likedProducts.length,
            itemBuilder: (context, index) {
              final product = likedProducts[index];
              return _buildProductCard(product);
            },
          );
        },
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 60, color: Colors.grey[600]),
          SizedBox(height: 16),
          Text('Oops! Something went wrong.',
              style: TextStyle(fontSize: 18, color: Colors.grey[800])),
          SizedBox(height: 8),
          Text(error, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border, size: 60, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text('No liked products yet',
              style: TextStyle(fontSize: 18, color: Colors.grey[600])),
          SizedBox(height: 8),
          Text('Start liking products to see them here!',
              style: TextStyle(fontSize: 14, color: Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _buildProductCard(LikedProduct product) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                    image: DecorationImage(
                      image: NetworkImage(product.productImage),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: LikeButton(
                    productId: product.id,
                    productDetails: product.toFirestore(),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4),
                Text(
                  '${product.price} ${product.currency}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
