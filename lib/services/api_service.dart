import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://localhost:5000/api';
  
  static dynamic _handleResponse(http.Response response) {
    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json.decode(response.body);
    } else {
      return {'error': true, 'message': 'Server error: ${response.statusCode}'};
    }
  }
  
  // ==================== AUTH (POST) ====================
  static Future<Map<String, dynamic>> register(String name, String email, String password, {String? phone, String? address}) async {
    try {
      print('📝 Registering user: $email');
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': name,
          'email': email,
          'password': password,
          'phone': phone ?? '',
          'address': address ?? '',
        }),
      );
      return _handleResponse(response);
    } catch (e) {
      print('❌ Register error: $e');
      return {'error': true, 'message': 'Connection error: $e'};
    }
  }
  
  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      print('🔐 Logging in: $email');
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );
      return _handleResponse(response);
    } catch (e) {
      print('❌ Login error: $e');
      return {'error': true, 'message': 'Connection error: $e'};
    }
  }
  
  static Future<Map<String, dynamic>> adminLogin(String username, String password) async {
    try {
      print('👑 Admin login: $username');
      final response = await http.post(
        Uri.parse('$baseUrl/auth/admin-login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'username': username, 'password': password}),
      );
      return _handleResponse(response);
    } catch (e) {
      print('❌ Admin login error: $e');
      return {'error': true, 'message': 'Connection error: $e'};
    }
  }
  
  // ==================== PRODUCTS (POST, GET, PUT, DELETE) ====================
  static Future<List<dynamic>> getProducts() async {
    try {
      print('📦 Fetching products...');
      final response = await http.get(Uri.parse('$baseUrl/products'));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return [];
    } catch (e) {
      print('❌ Get products error: $e');
      return [];
    }
  }
  
  static Future<Map<String, dynamic>> createProduct(Map<String, dynamic> product) async {
    try {
      print('➕ Creating product: ${product['name']}');
      final response = await http.post(
        Uri.parse('$baseUrl/products'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(product),
      );
      return _handleResponse(response);
    } catch (e) {
      print('❌ Create product error: $e');
      return {'error': true, 'message': 'Connection error: $e'};
    }
  }
  
  static Future<Map<String, dynamic>> updateProduct(String id, Map<String, dynamic> product) async {
    try {
      print('✏️ Updating product: $id');
      final response = await http.put(
        Uri.parse('$baseUrl/products/$id'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(product),
      );
      return _handleResponse(response);
    } catch (e) {
      print('❌ Update product error: $e');
      return {'error': true, 'message': 'Connection error: $e'};
    }
  }
  
  static Future<void> deleteProduct(String id) async {
    try {
      print('🗑️ Deleting product: $id');
      await http.delete(Uri.parse('$baseUrl/products/$id'));
    } catch (e) {
      print('❌ Delete error: $e');
    }
  }
  
  // ==================== ORDERS (POST, GET, PUT) ====================
  static Future<Map<String, dynamic>> createOrder(Map<String, dynamic> order) async {
    try {
      print('📦 Creating order for: ${order['customerName']}');
      final response = await http.post(
        Uri.parse('$baseUrl/orders'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(order),
      );
      return _handleResponse(response);
    } catch (e) {
      print('❌ Create order error: $e');
      return {'error': true, 'message': 'Connection error: $e'};
    }
  }
  
  static Future<List<dynamic>> getUserOrders(String email) async {
    try {
      print('📋 Fetching orders for: $email');
      final response = await http.get(Uri.parse('$baseUrl/orders/my-orders?email=$email'));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return [];
    } catch (e) {
      print('❌ Get user orders error: $e');
      return [];
    }
  }
  
  static Future<List<dynamic>> getAllOrders() async {
    try {
      print('📋 Fetching all orders...');
      final response = await http.get(Uri.parse('$baseUrl/orders'));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return [];
    } catch (e) {
      print('❌ Get all orders error: $e');
      return [];
    }
  }
  
  static Future<Map<String, dynamic>> updateOrderStatus(String id, String status) async {
    try {
      print('🔄 Updating order $id status to: $status');
      final response = await http.put(
        Uri.parse('$baseUrl/orders/$id/status'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'orderStatus': status}),
      );
      return _handleResponse(response);
    } catch (e) {
      print('❌ Update order status error: $e');
      return {'error': true, 'message': 'Connection error: $e'};
    }
  }
  
  // ==================== FEEDBACK (POST, GET, PUT) ====================
  static Future<Map<String, dynamic>> createFeedback(Map<String, dynamic> feedback) async {
    try {
      print('💬 Sending feedback from: ${feedback['customerName']}');
      final response = await http.post(
        Uri.parse('$baseUrl/feedback'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(feedback),
      );
      return _handleResponse(response);
    } catch (e) {
      print('❌ Create feedback error: $e');
      return {'error': true, 'message': 'Connection error: $e'};
    }
  }
  
  static Future<List<dynamic>> getAllFeedback() async {
    try {
      print('💬 Fetching all feedback...');
      final response = await http.get(Uri.parse('$baseUrl/feedback'));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return [];
    } catch (e) {
      print('❌ Get all feedback error: $e');
      return [];
    }
  }
  
  static Future<Map<String, dynamic>> updateFeedback(String id, Map<String, dynamic> data) async {
    try {
      print('✏️ Updating feedback: $id');
      final response = await http.put(
        Uri.parse('$baseUrl/feedback/$id'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );
      return _handleResponse(response);
    } catch (e) {
      print('❌ Update feedback error: $e');
      return {'error': true, 'message': 'Connection error: $e'};
    }
  }

  // NEW: REPLY TO FEEDBACK
  static Future<Map<String, dynamic>> replyToFeedback(String feedbackId, String reply) async {
    try {
      print('💬 Replying to feedback: $feedbackId');
      final response = await http.put(
        Uri.parse('$baseUrl/feedback/$feedbackId/reply'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'reply': reply,
          'status': 'Replied',
        }),
      );
      return _handleResponse(response);
    } catch (e) {
      print('❌ Reply to feedback error: $e');
      return {'error': true, 'message': 'Connection error: $e'};
    }
  }
  
  // ==================== ADMIN (GET) ====================
  static Future<Map<String, dynamic>> getStats() async {
    try {
      print('📊 Fetching admin stats...');
      final response = await http.get(Uri.parse('$baseUrl/admin/stats'));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {};
    } catch (e) {
      print('❌ Get stats error: $e');
      return {};
    }
  }
  
  static Future<List<dynamic>> getCustomers() async {
    try {
      print('👥 Fetching customers...');
      final response = await http.get(Uri.parse('$baseUrl/admin/customers'));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return [];
    } catch (e) {
      print('❌ Get customers error: $e');
      return [];
    }
  }
}