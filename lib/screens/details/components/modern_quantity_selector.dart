import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ModernQuantitySelector extends StatefulWidget {
  final TextEditingController quantityController;
  final Function(int) onQuantityChanged;
  final Function(int) onAddToCart;

  const ModernQuantitySelector({
    Key? key,
    required this.quantityController,
    required this.onQuantityChanged,
    required this.onAddToCart,
  }) : super(key: key);

  @override
  _ModernQuantitySelectorState createState() => _ModernQuantitySelectorState();
}

class _ModernQuantitySelectorState extends State<ModernQuantitySelector> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = Tween<double>(begin: 1, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _animateButton() {
    _animationController.forward().then((_) {
      _animationController.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 3,
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildQuantityControls(),
          SizedBox(width: 16),
          _buildAddToCartButton(),
        ],
      ),
    );
  }

  Widget _buildQuantityControls() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildControlButton(Icons.remove, () {
            int currentValue = int.tryParse(widget.quantityController.text) ?? 1;
            if (currentValue > 1) {
              widget.quantityController.text = (currentValue - 1).toString();
              widget.onQuantityChanged(currentValue - 1);
            }
          }),
          Container(
            width: 50,
            child: TextField(
              controller: widget.quantityController,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 8),
              ),
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          _buildControlButton(Icons.add, () {
            int currentValue = int.tryParse(widget.quantityController.text) ?? 1;
            widget.quantityController.text = (currentValue + 1).toString();
            widget.onQuantityChanged(currentValue + 1);
          }),
        ],
      ),
    );
  }

  Widget _buildControlButton(IconData icon, VoidCallback onPressed) {
    return InkWell(
      onTap: () {
        onPressed();
        _animateButton();
      },
      child: Container(
        padding: EdgeInsets.all(8),
        child: Icon(icon, size: 20, color: Colors.blue[700]),
      ),
    );
  }

  Widget _buildAddToCartButton() {
    return ScaleTransition(
      scale: _animation,
      child: ElevatedButton(
        onPressed: () {
          int quantity = int.tryParse(widget.quantityController.text) ?? 1;
          widget.onAddToCart(quantity);
          _animateButton();
        },
        child: Text('Add to Cart', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white, backgroundColor: Colors.blue[700],
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 0,
        ),
      ),
    );
  }
}