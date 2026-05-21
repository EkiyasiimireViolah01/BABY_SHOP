import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../models/product.dart';
import '../models/cart_item.dart';
import '../models/order.dart';
import '../models/feedback_message.dart';
import '../models/customer.dart';
import '../utils/constants.dart';
import 'home_page.dart';
import 'categories_page.dart';
import 'cart_page.dart';
import 'account_page.dart';

class MainHomePage extends StatefulWidget {
  const MainHomePage({super.key});

  @override
  State<MainHomePage> createState() => _MainHomePageState();
}

class _MainHomePageState extends State<MainHomePage> {
  int _selectedIndex = 0;
  bool _isLoggedIn = false;
  Customer? _currentCustomer;
  
  List<Product> _products = [];
  List<CartItem> _cartItems = [];
  List<Order> _orders = [];
  List<FeedbackMessage> _feedbacks = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // Load products from API
      final productsData = await ApiService.getProducts();
      if (productsData.isEmpty) {
        _products = _getDefaultProducts();
        for (final product in _products) {
          await ApiService.createProduct(product.toJson());
        }
      } else {
        _products = productsData.map((json) => Product.fromJson(json)).toList();
      }
      
      // Load orders from API if logged in
      if (_currentCustomer != null) {
        final ordersData = await ApiService.getUserOrders(_currentCustomer!.email);
        _orders = ordersData.map((json) => Order.fromJson(json)).toList();
      }
      
      // Load feedbacks from API
      final feedbacksData = await ApiService.getAllFeedback();
      _feedbacks = feedbacksData.map((json) => FeedbackMessage.fromJson(json)).toList();
      
      // Load customer from local storage (session only)
      final customer = await StorageService.loadCurrentCustomer();
      if (customer != null) {
        _currentCustomer = customer;
        _isLoggedIn = true;
      }
      
      // Load cart items from local storage (temporary)
      final cartItems = await StorageService.loadCartItems();
      _cartItems = cartItems;
      
      setState(() {});
    } catch (e) {
      // Silent fail
    }
  }

  Future<void> _saveData() async {
    await StorageService.saveCartItems(_cartItems);
    if (_isLoggedIn && _currentCustomer != null) {
      await StorageService.saveCurrentCustomer(_currentCustomer);
    }
  }

  List<Product> _getDefaultProducts() {
    return [
      Product(id: '1', name: 'Baby Cotton Onesie', price: 25000, image: 'https://images.unsplash.com/photo-1522771939531-1f9c5f5a2e3f?w=300', category: 'Clothing', description: 'Soft cotton onesie for newborns', stock: 50),
      Product(id: '2', name: 'Baby Feeding Bottle', price: 15000, image: 'https://images.unsplash.com/photo-1522335789203-aabd1fc54bc9?w=300', category: 'Feeding', description: 'BPA-free feeding bottle', stock: 100),
      Product(id: '3', name: 'Soft Baby Blanket', price: 35000, image: 'https://images.unsplash.com/photo-1544818493-250d509c8dd5?w=300', category: 'Nursery', description: 'Warm and cozy blanket', stock: 30),
      Product(id: '4', name: 'Baby Walker', price: 85000, image: 'https://images.unsplash.com/photo-1555252333-9f8e92e65df9?w=300', category: 'Toys', description: 'Adjustable baby walker', stock: 15),
      Product(id: '5', name: 'Diaper Pack', price: 20000, image: 'https://images.unsplash.com/photo-1583947215250-095d32b6f8b9?w=300', category: 'Diapers', description: 'Super absorbent diapers', stock: 200),
      Product(id: '6', name: 'Baby Bath Tub', price: 45000, image: 'https://images.unsplash.com/photo-1595981267035-7b04ca84a82d?w=300', category: 'Bath', description: 'Non-slip baby bathtub', stock: 25),
      Product(id: '7', name: 'Teething Toy Set', price: 18000, image: 'https://images.unsplash.com/photo-1595435934242-5f6f2c20d34d?w=300', category: 'Toys', description: 'Safe silicone teething toys', stock: 60),
      Product(id: '8', name: 'Baby Stroller', price: 150000, image: 'https://images.unsplash.com/photo-1564466808903-44c6c6d2a5c4?w=300', category: 'Travel', description: 'Lightweight foldable stroller', stock: 10),
    ];
  }

  int get _cartItemCount => _cartItems.fold(0, (sum, item) => sum + item.quantity);
  double get _cartTotal => _cartItems.fold(0, (sum, item) => sum + (item.product.price * item.quantity));

  void _addToCart(Product product) {
    setState(() {
      final existingIndex = _cartItems.indexWhere((item) => item.product.id == product.id);
      if (existingIndex != -1) {
        _cartItems[existingIndex].quantity++;
      } else {
        _cartItems.add(CartItem(product: product));
      }
      _saveData();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${product.name} added to cart!'), backgroundColor: AppColors.successGreen),
    );
  }

  void _removeFromCart(int index) {
    setState(() {
      _cartItems.removeAt(index);
      _saveData();
    });
  }

  void _updateCartQuantity(int index, int change) {
    setState(() {
      final int newQuantity = _cartItems[index].quantity + change;
      if (newQuantity >= 1) {
        _cartItems[index].quantity = newQuantity;
      }
      _saveData();
    });
  }

  void _placeOrder({required String phone, required String location, required String paymentMethod}) async {
    final orderData = {
      'customerName': _currentCustomer?.name ?? 'Guest',
      'customerEmail': _currentCustomer?.email ?? 'guest@example.com',
      'phone': phone,
      'location': location,
      'paymentMethod': paymentMethod,
      'items': _cartItems.map((item) => {
        'productId': item.product.id,
        'name': item.product.name,
        'price': item.product.price,
        'quantity': item.quantity,
        'image': item.product.image,
      }).toList(),
      'totalAmount': _cartTotal,
    };
    
    final response = await ApiService.createOrder(orderData);
    
    if (response.containsKey('_id')) {
      final newOrder = Order(
        id: response['_id'],
        orderNumber: response['orderNumber'] ?? 'ORD-${DateTime.now().millisecondsSinceEpoch}',
        items: List.from(_cartItems),
        totalAmount: _cartTotal,
        status: response['status'] ?? 'Pending',
        date: DateTime.now().toString().substring(0, 16),
        phone: phone,
        location: location,
        paymentMethod: paymentMethod,
        customerName: _currentCustomer?.name ?? 'Guest',
        customerEmail: _currentCustomer?.email ?? 'guest@example.com',
      );
      
      setState(() {
        _orders.insert(0, newOrder);
        _cartItems.clear();
        _saveData();
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order placed successfully!'), backgroundColor: AppColors.successGreen),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response['message'] ?? 'Failed to place order'), backgroundColor: Colors.red),
      );
    }
  }

  void _sendFeedback(String message) async {
    if (_currentCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to send feedback'), backgroundColor: Colors.orange),
      );
      return;
    }
    
    final feedbackData = {
      'customerName': _currentCustomer!.name,
      'customerEmail': _currentCustomer!.email,
      'message': message,
      'date': DateTime.now().toString().substring(0, 16),
      'status': 'New',
    };
    
    final response = await ApiService.createFeedback(feedbackData);
    
    if (response.containsKey('_id')) {
      final newFeedback = FeedbackMessage(
        id: response['_id'],
        customerName: _currentCustomer!.name,
        customerEmail: _currentCustomer!.email,
        message: message,
        date: DateTime.now().toString().substring(0, 16),
        status: 'New',
        reply: null,
      );
      
      setState(() {
        _feedbacks.insert(0, newFeedback);
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Feedback sent to admin!'), backgroundColor: AppColors.successGreen),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response['message'] ?? 'Failed to send feedback'), backgroundColor: Colors.red),
      );
    }
  }

  void _handleLogin(Customer customer) async {
    setState(() {
      _isLoggedIn = true;
      _currentCustomer = customer;
    });
    
    final ordersData = await ApiService.getUserOrders(customer.email);
    setState(() {
      _orders = ordersData.map((json) => Order.fromJson(json)).toList();
    });
    
    await StorageService.saveCurrentCustomer(customer);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Welcome ${customer.name}!'), backgroundColor: AppColors.successGreen),
    );
  }

  void _handleLogout() async {
    setState(() {
      _isLoggedIn = false;
      _currentCustomer = null;
      _cartItems.clear();
      _orders.clear();
      _selectedIndex = 0;
    });
    await StorageService.saveCurrentCustomer(null);
    await StorageService.saveCartItems([]);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Logged out successfully!'), backgroundColor: AppColors.warningOrange),
    );
  }

  void _showCheckoutDialog() {
    final TextEditingController phoneController = TextEditingController();
    final TextEditingController locationController = TextEditingController();
    String selectedPayment = 'Cash on Delivery';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text('Checkout'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Enter your details to complete order', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: phoneController,
                    decoration: const InputDecoration(labelText: 'Phone Number *', border: OutlineInputBorder(), prefixIcon: Icon(Icons.phone)),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: locationController,
                    decoration: const InputDecoration(labelText: 'Delivery Address *', border: OutlineInputBorder(), prefixIcon: Icon(Icons.location_on)),
                  ),
                  const SizedBox(height: 12),
                  const Text('Payment Method', style: TextStyle(fontWeight: FontWeight.bold)),
                  RadioListTile(
                    title: const Text('Cash on Delivery'),
                    value: 'Cash on Delivery',
                    groupValue: selectedPayment,
                    onChanged: (value) => setStateDialog(() => selectedPayment = value.toString()),
                    activeColor: AppColors.primaryPurple,
                  ),
                  RadioListTile(
                    title: const Text('Mobile Money'),
                    value: 'Mobile Money',
                    groupValue: selectedPayment,
                    onChanged: (value) => setStateDialog(() => selectedPayment = value.toString()),
                    activeColor: AppColors.primaryPurple,
                  ),
                  RadioListTile(
                    title: const Text('Credit Card'),
                    value: 'Credit Card',
                    groupValue: selectedPayment,
                    onChanged: (value) => setStateDialog(() => selectedPayment = value.toString()),
                    activeColor: AppColors.primaryPurple,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppColors.primaryPurple.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Amount:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('UGX ${_cartTotal.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryPurple)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () {
                  if (phoneController.text.isEmpty || locationController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please fill all fields'), backgroundColor: AppColors.warningOrange),
                    );
                    return;
                  }
                  Navigator.pop(context);
                  _placeOrder(
                    phone: phoneController.text.trim(),
                    location: locationController.text.trim(),
                    paymentMethod: selectedPayment,
                  );
                  setState(() => _selectedIndex = 3);
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryPurple),
                child: const Text('Place Order'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BabyShop', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: AppColors.primaryPurple,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () => setState(() => _selectedIndex = 2),
              ),
              if (_cartItemCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text('$_cartItemCount', style: const TextStyle(color: Colors.white, fontSize: 10)),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          HomePage(
            products: _products,
            onAddToCart: _addToCart,
            onShowCheckout: () {
              if (!_isLoggedIn) {
                setState(() => _selectedIndex = 3);
              } else {
                _showCheckoutDialog();
              }
            },
          ),
          CategoriesPage(
            products: _products,
            onAddToCart: _addToCart,
          ),
          CartPage(
            cartItems: _cartItems,
            onRemove: _removeFromCart,
            onUpdateQuantity: _updateCartQuantity,
            cartTotal: _cartTotal,
            onCheckout: () {
              if (!_isLoggedIn) {
                setState(() => _selectedIndex = 3);
              } else {
                _showCheckoutDialog();
              }
            },
          ),
          AccountPage(
            isLoggedIn: _isLoggedIn,
            customer: _currentCustomer,
            orders: _orders,
            feedbacks: _feedbacks,
            onLogin: _handleLogin,
            onLogout: _handleLogout,
            onSendFeedback: _sendFeedback,
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: AppColors.primaryPurple,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.category), label: 'Categories'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Cart'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Account'),
        ],
      ),
    );
  }
}