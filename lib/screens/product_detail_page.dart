import 'package:flutter/material.dart';
import '../models/product.dart';
import '../utils/constants.dart';

class ProductDetailPage extends StatelessWidget {
  final Product product;
  final Function(Product) onAddToCart;

  const ProductDetailPage({super.key, required this.product, required this.onAddToCart});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(product.name), backgroundColor: AppColors.primaryPurple),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(color: AppColors.primaryPurple.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                child: Center(child: Text(product.image, style: const TextStyle(fontSize: 100))),
              ),
            ),
            const SizedBox(height: 20),
            Text(product.name, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: AppColors.primaryPurple.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
              child: Text(product.category, style: const TextStyle(color: AppColors.primaryPurple)),
            ),
            const SizedBox(height: 16),
            Text('UGX ${product.price.toStringAsFixed(0)}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.primaryPurple)),
            const SizedBox(height: 16),
            const Text('Description', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(product.description, style: const TextStyle(fontSize: 16, height: 1.5)),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.inventory, size: 20, color: Colors.grey),
                const SizedBox(width: 8),
                Text('Stock: ${product.stock} items available', style: const TextStyle(fontSize: 14)),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  onAddToCart(product);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryPurple, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text('Add to Cart', style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}