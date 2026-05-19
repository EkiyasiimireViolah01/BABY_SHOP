import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product.dart';
import '../models/order.dart';
import '../models/feedback_message.dart';
import '../models/customer.dart';
import '../models/cart_item.dart';
import '../utils/constants.dart';

class StorageService {
  // ==================== PRODUCTS ====================
  static Future<void> saveProducts(List<Product> products) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> productJson = products.map((p) => json.encode(p.toJson())).toList();
      await prefs.setStringList(AppConstants.productsKey, productJson);
      print('✅ Products saved: ${products.length} items');
    } catch (e) {
      print('❌ Error saving products: $e');
    }
  }

  static Future<List<Product>> loadProducts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String>? productJson = prefs.getStringList(AppConstants.productsKey);
      if (productJson == null || productJson.isEmpty) {
        print('⚠️ No products found in storage');
        return [];
      }
      final products = productJson.map((jsonStr) => Product.fromJson(json.decode(jsonStr))).toList();
      print('✅ Products loaded: ${products.length} items');
      return products;
    } catch (e) {
      print('❌ Error loading products: $e');
      return [];
    }
  }

  // ==================== ORDERS ====================
  static Future<void> saveOrders(List<Order> orders) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> orderJson = orders.map((o) => json.encode(o.toJson())).toList();
      await prefs.setStringList(AppConstants.ordersKey, orderJson);
      print('✅ Orders saved: ${orders.length} items');
      if (orders.isNotEmpty) {
        for (var order in orders) {
          print('   📦 Order: ${order.orderNumber} - ${order.customerName} - UGX ${order.totalAmount}');
        }
      }
    } catch (e) {
      print('❌ Error saving orders: $e');
    }
  }

  static Future<List<Order>> loadOrders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String>? orderJson = prefs.getStringList(AppConstants.ordersKey);
      if (orderJson == null || orderJson.isEmpty) {
        print('⚠️ No orders found in storage');
        return [];
      }
      final orders = orderJson.map((jsonStr) => Order.fromJson(json.decode(jsonStr))).toList();
      print('✅ Orders loaded: ${orders.length} items');
      for (var order in orders) {
        print('   📦 Order: ${order.orderNumber} - ${order.customerName}');
      }
      return orders;
    } catch (e) {
      print('❌ Error loading orders: $e');
      return [];
    }
  }

  // ==================== FEEDBACKS / MESSAGES ====================
  static Future<void> saveFeedbacks(List<FeedbackMessage> feedbacks) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> feedbackJson = feedbacks.map((f) => json.encode(f.toJson())).toList();
      await prefs.setStringList(AppConstants.feedbacksKey, feedbackJson);
      print('✅ Feedbacks/Messages saved: ${feedbacks.length} items');
      if (feedbacks.isNotEmpty) {
        for (var feedback in feedbacks) {
          print('   💬 Feedback: ${feedback.customerName} - ${feedback.message.substring(0, feedback.message.length > 30 ? 30 : feedback.message.length)}...');
        }
      }
    } catch (e) {
      print('❌ Error saving feedbacks: $e');
    }
  }

  static Future<List<FeedbackMessage>> loadFeedbacks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String>? feedbackJson = prefs.getStringList(AppConstants.feedbacksKey);
      if (feedbackJson == null || feedbackJson.isEmpty) {
        print('⚠️ No feedbacks found in storage');
        return [];
      }
      final feedbacks = feedbackJson.map((jsonStr) => FeedbackMessage.fromJson(json.decode(jsonStr))).toList();
      print('✅ Feedbacks loaded: ${feedbacks.length} items');
      return feedbacks;
    } catch (e) {
      print('❌ Error loading feedbacks: $e');
      return [];
    }
  }

  // ==================== CUSTOMERS ====================
  static Future<void> saveCurrentCustomer(Customer? customer) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (customer == null) {
        await prefs.remove(AppConstants.currentCustomerKey);
        print('✅ Customer removed from storage');
      } else {
        await prefs.setString(AppConstants.currentCustomerKey, json.encode(customer.toJson()));
        print('✅ Customer saved: ${customer.name} (${customer.email})');
      }
    } catch (e) {
      print('❌ Error saving customer: $e');
    }
  }

  static Future<Customer?> loadCurrentCustomer() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? customerJson = prefs.getString(AppConstants.currentCustomerKey);
      if (customerJson == null) {
        print('⚠️ No customer found in storage');
        return null;
      }
      final customer = Customer.fromJson(json.decode(customerJson));
      print('✅ Customer loaded: ${customer.name} (${customer.email})');
      return customer;
    } catch (e) {
      print('❌ Error loading customer: $e');
      return null;
    }
  }

  // ==================== CART ====================
  static Future<void> saveCartItems(List<CartItem> cartItems) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> cartJson = cartItems.map((c) => json.encode(c.toJson())).toList();
      await prefs.setStringList(AppConstants.cartItemsKey, cartJson);
      print('✅ Cart items saved: ${cartItems.length} items');
    } catch (e) {
      print('❌ Error saving cart items: $e');
    }
  }

  static Future<List<CartItem>> loadCartItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String>? cartJson = prefs.getStringList(AppConstants.cartItemsKey);
      if (cartJson == null || cartJson.isEmpty) {
        print('⚠️ No cart items found in storage');
        return [];
      }
      final cartItems = cartJson.map((jsonStr) => CartItem.fromJson(json.decode(jsonStr))).toList();
      print('✅ Cart items loaded: ${cartItems.length} items');
      return cartItems;
    } catch (e) {
      print('❌ Error loading cart items: $e');
      return [];
    }
  }

  // ==================== CLEAR ALL DATA ====================
  static Future<void> clearAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.productsKey);
      await prefs.remove(AppConstants.ordersKey);
      await prefs.remove(AppConstants.feedbacksKey);
      await prefs.remove(AppConstants.currentCustomerKey);
      await prefs.remove(AppConstants.cartItemsKey);
      print('✅ All data cleared from storage');
    } catch (e) {
      print('❌ Error clearing data: $e');
    }
  }
}