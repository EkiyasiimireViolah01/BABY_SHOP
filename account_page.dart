import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert';
import '../models/customer.dart';
import '../models/order.dart';
import '../models/feedback_message.dart';
import '../utils/constants.dart';
import '../services/api_service.dart';
import 'admin/admin_dashboard.dart';

class AccountPage extends StatefulWidget {
  final bool isLoggedIn;
  final Customer? customer;
  final List<Order> orders;
  final List<FeedbackMessage> feedbacks;
  final Function(Customer) onLogin;
  final VoidCallback onLogout;
  final Function(String) onSendFeedback;

  const AccountPage({
    super.key,
    required this.isLoggedIn,
    required this.customer,
    required this.orders,
    required this.feedbacks,
    required this.onLogin,
    required this.onLogout,
    required this.onSendFeedback,
  });

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final TextEditingController _loginEmail = TextEditingController();
  final TextEditingController _loginPassword = TextEditingController();
  final TextEditingController _regName = TextEditingController();
  final TextEditingController _regEmail = TextEditingController();
  final TextEditingController _regPhone = TextEditingController();
  final TextEditingController _regAddress = TextEditingController();
  final TextEditingController _regPassword = TextEditingController();
  final TextEditingController _regConfirm = TextEditingController();
  final TextEditingController _feedbackController = TextEditingController();

  final TextEditingController _prodName = TextEditingController();
  final TextEditingController _prodPrice = TextEditingController();
  final TextEditingController _prodDesc = TextEditingController();
  final TextEditingController _prodCategory = TextEditingController();
  final TextEditingController _prodStock = TextEditingController();
  XFile? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  bool _isLoginMode = true;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  int _selectedTab = 0;
  bool _isLoading = false;

  List<FeedbackMessage> _userFeedbacks = [];
  bool _loadingFeedback = false;

  // Updated for Chrome
  String baseUrl = 'http://localhost:5000';

  bool get isAdmin => widget.customer?.email == 'admin@babyshop.com';

  @override
  void initState() {
    super.initState();
    if (widget.isLoggedIn &&!isAdmin) {
      _fetchUserFeedback();
    }
  }

  Future<void> _fetchUserFeedback() async {
    if (widget.customer == null) return;
    setState(() => _loadingFeedback = true);
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/api/feedback/my/${widget.customer!.id}'),
      );
      if (res.statusCode == 200) {
        List data = json.decode(res.body);
        setState(() {
          _userFeedbacks = data.map((e) => FeedbackMessage.fromJson(e)).toList();
        });
      }
    } catch (e) {
      print('Fetch feedback error: $e');
    }
    setState(() => _loadingFeedback = false);
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

  String _getStatusIcon(String status) {
    switch (status) {
      case 'Pending': return '⏳';
      case 'Processing': return '🔄';
      case 'Shipped': return '📦';
      case 'On the way': return '🚚';
      case 'Delivered': return '✅';
      default: return '📋';
    }
  }

  void _handleLogin() async {
    final email = _loginEmail.text.trim();
    final password = _loginPassword.text.trim();
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter email and password')));
      return;
    }
    if (email == 'admin@babyshop.com' && password == 'admin1234') {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminDashboard()));
      return;
    }
    setState(() => _isLoading = true);
    final response = await ApiService.login(email, password);
    setState(() => _isLoading = false);
    if (response.containsKey('token')) {
      final customer = Customer(
        id: response['user']['_id']?? response['user']['id']?? '',
        name: response['user']['name']?? email.split('@')[0],
        email: email,
        phone: response['user']['phone']?? '',
        address: response['user']['address']?? '',
      );
      widget.onLogin(customer);
      _fetchUserFeedback();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Welcome ${customer.name}!'), backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response['message']?? 'Login failed'), backgroundColor: Colors.red),
      );
    }
  }

  void _handleRegister() async {
    final name = _regName.text.trim();
    final email = _regEmail.text.trim();
    final phone = _regPhone.text.trim();
    final address = _regAddress.text.trim();
    final password = _regPassword.text.trim();
    final confirm = _regConfirm.text.trim();
    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required fields')));
      return;
    }
    if (password!= confirm) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
      return;
    }
    setState(() => _isLoading = true);
    final response = await ApiService.register(name, email, password, phone: phone, address: address);
    setState(() => _isLoading = false);
    if (response.containsKey('token')) {
      final customer = Customer(
        id: response['user']['_id']?? response['user']['id']?? '',
        name: name,
        email: email,
        phone: phone,
        address: address,
      );
      widget.onLogin(customer);
      _fetchUserFeedback();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Welcome $name! Registration successful!'), backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response['message']?? 'Registration failed'), backgroundColor: Colors.red),
      );
    }
  }

  void _sendFeedback() async {
    final message = _feedbackController.text.trim();
    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a message')));
      return;
    }
    if (widget.customer == null) return;

    setState(() => _isLoading = true);
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/feedback'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': widget.customer!.id,
          'customerName': widget.customer!.name,
          'customerEmail': widget.customer!.email,
          'message': message,
          'date': DateTime.now().toIso8601String().split('T')[0],
        }),
      );
      if (res.statusCode == 201) {
        _feedbackController.clear();
        await _fetchUserFeedback();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Feedback sent!'), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
    setState(() => _isLoading = false);
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (image!= null) setState(() => _selectedImage = image);
  }

  Future<void> _addProduct() async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select an image')));
      return;
    }
    if (_prodName.text.isEmpty || _prodPrice.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name and Price are required')));
      return;
    }
    setState(() => _isLoading = true);
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/api/products'));
      request.fields['name'] = _prodName.text;
      request.fields['price'] = _prodPrice.text;
      request.fields['description'] = _prodDesc.text;
      request.fields['category'] = _prodCategory.text;
      request.fields['stock'] = _prodStock.text;
      request.files.add(await http.MultipartFile.fromPath('image', _selectedImage!.path));
      var response = await request.send();
      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Product added'), backgroundColor: Colors.green),
        );
        _clearProductForm();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _clearProductForm() {
    _prodName.clear();
    _prodPrice.clear();
    _prodDesc.clear();
    _prodCategory.clear();
    _prodStock.clear();
    setState(() => _selectedImage = null);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLoggedIn) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person, size: 80, color: AppColors.primaryPurple),
              const SizedBox(height: 20),
              Text(_isLoginMode? 'Welcome Back!' : 'Create Account', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 30),
              if (_isLoginMode)...[
                TextField(controller: _loginEmail, decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email), border: OutlineInputBorder())),
                const SizedBox(height: 16),
                TextField(controller: _loginPassword, obscureText: _obscurePassword, decoration: InputDecoration(
                  labelText: 'Password', prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(icon: Icon(_obscurePassword? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscurePassword =!_obscurePassword)),
                  border: const OutlineInputBorder())),
                const SizedBox(height: 24),
                ElevatedButton(onPressed: _isLoading? null : _handleLogin,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryPurple, minimumSize: const Size(double.infinity, 50)),
                  child: _isLoading? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white))
                      : const Text('Login', style: TextStyle(fontSize: 16))),
                TextButton(onPressed: () => setState(() => _isLoginMode = false), child: const Text("Don't have an account? Register")),
              ] else...[
                TextField(controller: _regName, decoration: const InputDecoration(labelText: 'Full Name *', prefixIcon: Icon(Icons.person), border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: _regEmail, decoration: const InputDecoration(labelText: 'Email *', prefixIcon: Icon(Icons.email), border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: _regPhone, decoration: const InputDecoration(labelText: 'Phone Number', prefixIcon: Icon(Icons.phone), border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: _regAddress, decoration: const InputDecoration(labelText: 'Delivery Address', prefixIcon: Icon(Icons.location_on), border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: _regPassword, obscureText: _obscurePassword, decoration: InputDecoration(
                  labelText: 'Password *', prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(icon: Icon(_obscurePassword? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscurePassword =!_obscurePassword)),
                  border: const OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: _regConfirm, obscureText: _obscureConfirmPassword, decoration: InputDecoration(
                  labelText: 'Confirm Password *', prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(icon: Icon(_obscureConfirmPassword? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscureConfirmPassword =!_obscureConfirmPassword)),
                  border: const OutlineInputBorder())),
                const SizedBox(height: 24),
                ElevatedButton(onPressed: _isLoading? null : _handleRegister,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryPurple, minimumSize: const Size(double.infinity, 50)),
                  child: _isLoading? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white))
                      : const Text('Register', style: TextStyle(fontSize: 16))),
                TextButton(onPressed: () => setState(() => _isLoginMode = true), child: const Text('Already have an account? Login')),
              ],
            ],
          ),
        ),
      );
    }

    return DefaultTabController(
      length: isAdmin? 4 : 3,
      child: Scaffold(
        body: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              color: AppColors.primaryPurple,
              child: Column(
                children: [
                  const CircleAvatar(radius: 40, backgroundColor: Colors.white, child: Icon(Icons.person, size: 50, color: AppColors.primaryPurple)),
                  const SizedBox(height: 12),
                  Text(widget.customer!.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                  Text(widget.customer!.email, style: const TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            TabBar(
              onTap: (index) => setState(() => _selectedTab = index),
              tabs: [
                const Tab(text: 'Orders', icon: Icon(Icons.shopping_bag)),
                const Tab(text: 'Feedback', icon: Icon(Icons.feedback)),
                const Tab(text: 'Account', icon: Icon(Icons.person)),
                if (isAdmin) const Tab(text: 'Add Product', icon: Icon(Icons.add_box)),
              ],
              labelColor: AppColors.primaryPurple,
              unselectedLabelColor: Colors.grey,
              indicatorColor: AppColors.primaryPurple,
              isScrollable: isAdmin,
            ),
            Expanded(
              child: IndexedStack(
                index: _selectedTab,
                children: [
                  widget.orders.isEmpty
                 ? const Center(child: Text('No orders yet'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: widget.orders.length,
                          itemBuilder: (context, index) {
                            final order = widget.orders[index];
                            return Card(child: ListTile(title: Text(order.orderNumber)));
                          },
                        ),

                  RefreshIndicator(
                    onRefresh: _fetchUserFeedback,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          color: Colors.white,
                          child: Column(
                            children: [
                              TextField(
                                controller: _feedbackController,
                                maxLines: 3,
                                decoration: InputDecoration(
                                  hintText: 'Write your message here...',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: _isLoading? null : _sendFeedback,
                                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryPurple),
                                child: const Text('Send Feedback'),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: _loadingFeedback
                         ? const Center(child: CircularProgressIndicator())
                            : _userFeedbacks.isEmpty
                           ? const Center(child: Text('No messages yet'))
                              : ListView.builder(
                                  reverse: false,
                                  padding: const EdgeInsets.all(12),
                                  itemCount: _userFeedbacks.length,
                                  itemBuilder: (context, index) {
                                    final fb = _userFeedbacks[index];
                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: Container(
                                            margin: const EdgeInsets.only(bottom: 4),
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: Colors.grey[300],
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Text("You: ${fb.message}"),
                                          ),
                                        ),
                                        if (fb.reply!= null && fb.reply!.isNotEmpty)
                                          Align(
                                            alignment: Alignment.centerRight,
                                            child: Container(
                                              margin: const EdgeInsets.only(left: 40, bottom: 10),
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: AppColors.primaryPurple,
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: Text(
                                                "Admin: ${fb.reply}",
                                                style: const TextStyle(color: Colors.white),
                                              ),
                                            ),
                                          ),
                                      ],
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),

                  ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Card(child: ListTile(title: Text(widget.customer!.name))),
                      ElevatedButton.icon(
                        onPressed: widget.onLogout,
                        icon: const Icon(Icons.logout),
                        label: const Text('Logout'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      ),
                    ],
                  ),

                  if (isAdmin)
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(children: [
                        TextField(controller: _prodName, decoration: const InputDecoration(labelText: 'Product Name')),
                        const SizedBox(height: 10),
                        _selectedImage == null
                       ? const Text('No image selected')
                          : Image.file(File(_selectedImage!.path), height: 150),
                        ElevatedButton(onPressed: _pickImage, child: const Text('Pick Image')),
                        ElevatedButton(onPressed: _addProduct, child: const Text('Add Product')),
                      ]),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _loginEmail.dispose();
    _loginPassword.dispose();
    _regName.dispose();
    _regEmail.dispose();
    _regPhone.dispose();
    _regAddress.dispose();
    _regPassword.dispose();
    _regConfirm.dispose();
    _feedbackController.dispose();
    _prodName.dispose();
    _prodPrice.dispose();
    _prodDesc.dispose();
    _prodCategory.dispose();
    _prodStock.dispose();
    super.dispose();
  }
}