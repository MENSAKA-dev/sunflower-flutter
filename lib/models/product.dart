class Product {
  final int id;
  final String name;
  final String? description;
  final double price;
  final int stock;
  final String? category;

  const Product({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    required this.stock,
    this.category,
  });

  factory Product.fromJson(Map<String, dynamic> j) => Product(
    id:          j['id'] as int,
    name:        j['name'] as String,
    description: j['description'] as String?,
    price:       double.tryParse(j['price'].toString()) ?? 0,
    stock:       int.tryParse(j['stock'].toString()) ?? 0,
    category:    j['category'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'name':        name,
    'description': description,
    'price':       price,
    'stock':       stock,
    'category':    category,
  };
}
