import 'package:babyshop_products/screens/main_home_page.dart';
import 'package:flutter/material.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BabyShopApp());
}

class BabyShopApp extends StatelessWidget {
  const BabyShopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BabyShop',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.purple,
        primaryColor: const Color(0xFF6a1b9a),
      ),
      home: const MainHomePage(),
    );
  }
}