import 'package:flutter/material.dart';
import '../models/product.dart';
import '../widgets/product_card.dart';

class HomePage extends StatefulWidget {
  final List<Product> products;
  final Function(Product) onAddToCart;
  final VoidCallback onShowCheckout;

  const HomePage({
    super.key,
    required this.products,
    required this.onAddToCart,
    required this.onShowCheckout,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Debug print to check products
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('🔍 HomePage received ${widget.products.length} products');
      for (var p in widget.products) {
        print('📦 ${p.name} - Image: ${p.image}');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.products.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text('No products found', style: TextStyle(fontSize: 18)),
            Text('Please add products from Admin Dashboard', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    List<Product> filteredProducts = _searchQuery.isEmpty
        ? widget.products
        : widget.products.where((p) =>
            p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            p.category.toLowerCase().contains(_searchQuery.toLowerCase())
          ).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: 'Search products...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(icon: const Icon(Icons.clear), onPressed: () => setState(() => _searchQuery = ''))
                  : null,
            ),
          ),
        ),
        Expanded(
          child: filteredProducts.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 80, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No matching products', style: TextStyle(fontSize: 18)),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: filteredProducts.length,
                  itemBuilder: (context, index) {
                    final product = filteredProducts[index];
                    return ProductCard(
                      product: product,
                      onTap: () {
                        // Navigate to product detail
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