import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shop_app/business%20logic/firebase_service.dart';
import 'package:shop_app/business%20logic/models/cart_model.dart';
import 'package:shop_app/screens/details/wholesaler_detail_screen.dart';
import 'package:shop_app/screens/post%20checkout%20screen/post_checkout_screen.dart';

class CartScreen extends StatefulWidget {
  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  bool _isLoading = false;
  final Map<String, TextEditingController> _quantityControllers = {};
  final Map<String, Timer> _debounceTimers = {};  // Added debounce timers
  final Map<String, int> _localQuantities = {};  // Local state for immediate UI updates

  @override
  void dispose() {
    _quantityControllers.values.forEach((controller) => controller.dispose());
    _debounceTimers.values.forEach((timer) => timer.cancel());  // Cancel timers on dispose
    super.dispose();
  }

  Future<void> _updateQuantity(CartItem item, int quantity) async {
    setState(() => _isLoading = true);
    try {
      await _firebaseService.updateCartItemQuantity(item.productId, quantity);
    } catch (e) {
      _showError('Failed to update quantity');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _removeItem(CartItem item) async {
    setState(() => _isLoading = true);
    try {
      await _firebaseService.removeFromCart(item.productId);
      // Clean up controller when item is removed
      final controller = _quantityControllers.remove(item.productId);
      controller?.dispose();
      _showSuccess('Item removed from cart');
    } catch (e) {
      _showError('Failed to remove item');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('Error', style: AppTypography.heading3),
        content: Text(message, style: AppTypography.body),
        actions: [
          CupertinoDialogAction(
            child: Text('OK', style: AppTypography.body),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: AppTypography.body.copyWith(color: Colors.white)),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.accent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AppColors.background.withOpacity(0.9),
        border: null,
        middle: Text('Shopping Cart', style: AppTypography.heading2),
      ),
      child: SafeArea(
        child: StreamBuilder<Cart>(
          stream: _firebaseService.getCartStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CupertinoActivityIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error loading cart items',
                  style: AppTypography.body.copyWith(
                    color: CupertinoColors.destructiveRed,
                  ),
                ),
              );
            }

            final cart = snapshot.data ?? Cart(items: []);

            if (cart.items.isEmpty) {
              return _buildEmptyCart();
            }

            return Stack(
              children: [
                ListView.separated(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 100),
                  itemCount: cart.items.length,
                  separatorBuilder: (context, index) => SizedBox(height: 16),
                  itemBuilder: (context, index) => _buildCartItem(cart.items[index]),
                ),
                _buildBottomSheet(cart),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.cart,
            size: 64,
            color: AppColors.textLight,
          ),
          SizedBox(height: 16),
          Text(
            'Your cart is empty',
            style: AppTypography.body,
          ),
          SizedBox(height: 8),
          Text(
            'Start shopping to add items to your cart',
            style: AppTypography.bodyLight,
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(CartItem item) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.text.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                item.image,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 80,
                  height: 80,
                  color: AppColors.cardBackground,
                  child: Icon(
                    CupertinoIcons.photo,
                    color: AppColors.textLight,
                  ),
                ),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: AppTypography.heading3,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    '${item.price} ${item.currency}',
                    style: AppTypography.price,
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      QuantityInput(
                        key: ValueKey(item.productId), // Important for maintaining state
                        item: item,
                        onQuantityChanged: (item, quantity) async {
                          try {
                            await _firebaseService.updateCartItemQuantity(item.productId, quantity);
                          } catch (e) {
                            _showError('Failed to update quantity');
                          }
                        },
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () => _removeItem(item),
                        child: const Icon(
                          CupertinoIcons.trash,
                          color: CupertinoColors.destructiveRed,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  TextEditingController _getQuantityController(CartItem item) {
    if (!_quantityControllers.containsKey(item.productId)) {
      final controller = TextEditingController(text: item.quantity.toString());
      _localQuantities[item.productId] = item.quantity;  // Initialize local quantity
      _quantityControllers[item.productId] = controller;
    }
    return _quantityControllers[item.productId]!;
  }

  void _updateLocalQuantity(CartItem item, String value) {
    final newValue = int.tryParse(value);
    if (newValue != null && newValue > 0 && newValue <= 9999) {
      setState(() {
        _localQuantities[item.productId] = newValue;  // Update local quantity
      });
      
      // Cancel existing timer
      _debounceTimers[item.productId]?.cancel();
      
      // Start new timer for database update
      _debounceTimers[item.productId] = Timer(
        const Duration(milliseconds: 1000),
        () => _updateDatabaseQuantity(item, newValue),  // Update database after delay
      );
    }
  }

  Future<void> _updateDatabaseQuantity(CartItem item, int quantity) async {
    try {
      await _firebaseService.updateCartItemQuantity(item.productId, quantity);
    } catch (e) {
      // Revert local state on error
      setState(() {
        _localQuantities[item.productId] = item.quantity;  // Reset to original quantity
        _quantityControllers[item.productId]?.text = item.quantity.toString();
      });
      _showError('Failed to update quantity');
    }
  }

  Widget _buildBottomSheet(Cart cart) {
    if (cart.items.isEmpty) return SizedBox();

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: AppColors.text.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Total', style: AppTypography.bodyLight),
                    Text(
                      '${cart.total.toStringAsFixed(2)} ${cart.items.first.currency}',
                      style: AppTypography.heading2,
                    ),
                  ],
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: CupertinoButton(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(12),
                  onPressed: () {
                    // Implement checkout
                    Navigator.push(context, MaterialPageRoute(builder: (context) => PostCheckoutScreen(cart: cart)));
                  },
                  child: Text(
                    'Checkout',
                    style: AppTypography.body.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Update status indicator
  Widget _buildQuantityUpdateIndicator(String productId) {
    final isUpdating = _debounceTimers[productId]?.isActive ?? false;
    if (!isUpdating) return SizedBox.shrink();

    return Positioned(
      top: 0,
      right: 0,
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: AppColors.accent,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  // Optional: Add this method to provide visual feedback while typing
  Widget _buildQuantityWithStatus(CartItem item) {
    return Stack(
      children: [
        QuantityInput(
          key: ValueKey(item.productId), // Important for maintaining state
          item: item,
          onQuantityChanged: (item, quantity) async {
            await _firebaseService.updateCartItemQuantity(item.productId, quantity);
          },
        ),
        _buildQuantityUpdateIndicator(item.productId),  // Show update indicator
      ],
    );
  }
}

// New QuantityInput widget
class QuantityInput extends StatefulWidget {
  final CartItem item;
  final Function(CartItem, int) onQuantityChanged;

  const QuantityInput({
    Key? key,
    required this.item,
    required this.onQuantityChanged,
  }) : super(key: key);

  @override
  _QuantityInputState createState() => _QuantityInputState();
}

class _QuantityInputState extends State<QuantityInput> {
  late TextEditingController _controller;
  Timer? _debounceTimer;
  int _localQuantity = 0;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _localQuantity = widget.item.quantity;
    _controller = TextEditingController(text: _localQuantity.toString());
  }

  @override
  void dispose() {
    _controller.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  // New method to handle quantity changes
  void _handleQuantityChange(int newQuantity) {
    if (newQuantity > 0 && newQuantity <= 9999) {
      setState(() {
        _localQuantity = newQuantity;
        _controller.text = newQuantity.toString();
      });

      _debounceTimer?.cancel();
      _debounceTimer = Timer(
        const Duration(milliseconds: 1000),
        () {
          if (_localQuantity != widget.item.quantity) {
            widget.onQuantityChanged(widget.item, _localQuantity);
          }
        },
      );
    }
  }

  // New method to handle text input changes
  void _handleTextChange(String value) {
    final newValue = int.tryParse(value);
    if (newValue != null) {
      _handleQuantityChange(newValue);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Only update local quantity if not focused and quantity changed externally
    if (!_isFocused && widget.item.quantity != _localQuantity) {
      _localQuantity = widget.item.quantity;
      _controller.text = _localQuantity.toString();
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.border,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Updated button logic
          CupertinoButton(
            padding: EdgeInsets.all(8),
            onPressed: _localQuantity > 1 
                ? () => _handleQuantityChange(_localQuantity - 1)
                : null,
            child: Icon(
              CupertinoIcons.minus,
              size: 16,
              color: _localQuantity > 1 
                  ? AppColors.text 
                  : AppColors.textLight,
            ),
          ),
          SizedBox(
            width: 50,
            child: Focus(
              onFocusChange: (hasFocus) {
                setState(() => _isFocused = hasFocus);
                if (!hasFocus) {
                  final value = int.tryParse(_controller.text);
                  if (value != null && value > 0) {
                    _handleQuantityChange(value);
                  } else {
                    _controller.text = _localQuantity.toString();
                  }
                }
              },
              child: CupertinoTextField(
                controller: _controller,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                decoration: BoxDecoration(
                  color: AppColors.background,
                ),
                style: AppTypography.body,
                onChanged: _handleTextChange,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  TextInputFormatter.withFunction((oldValue, newValue) {
                    if (newValue.text.isEmpty) return newValue;
                    final value = int.tryParse(newValue.text);
                    if (value == null || value <= 0) return oldValue;
                    if (value > 9999) return oldValue;
                    return newValue;
                  }),
                ],
              ),
            ),
          ),
          CupertinoButton(
            padding: EdgeInsets.all(8),
            onPressed: _localQuantity < 9999 
                ? () => _handleQuantityChange(_localQuantity + 1)
                : null,
            child: Icon(
              CupertinoIcons.plus,
              size: 16,
              color: _localQuantity < 9999 
                  ? AppColors.text 
                  : AppColors.textLight,
            ),
          ),
        ],
      ),
    );
  }
}
