import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import '../../models/product.dart';
import '../../models/order.dart';
import '../../models/feedback_message.dart';
import '../../models/customer.dart';
import '../../services/api_service.dart';
import '../../utils/constants.dart';
import '../../screens/main_home_page.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;

  List<Product> _products = [];
  List<Order> _orders = [];
  List<FeedbackMessage> _feedbacks = [];
  List<Customer> _customers = [];

  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _productPriceController = TextEditingController();
  final TextEditingController _productCategoryController = TextEditingController();
  final TextEditingController _productDescriptionController = TextEditingController();
  final TextEditingController _productStockController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  File? _selectedImage;
  Uint8List? _webImageBytes;
  String _imagePreviewUrl = '';
  final ImagePicker _picker = ImagePicker();
  String _editingProductId = '';
  String _searchQuery = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final productsData = await ApiService.getProducts();
      if (productsData.isEmpty) {
        _products = _getDefaultProducts();
        for (var product in _products) {
          await ApiService.createProduct(product.toJson());
        }
      } else {
        _products = productsData.map((json) => Product.fromJson(json)).toList();
      }

      final ordersData = await ApiService.getAllOrders();
      _orders = ordersData.map((json) => Order.fromJson(json)).toList();

      final feedbacksData = await ApiService.getAllFeedback();
      _feedbacks = feedbacksData.map((json) => FeedbackMessage.fromJson(json)).toList();

      final customersData = await ApiService.getCustomers();
      _customers = customersData.map((json) => Customer.fromJson(json)).toList();

      setState(() {});
    } catch (e) {
      print('Error loading data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Product> _getDefaultProducts() {
    return [
      Product(id: '1', name: 'Baby Cotton Onesie', price: 25000, image: 'https://images.unsplash.com/photo-1522771939531-1f9c5f5a2e3f?w=300', category: 'Clothing', description: 'Soft cotton onesie for newborns', stock: 50),
      Product(id: '2', name: 'Baby Feeding Bottle', price: 15000, image: 'https://images.unsplash.com/photo-1522335789203-aabd1fc54bc9?w=300', category: 'Feeding', description: 'BPA-free feeding bottle', stock: 100),
      Product(id: '3', name: 'Soft Baby Blanket', price: 35000, image: 'https://images.unsplash.com/photo-1544818493-250d509c8dd5?w=300', category: 'Nursery', description: 'Warm and cozy blanket', stock: 30),
      Product(id: '4', name: 'Baby Walker', price: 85000, image: 'https://images.unsplash.com/photo-1555252333-9f8e92e65df9?w=300', category: 'Toys', description: 'Adjustable baby walker', stock: 15),
      Product(id: '5', name: 'Diaper Pack', price: 20000, image: 'https://images.unsplash.com/photo-1583947215250-095d32b6f8b9?w=300', category: 'Diapers', description: 'Super absorbent diapers', stock: 200),
    ];
  }

  List<Product> get _filteredProducts {
    if (_searchQuery.isEmpty) return _products;
    return _products.where((p) =>
      p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
      p.category.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (pickedFile!= null) {
        if (kIsWeb) {
          final bytes = await pickedFile.readAsBytes();
          setState(() {
            _webImageBytes = bytes;
            _selectedImage = null;
            _imagePreviewUrl = '';
          });
        } else {
          setState(() {
            _selectedImage = File(pickedFile.path);
            _webImageBytes = null;
            _imagePreviewUrl = pickedFile.path;
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error picking image'), backgroundColor: Colors.red),
      );
    }
  }

  Future<String> _processImageForUpload() async {
    if (_selectedImage!= null &&!kIsWeb) {
      final bytes = await _selectedImage!.readAsBytes();
      return 'data:image/jpeg;base64,${base64Encode(bytes)}';
    } else if (_webImageBytes!= null && kIsWeb) {
      return 'data:image/jpeg;base64,${base64Encode(_webImageBytes!)}';
    }
    return '';
  }

  void _addProduct() async {
    if (_productNameController.text.isEmpty || _productPriceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill product name and price'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    String imagePath = 'https://images.unsplash.com/photo-1522771939531-1f9c5f5a2e3f?w=300';

    try {
      if ((_selectedImage!= null &&!kIsWeb) || (_webImageBytes!= null && kIsWeb)) {
        imagePath = await _processImageForUpload();
        if (imagePath.isEmpty) {
          throw Exception('Failed to process image');
        }
      }

      final productData = {
        'name': _productNameController.text,
        'price': double.parse(_productPriceController.text),
        'image': imagePath,
        'category': _productCategoryController.text.isEmpty? 'General' : _productCategoryController.text,
        'description': _productDescriptionController.text.isEmpty? 'No description' : _productDescriptionController.text,
        'stock': int.tryParse(_productStockController.text)?? 10,
      };

      final response = await ApiService.createProduct(productData);

      if (response.containsKey('_id')) {
        final newProduct = Product(
          id: response['_id'],
          name: productData['name'] as String,
          price: (productData['price'] as num).toDouble(),
          image: productData['image'] as String,
          category: productData['category'] as String,
          description: productData['description'] as String,
          stock: productData['stock'] as int,
        );

        setState(() {
          _products.add(newProduct);
        });

        _clearProductForm();
        if (Navigator.canPop(context)) Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product added to database!'), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message']?? 'Failed to add product'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error adding product'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _editProduct(Product product) {
    _editingProductId = product.id;
    _productNameController.text = product.name;
    _productPriceController.text = product.price.toString();
    _productCategoryController.text = product.category;
    _productDescriptionController.text = product.description;
    _productStockController.text = product.stock.toString();
    _imagePreviewUrl = product.image;
    _selectedImage = null;
    _webImageBytes = null;
    _showProductDialog(isEditing: true);
  }

  void _updateProduct() async {
    setState(() {
      _isLoading = true;
    });

    try {
      String imagePath = _imagePreviewUrl;

      if ((_selectedImage!= null &&!kIsWeb) || (_webImageBytes!= null && kIsWeb)) {
        imagePath = await _processImageForUpload();
        if (imagePath.isEmpty) {
          throw Exception('Failed to process image');
        }
      }

      final productData = {
        'name': _productNameController.text,
        'price': double.parse(_productPriceController.text),
        'image': imagePath,
        'category': _productCategoryController.text.isEmpty? 'General' : _productCategoryController.text,
        'description': _productDescriptionController.text.isEmpty? 'No description' : _productDescriptionController.text,
        'stock': int.tryParse(_productStockController.text)?? 10,
      };

      final response = await ApiService.updateProduct(_editingProductId, productData);

      if (response.containsKey('_id')) {
        final index = _products.indexWhere((p) => p.id == _editingProductId);
        if (index!= -1) {
          setState(() {
            _products[index] = Product(
              id: _editingProductId,
              name: productData['name'] as String,
              price: (productData['price'] as num).toDouble(),
              image: productData['image'] as String,
              category: productData['category'] as String,
              description: productData['description'] as String,
              stock: productData['stock'] as int,
            );
          });
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product updated in database!'), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message']?? 'Failed to update product'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error updating product'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
      _clearProductForm();
      if (Navigator.canPop(context)) Navigator.pop(context);
    }
  }

  void _deleteProduct(String productId) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: const Text('Are you sure you want to delete this product?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              setState(() {
                _isLoading = true;
              });
              await ApiService.deleteProduct(productId);
              setState(() {
                _products.removeWhere((p) => p.id == productId);
                _isLoading = false;
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Product deleted from database!'), backgroundColor: Colors.red),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _clearProductForm() {
    _productNameController.clear();
    _productPriceController.clear();
    _productCategoryController.clear();
    _productDescriptionController.clear();
    _productStockController.clear();
    _selectedImage = null;
    _webImageBytes = null;
    _imagePreviewUrl = '';
    _editingProductId = '';
  }

  Widget _buildImagePreview() {
    if (_selectedImage!= null &&!kIsWeb) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.file(
          _selectedImage!,
          width: double.infinity,
          height: 120,
          fit: BoxFit.cover,
        ),
      );
    } else if (_webImageBytes!= null && kIsWeb) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.memory(
          _webImageBytes!,
          width: double.infinity,
          height: 120,
          fit: BoxFit.cover,
        ),
      );
    } else if (_imagePreviewUrl.isNotEmpty) {
      return Image.network(
        _imagePreviewUrl,
        width: double.infinity,
        height: 120,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.image_not_supported, size: 40),
                Text('Tap to select image'),
              ],
            ),
          );
        },
      );
    } else {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.upload_file, size: 40, color: Colors.grey),
            SizedBox(height: 8),
            Text('Tap to upload product image'),
          ],
        ),
      );
    }
  }

  void _showProductDialog({bool isEditing = false}) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: Text(isEditing? 'Edit Product' : 'Add New Product'),
            content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        await _pickImage();
                        setStateDialog(() {});
                      },
                      child: Container(
                        height: 120,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: _buildImagePreview(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _productNameController,
                      decoration: const InputDecoration(labelText: 'Product Name *', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _productPriceController,
                      decoration: const InputDecoration(labelText: 'Price (UGX) *', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _productCategoryController,
                      decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _productDescriptionController,
                      decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _productStockController,
                      decoration: const InputDecoration(labelText: 'Stock Quantity', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () {
                _clearProductForm();
                Navigator.pop(context);
              }, child: const Text('Cancel')),
              ElevatedButton(
                onPressed: isEditing? _updateProduct : _addProduct,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryPurple),
                child: _isLoading
                   ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator())
                    : Text(isEditing? 'Update' : 'Add'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _updateOrderStatus(String orderId, String newStatus) async {
    final response = await ApiService.updateOrderStatus(orderId, newStatus);
    if (response.containsKey('_id')) {
      final index = _orders.indexWhere((o) => o.id == orderId);
      if (index!= -1) {
        setState(() {
          _orders[index].status = newStatus;
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order status updated to $newStatus'), backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update status'), backgroundColor: Colors.red),
      );
    }
  }

  void _replyToFeedback(FeedbackMessage feedback) async {
    final TextEditingController replyController = TextEditingController(text: feedback.reply?? '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reply to ${feedback.customerName}'),
        content: TextField(
          controller: replyController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Type your reply here...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final response = await ApiService.updateFeedback(feedback.id, {
                'status': 'Replied',
                'reply': replyController.text,
              });

              if (response.containsKey('_id')) {
                final index = _feedbacks.indexWhere((f) => f.id == feedback.id);
                if (index!= -1) {
                  setState(() {
                    _feedbacks[index].status = 'Replied';
                    _feedbacks[index].reply = replyController.text;
                  });
                }
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Reply sent to customer!'), backgroundColor: Colors.green),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Failed to send reply'), backgroundColor: Colors.red),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryPurple),
            child: const Text('Send Reply'),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending': return Colors.orange;
      case 'Processing': return Colors.blue;
      case 'Shipped': return Colors.purple;
      case 'On the way': return Colors.teal;
      case 'Delivered': return Colors.green;
      default: return Colors.grey;
    }
  }

  Widget _buildProductImage(String imagePath) {
    if (imagePath.startsWith('http')) {
      return Image.network(
        imagePath,
        width: 50,
        height: 50,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 50,
            height: 50,
            color: AppColors.primaryPurple.withOpacity(0.1),
            child: const Icon(Icons.image_not_supported, size: 24, color: Colors.grey),
          );
        },
      );
    } else if (imagePath.startsWith('data:image')) {
      try {
        final base64String = imagePath.split(',').last;
        return Image.memory(
          base64Decode(base64String),
          width: 50,
          height: 50,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: 50,
              height: 50,
              color: AppColors.primaryPurple.withOpacity(0.1),
              child: const Icon(Icons.image_not_supported, size: 24, color: Colors.grey),
            );
          },
        );
      } catch (e) {
        return Container(
          width: 50,
          height: 50,
          color: AppColors.primaryPurple.withOpacity(0.1),
          child: const Icon(Icons.broken_image, size: 24, color: Colors.grey),
        );
      }
    } else if (!kIsWeb && (imagePath.contains('/') || imagePath.contains('\\'))) {
      return Image.file(
        File(imagePath),
        width: 50,
        height: 50,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 50,
            height: 50,
            color: AppColors.primaryPurple.withOpacity(0.1),
            child: const Icon(Icons.image_not_supported, size: 24, color: Colors.grey),
          );
        },
      );
    } else {
      return Container(
        width: 50,
        height: 50,
        color: AppColors.primaryPurple.withOpacity(0.1),
        child: Center(
          child: Text(
            imagePath.isNotEmpty && imagePath.length <= 2? imagePath : '📦',
            style: const TextStyle(fontSize: 24),
          ),
        ),
      );
    }
  }

  // UPDATED: Added onTap parameter and InkWell wrapper
  Widget _buildStatCard(String title, int value, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5)],
        ),
        child: Column(
          children: [
            Icon(icon, size: 30, color: color),
            const SizedBox(height: 8),
            Text(value.toString(), style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
            Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusButton(String status, String currentStatus, VoidCallback onPressed) {
    final isSelected = status == currentStatus;
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected? _getStatusColor(status) : Colors.grey.shade200,
        foregroundColor: isSelected? Colors.white : Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        minimumSize: Size.zero,
      ),
      child: Text(status, style: const TextStyle(fontSize: 11)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: AppColors.primaryPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const MainHomePage()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: AppColors.primaryPurple),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('Admin Panel', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text('admin@babyshop.com', style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Dashboard'),
              selected: _selectedIndex == 0,
              onTap: () => setState(() { _selectedIndex = 0; Navigator.pop(context); }),
            ),
            ListTile(
              leading: const Icon(Icons.inventory),
              title: const Text('Products'),
              selected: _selectedIndex == 1,
              onTap: () => setState(() { _selectedIndex = 1; Navigator.pop(context); }),
            ),
            ListTile(
              leading: const Icon(Icons.shopping_cart),
              title: const Text('Orders'),
              selected: _selectedIndex == 2,
              onTap: () => setState(() { _selectedIndex = 2; Navigator.pop(context); }),
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Customers'),
              selected: _selectedIndex == 3,
              onTap: () => setState(() { _selectedIndex = 3; Navigator.pop(context); }),
            ),
            ListTile(
              leading: const Icon(Icons.feedback),
              title: const Text('Feedback'),
              selected: _selectedIndex == 4,
              onTap: () => setState(() { _selectedIndex = 4; Navigator.pop(context); }),
            ),
          ],
        ),
      ),
      body: _isLoading
         ? const Center(child: CircularProgressIndicator())
          : IndexedStack(
              index: _selectedIndex,
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.admin_panel_settings, size: 80, color: AppColors.primaryPurple),
                      const SizedBox(height: 20),
                      const Text('Welcome, Admin!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      const Text('Manage your store from the sidebar', style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 30),
                      Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        alignment: WrapAlignment.center,
                        children: [
                          // UPDATED: Added onTap callbacks to switch tabs
                          _buildStatCard('Products', _products.length, Icons.inventory, AppColors.primaryPurple,
                            () => setState(() => _selectedIndex = 1)),
                          _buildStatCard('Orders', _orders.length, Icons.shopping_cart, Colors.blue,
                            () => setState(() => _selectedIndex = 2)),
                          _buildStatCard('Customers', _customers.length, Icons.people, Colors.green,
                            () => setState(() => _selectedIndex = 3)),
                          _buildStatCard('Feedbacks', _feedbacks.length, Icons.feedback, Colors.orange,
                            () => setState(() => _selectedIndex = 4)),
                        ],
                      ),
                    ],
                  ),
                ),
                // Products Management
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: Colors.white,
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              onChanged: (value) {
                                setState(() {
                                  _searchQuery = value;
                                });
                              },
                              decoration: const InputDecoration(
                                hintText: 'Search products...',
                                prefixIcon: Icon(Icons.search),
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton.icon(
                            onPressed: () => _showProductDialog(isEditing: false),
                            icon: const Icon(Icons.add),
                            label: const Text('Add Product'),
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryPurple),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: _filteredProducts.length,
                        itemBuilder: (context, index) {
                          final product = _filteredProducts[index];
                          return Card(
                            margin: const EdgeInsets.all(8),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(12),
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: SizedBox(
                                  width: 50,
                                  height: 50,
                                  child: _buildProductImage(product.image),
                                ),
                              ),
                              title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('UGX ${product.price.toStringAsFixed(0)} | Stock: ${product.stock} | ${product.category}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () => _editProduct(product),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _deleteProduct(product.id),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                // Orders Management
                _orders.isEmpty
                   ? const Center(child: Text('No orders yet'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: _orders.length,
                        itemBuilder: (context, index) {
                          final order = _orders[index];
                          return Card(
                            margin: const EdgeInsets.all(8),
                            child: ExpansionTile(
                              leading: CircleAvatar(
                                backgroundColor: _getStatusColor(order.status).withOpacity(0.2),
                                child: Text(order.status[0], style: TextStyle(color: _getStatusColor(order.status))),
                              ),
                              title: Text(order.orderNumber, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('${order.customerName} | ${order.date}'),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(order.status).withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(order.status, style: TextStyle(color: _getStatusColor(order.status), fontSize: 12)),
                                  ),
                                  Text('UGX ${order.totalAmount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Order Details:', style: TextStyle(fontWeight: FontWeight.bold)),
                                      Text('Customer: ${order.customerName}'),
                                      Text('Phone: ${order.phone}'),
                                      Text('Location: ${order.location}'),
                                      Text('Payment: ${order.paymentMethod}'),
                                      const Divider(),
                                      const Text('Items:', style: TextStyle(fontWeight: FontWeight.bold)),
                                     ...order.items.map((item) => Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 4),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text('${item.product.name} x${item.quantity}'),
                                            Text('UGX ${(item.product.price * item.quantity).toStringAsFixed(0)}'),
                                          ],
                                        ),
                                      )),
                                      const Divider(),
                                      const Text('Update Status:', style: TextStyle(fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 8,
                                        children: [
                                          _buildStatusButton('Pending', order.status, () => _updateOrderStatus(order.id, 'Pending')),
                                          _buildStatusButton('Processing', order.status, () => _updateOrderStatus(order.id, 'Processing')),
                                          _buildStatusButton('Shipped', order.status, () => _updateOrderStatus(order.id, 'Shipped')),
                                          _buildStatusButton('On the way', order.status, () => _updateOrderStatus(order.id, 'On the way')),
                                          _buildStatusButton('Delivered', order.status, () => _updateOrderStatus(order.id, 'Delivered')),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                // Customers Management
                _customers.isEmpty
                   ? const Center(child: Text('No customers yet'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: _customers.length,
                        itemBuilder: (context, index) {
                          final customer = _customers[index];
                          return Card(
                            margin: const EdgeInsets.all(8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppColors.primaryPurple,
                                child: Text(customer.name[0].toUpperCase(), style: const TextStyle(color: Colors.white)),
                              ),
                              title: Text(customer.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(customer.email),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.phone, size: 16, color: Colors.grey),
                                  Text(customer.phone, style: const TextStyle(fontSize: 12)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                // Feedback Management
                _feedbacks.isEmpty
                   ? const Center(child: Text('No feedback yet'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: _feedbacks.length,
                        itemBuilder: (context, index) {
                          final feedback = _feedbacks[index];
                          return Card(
                            margin: const EdgeInsets.all(8),
                            child: ExpansionTile(
                              leading: CircleAvatar(
                                backgroundColor: feedback.status == 'New'? Colors.orange.shade100 : Colors.green.shade100,
                                child: Icon(Icons.feedback, color: feedback.status == 'New'? Colors.orange : Colors.green),
                              ),
                              title: Text(feedback.customerName, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(feedback.date),
                              trailing: Chip(
                                label: Text(feedback.status),
                                backgroundColor: feedback.status == 'New'? Colors.orange.shade100 : Colors.green.shade100,
                              ),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Message:', style: TextStyle(fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade50,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(feedback.message),
                                      ),
                                      if (feedback.reply!= null)...[
                                        const SizedBox(height: 12),
                                        const Text('Your Reply:', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryPurple)),
                                        const SizedBox(height: 8),
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: AppColors.primaryPurple.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(feedback.reply!),
                                        ),
                                      ],
                                      if (feedback.status == 'New')...[
                                        const SizedBox(height: 16),
                                        ElevatedButton(
                                          onPressed: () => _replyToFeedback(feedback),
                                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryPurple),
                                          child: const Text('Reply to Customer'),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ],
            ),
    );
  }
}