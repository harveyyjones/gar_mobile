import 'package:flutter/material.dart';
import 'package:shop_app/business%20logic/firebase_service.dart';

class LikeButton extends StatelessWidget {
  final String productId;
  final Map<String, dynamic> productDetails;
  final FirebaseService _firebaseService = FirebaseService();

  LikeButton({
    required this.productId,
    required this.productDetails,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: _firebaseService.isProductLiked(productId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        }

        final isLiked = snapshot.data ?? false;

        return GestureDetector(
          onTap: () => _firebaseService.toggleLikeProduct(productId, productDetails),
          child: AnimatedSwitcher(
            duration: Duration(milliseconds: 200),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return ScaleTransition(scale: animation, child: child);
            },
            child: Icon(
              isLiked ? Icons.favorite : Icons.favorite_border,
              key: ValueKey<bool>(isLiked),
              color: isLiked ? Colors.red : Colors.white,
              size: 28,
            ),
          ),
        );
      },
    );
  }
}