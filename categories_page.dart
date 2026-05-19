import 'package:flutter/material.dart';
import '../models/product.dart';
import '../widgets/product_card.dart';
import 'product_detail_page.dart';

class CategoriesPage extends StatefulWidget {
  final List<Product> products;
  final Function(Product) onAddToCart;

  const CategoriesPage({super.key, required this.products, required this.onAddToCart});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  String? _selectedCategory;
  
  List<String> get _categories {
    return widget.products.map((p) => p.category).toSet().toList();
  }

  List<Product> get _productsInCategory {
    if (_selectedCategory == null) return [];
    return widget.products.where((p) => p.category == _selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedCategory == null) {
      return GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final productCount = widget.products.where((p) => p.category == category).length;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = category),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.purple, Colors.purple.shade300]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.category, size: 50, color: Colors.white),
                  const SizedBox(height: 12),
                  Text(category, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('$productCount products', style: const TextStyle(color: Colors.white70)),
                ],
              ),
            ),
          );
        },
      );
    }
    
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _selectedCategory = null),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(_selectedCategory!, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              ),
              Text('${_productsInCategory.length} items', style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ),
        Expanded(
          child: _productsInCategory.isEmpty
              ? const Center(child: Text('No products in this category'))
              : GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.7,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: _productsInCategory.length,
                  itemBuilder: (context, index) {
                    final product = _productsInCategory[index];
                    return ProductCard(
                      product: product,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => ProductDetailPage(
                            product: product,
                            onAddToCart: widget.onAddToCart,
                          )),
                        );
                      },
                      onAddToCart: () => widget.onAddToCart(product),
                    );
                  },
                ),
        ),
      ],
    );
  }
}