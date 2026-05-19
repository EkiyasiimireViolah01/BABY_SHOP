class Product {
  String id;
  String name;
  double price;
  String image;
  String category;
  String description;
  int stock;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.image,
    required this.category,
    required this.description,
    required this.stock,
  });

  Map<String, dynamic> toJson() => {
    '_id': id, // Correct for MongoDB
    'name': name,
    'price': price,
    'image': image,
    'category': category,
    'description': description,
    'stock': stock,
  };

  factory Product.fromJson(Map<String, dynamic> json) => Product(
    id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
    price: (json['price'] ?? 0).toDouble(),
    image: json['image']?.toString() ?? '',
    category: json['category']?.toString() ?? '',
    description: json['description']?.toString() ?? '',
    stock: (json['stock'] ?? 0).toInt(),
  );
}