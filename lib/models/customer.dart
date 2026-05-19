class Customer {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String address;

  Customer({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'phone': phone,
    'address': address,
  };

  factory Customer.fromJson(Map<String, dynamic> json) => Customer(
    id: json['_id']?? json['id']?? '',
    name: json['name']?? json['customerName']?? '',
    email: json['email']?? json['customerEmail']?? '',
    phone: json['phone']?? '',
    address: json['address']?? json['location']?? '',
  );
}