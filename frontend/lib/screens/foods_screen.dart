import 'package:flutter/material.dart';
import '../models/food.dart';
import '../services/api_service.dart';
import '../widgets/food_card.dart';
import 'cart_screen.dart';

class FoodsScreen extends StatefulWidget {
  const FoodsScreen({super.key});

  @override
  State<FoodsScreen> createState() => _FoodsScreenState();
}

class _FoodsScreenState extends State<FoodsScreen> {
  List<Food> foods = [];
  List<Map<String, dynamic>> cart = [];

  @override
  void initState() {
    super.initState();
    _loadFoods();
  }

  void _loadFoods() async {
    final list = await ApiService.getFoods();
    setState(() {
      foods = list;
    });
  }

  void _addToCart(Food food) {
    setState(() {
      final index = cart.indexWhere((item) => item["foodId"] == food.id);
      if (index >= 0) {
        cart[index]["qty"] += 1;
      } else {
        cart.add({"foodId": food.id, "name": food.name, "qty": 1, "price": food.price});
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("${food.name} added to cart")),
    );
  }

  void _goToCart() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CartScreen(cartItems: cart, onOrderPlaced: _clearCart),
      ),
    );
  }

  void _clearCart() {
    setState(() {
      cart.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Menu"),
        actions: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: _goToCart,
                  icon: const Icon(Icons.shopping_cart_outlined),
                  color: const Color(0xFF10B981),
                ),
              ),
              if (cart.isNotEmpty)
                Positioned(
                  right: 4,
                  top: 4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFFEF4444),
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 20,
                      minHeight: 20,
                    ),
                    child: Center(
                      child: Text(
                        "${cart.length}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: foods.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.restaurant_menu,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "No foods available",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: foods.length,
              itemBuilder: (_, i) {
                final food = foods[i];
                return FoodCard(food: food, onAdd: () => _addToCart(food));
              },
            ),
    );
  }
}
