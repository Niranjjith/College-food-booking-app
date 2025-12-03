class Order {
  final String id;
  final double subtotal;
  final String status;
  final List<OrderItem> items;
  final String createdAt;
  final String? pickupCode;
  final Map<String, dynamic>? preparation;

  Order({
    required this.id,
    required this.subtotal,
    required this.status,
    required this.items,
    required this.createdAt,
    this.pickupCode,
    this.preparation,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['_id'] ?? json['id'] ?? '',
      subtotal: (json['subtotal'] as num).toDouble(),
      status: json['status'] ?? 'pending',
      items: (json['items'] as List).map((e) => OrderItem.fromJson(e)).toList(),
      createdAt: json['createdAt'] ?? DateTime.now().toIso8601String(),
      pickupCode: json['pickupCode'],
      preparation: json['preparation'] != null 
          ? Map<String, dynamic>.from(json['preparation']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'subtotal': subtotal,
      'status': status,
      'items': items.map((e) => e.toJson()).toList(),
      'createdAt': createdAt,
      'pickupCode': pickupCode,
      'preparation': preparation,
    };
  }
}

class OrderItem {
  final String name;
  final int qty;
  final double price;

  OrderItem({required this.name, required this.qty, required this.price});

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      name: json['name'] ?? '',
      qty: json['qty'] ?? 1,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'qty': qty,
      'price': price,
    };
  }
}
