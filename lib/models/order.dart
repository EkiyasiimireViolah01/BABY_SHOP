import 'cart_item.dart';
import 'product.dart';

class Order {
  final String id;
  final String orderNumber;
  final List<CartItem> items;
  final double totalAmount;
  String status;
  final String date;
  final String phone;
  final String location;
  final String paymentMethod;
  final String customerName;
  final String customerEmail;

  Order({
    required this.id,
    required this.orderNumber,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.date,
    required this.phone,
    required this.location,
    required this.paymentMethod,
    required this.customerName,
    required this.customerEmail,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'orderNumber': orderNumber,
    'items': items.map((i) => i.toJson()).toList(),
    'totalAmount': totalAmount,
    'status': status,
    'date': date,
    'phone': phone,
    'location': location,
    'paymentMethod': paymentMethod,
    'customerName': customerName,
    'customerEmail': customerEmail,
  };

  factory Order.fromJson(Map<String, dynamic> json) => Order(
    id: json['_id']?? json['id']?? '',
    orderNumber: json['orderNumber']?? '',
    items: (json['items'] as List? ?? []).map((item) {
      return CartItem(
        product: Product(
          id: item['productId']?? '',
          name: item['name']?? 'Unknown Product',
          price: (item['price']?? 0).toDouble(),
          image: item['image']?? '',
          category: item['category']?? 'General',
          description: item['description']?? '',
          stock: item['stock']?? 0,
        ),
        quantity: item['quantity']?? 1,
      );
    }).toList(),
    totalAmount: (json['totalAmount']?? 0).toDouble(),
    status: json['status']?? json['orderStatus']?? 'Pending',
    date: json['date']?? json['createdAt']?? '',
    phone: json['phone']?? '',
    location: json['location']?? '',
    paymentMethod: json['paymentMethod']?? '',
    customerName: json['customerName']?? '',
    customerEmail: json['customerEmail']?? '',
  );
}