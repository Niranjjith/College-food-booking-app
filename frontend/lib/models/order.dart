class Order {
  final String id;
  final double subtotal;
  final String status;
  final List<OrderItem> items;

  Order({required this.id, required this.subtotal, required this.status, required this.items});

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['_id'],
      subtotal: (json['subtotal'] as num).toDouble(),
      status: json['status'],
      items: (json['items'] as List).map((e) => OrderItem.fromJson(e)).toList(),
    );
  }
}

class OrderItem {
  final String name;
  final int qty;
  final double price;

  OrderItem({required this.name, required this.qty, required this.price});

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      name: json['name'],
      qty: json['qty'],
      price: (json['price'] as num).toDouble(),
    );
  }
}
