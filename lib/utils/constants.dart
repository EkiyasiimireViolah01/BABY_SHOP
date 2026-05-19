import 'package:flutter/material.dart';

class AppColors {
  static const Color primaryPurple = Color(0xFF6a1b9a);
  static const Color lightPurple = Color(0xFF9c4dcc);
  static const Color darkPurple = Color(0xFF38006b);
  static const Color accentPurple = Color(0xFFe1bee7);
  static const Color successGreen = Color(0xFF4caf50);
  static const Color warningOrange = Color(0xFFff9800);
  static const Color errorRed = Color(0xFFf44336);
  static const Color infoBlue = Color(0xFF2196f3);
}

class AppConstants {
  // API Base URL - ADD THIS
  static const String baseUrl = 'http://localhost:5000';
  
  // API Endpoints - ADD THESE TOO
  static const String registerEndpoint = '/api/auth/register';
  static const String loginEndpoint = '/api/auth/login';
  static const String productsEndpoint = '/api/products';
  static const String ordersEndpoint = '/api/orders';
  
  // Admin Credentials
  static const String adminEmail = 'admin@babyshop.com';
  static const String adminPassword = 'admin1234';
  
  // Storage Keys
  static const String productsKey = 'babyshop_products';
  static const String ordersKey = 'babyshop_orders';
  static const String feedbacksKey = 'babyshop_feedbacks';
  static const String currentCustomerKey = 'babyshop_current_customer';
  static const String cartItemsKey = 'babyshop_cart_items';
  static const String tokenKey = 'babyshop_token';
}

class AppStrings {
  static const String appName = 'BabyShop';
  static const String tagline = 'Your One-Stop Baby Store';
}