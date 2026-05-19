import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/product.dart';
import '../utils/constants.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final VoidCallback onAddToCart;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              child: GestureDetector(
                onTap: () => _showImageDialog(context, product.image),
                child: Container(
                  height: 180,
                  width: double.infinity,
                  color: AppColors.primaryPurple.withOpacity(0.1),
                  child: _buildProductImage(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primaryPurple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      product.category,
                      style: const TextStyle(fontSize: 10, color: AppColors.primaryPurple),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'UGX ${product.price.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: AppColors.primaryPurple,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.inventory,
                        size: 12,
                        color: product.stock > 10
                          ? Colors.green
                            : (product.stock > 0? Colors.orange : Colors.red),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${product.stock} items left',
                        style: TextStyle(
                          fontSize: 10,
                          color: product.stock > 10
                            ? Colors.green
                              : (product.stock > 0? Colors.orange : Colors.red),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: product.stock > 0? onAddToCart : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryPurple,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        product.stock > 0? 'Add to Cart' : 'Out of Stock',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductImage() {
    String imageUrl = product.image.trim();

    print('Product: ${product.name} | Image starts with: ${imageUrl.isNotEmpty? imageUrl.substring(0, imageUrl.length > 30? 30 : imageUrl.length) : "EMPTY"}');

    // Handle base64 images from old DB entries
    if (imageUrl.startsWith('data:image')) {
      try {
        final base64String = imageUrl.split(',').last;
        final cleanedBase64 = base64String.replaceAll(RegExp(r'\s+'), '');
        return Image.memory(
          base64Decode(cleanedBase64),
          height: 180,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            print('Base64 decode error for ${product.name}: $error');
            return _buildFallback();
          },
        );
      } catch (e) {
        print('Base64 exception for ${product.name}: $e');
        return _buildFallback();
      }
    }

    // Handle raw base64 without data:image prefix
    if (imageUrl.length > 100 &&!imageUrl.startsWith('http')) {
      try {
        final cleanedBase64 = imageUrl.replaceAll(RegExp(r'\s+'), '');
        return Image.memory(
          base64Decode(cleanedBase64),
          height: 180,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            print('Raw base64 error for ${product.name}: $error');
            return _buildFallback();
          },
        );
      } catch (e) {
        print('Raw base64 exception for ${product.name}: $e');
        return _buildFallback();
      }
    }

    // Handle Multer URLs
    if (imageUrl.contains('unplash')) {
      imageUrl = imageUrl.replaceAll('unplash', 'unsplash');
    }

    if (imageUrl.contains('?ix=')) {
      imageUrl = '${imageUrl.split('?ix=')[0]}?w=300';
    }

    if (imageUrl.isNotEmpty && imageUrl.startsWith('http')) {
      if (!imageUrl.contains('?w=') &&!imageUrl.contains('?')) {
        imageUrl = '$imageUrl?w=300';
      }
      return Image.network(
        imageUrl,
        height: 180,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print('Network image error for ${product.name}: $error | URL: $imageUrl');
          return _buildFallback();
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            height: 180,
            width: double.infinity,
            color: AppColors.primaryPurple.withOpacity(0.1),
            child: const Center(
              child: SizedBox(
                height: 30,
                width: 30,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        },
      );
    }

    return _buildFallback();
  }

  Widget _buildFallback() {
    return Container(
      height: 180,
      width: double.infinity,
      color: AppColors.primaryPurple.withOpacity(0.1),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.shopping_bag, size: 40, color: AppColors.primaryPurple),
            const SizedBox(height: 8),
            Text(
              product.name,
              style: TextStyle(fontSize: 12, color: AppColors.primaryPurple.withOpacity(0.7)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
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
                panEnabled: true,
                minScale: 0.5,
                maxScale: 4,
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
    String imageUrl = imagePath;

    if (imageUrl.contains('unplash')) {
      imageUrl = imageUrl.replaceAll('unplash', 'unsplash');
    }

    if (imageUrl.isNotEmpty && (imageUrl.startsWith('http') || imageUrl.startsWith('https'))) {
      return Image.network(imageUrl, fit: BoxFit.contain);
    }

    if (imageUrl.startsWith('data:image')) {
      try {
        final base64String = imageUrl.split(',').last;
        return Image.memory(base64Decode(base64String), fit: BoxFit.contain);
      } catch (e) {
        return const Icon(Icons.broken_image, size: 60, color: Colors.white);
      }
    }

    return const Icon(Icons.image_not_supported, size: 60, color: Colors.white);
  }
}