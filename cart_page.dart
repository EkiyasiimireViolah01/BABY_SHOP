import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/cart_item.dart';
import '../utils/constants.dart';

class CartPage extends StatelessWidget {
  final List<CartItem> cartItems;
  final Function(int) onRemove;
  final Function(int, int) onUpdateQuantity;
  final double cartTotal;
  final VoidCallback onCheckout;

  const CartPage({
    super.key,
    required this.cartItems,
    required this.onRemove,
    required this.onUpdateQuantity,
    required this.cartTotal,
    required this.onCheckout,
  });

  @override
  Widget build(BuildContext context) {
    if (cartItems.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text('Your cart is empty', style: TextStyle(fontSize: 18)),
            Text('Add items from Home or Categories', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: cartItems.length,
            itemBuilder: (context, index) {
              final item = cartItems[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      // FIXED: Clickable image instead of Text
                      GestureDetector(
                        onTap: () => _showImageDialog(context, item.product.image),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: SizedBox(
                            width: 70,
                            height: 70,
                            child: _buildCartImage(item.product.image),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text('UGX ${item.product.price.toStringAsFixed(0)}', style: const TextStyle(color: AppColors.primaryPurple)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                IconButton(
                                  onPressed: () => onUpdateQuantity(index, -1),
                                  icon: const Icon(Icons.remove_circle_outline),
                                  color: AppColors.primaryPurple,
                                ),
                                Text(item.quantity.toString(), style: const TextStyle(fontSize: 16)),
                                IconButton(
                                  onPressed: () => onUpdateQuantity(index, 1),
                                  icon: const Icon(Icons.add_circle_outline),
                                  color: AppColors.primaryPurple,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => onRemove(index),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5)],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  Text('UGX ${cartTotal.toStringAsFixed(0)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primaryPurple)),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onCheckout,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryPurple, padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: const Text('Proceed to Checkout', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCartImage(String imagePath) {
    if (imagePath.startsWith('http')) {
      return Image.network(
        imagePath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: AppColors.primaryPurple.withOpacity(0.1),
            child: const Icon(Icons.broken_image, size: 30),
          );
        },
      );
    } else if (imagePath.startsWith('data:image')) {
      try {
        final base64String = imagePath.split(',').last;
        return Image.memory(
          base64Decode(base64String),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: AppColors.primaryPurple.withOpacity(0.1),
              child: const Icon(Icons.broken_image, size: 30),
            );
          },
        );
      } catch (e) {
        return Container(
          color: AppColors.primaryPurple.withOpacity(0.1),
          child: const Icon(Icons.broken_image, size: 30),
        );
      }
    } else {
      return Container(
        color: AppColors.primaryPurple.withOpacity(0.1),
        child: const Icon(Icons.shopping_bag, color: AppColors.primaryPurple, size: 30),
      );
    }
  }

  void _showImageDialog(BuildContext context, String imagePath) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: _buildFullImage(imagePath),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFullImage(String imagePath) {
    if (imagePath.startsWith('http')) {
      return Image.network(imagePath, fit: BoxFit.contain);
    } else if (imagePath.startsWith('data:image')) {
      try {
        final base64String = imagePath.split(',').last;
        return Image.memory(base64Decode(base64String), fit: BoxFit.contain);
      } catch (e) {
        return const Icon(Icons.broken_image, size: 60, color: Colors.white);
      }
    } else {
      return const Icon(Icons.image_not_supported, size: 60, color: Colors.white);
    }
  }
}