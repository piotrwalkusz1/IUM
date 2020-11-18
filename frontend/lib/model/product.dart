class Product {
  final String id;
  String name;
  String manufacturer;
  double price;
  int quantity;

  Product({this.id, this.name, this.manufacturer, this.price, this.quantity});

  Product.copy(Product product)
      : this.id = product.id,
        this.name = product.name,
        this.manufacturer = product.manufacturer,
        this.price = product.price,
        this.quantity = product.quantity;

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      manufacturer: json['manufacturer'] as String,
      price: json['price'].toDouble(),
      quantity: json['quantity'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'manufacturer': manufacturer,
      'price': price,
      'quantity': quantity
    };
  }
}
