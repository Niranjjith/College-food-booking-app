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
  List<Food> recommendations = [];
  List<Food> trending = [];
  List<Map<String, dynamic>> cart = [];
  bool showRecommendations = true;

  @override
  void initState() {
    super.initState();
    _loadFoods();
    _loadRecommendations();
    _loadTrending();
  }

  void _loadFoods() async {
    final list = await ApiService.getFoods();
    setState(() {
      foods = list;
    });
  }

  void _loadRecommendations() async {
    final list = await ApiService.getRecommendations();
    setState(() {
      recommendations = list.map((item) => Food.fromJson(item['food'])).toList();
    });
  }

  void _loadTrending() async {
    final list = await ApiService.getTrendingFoods();
    setState(() {
      trending = list.map((item) => Food.fromJson(item)).toList();
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
          : RefreshIndicator(
              onRefresh: () async {
                _loadFoods();
                _loadRecommendations();
                _loadTrending();
              },
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  // Recommendations Section
                  if (recommendations.isNotEmpty && showRecommendations) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.star, color: Color(0xFF10B981), size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            "Recommended for You",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF111827),
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                showRecommendations = false;
                              });
                            },
                            child: const Text("Hide"),
                          ),
                        ],
                      ),
                    ),
                    ...recommendations.map((food) => FoodCard(
                          food: food,
                          onAdd: () => _addToCart(food),
                        )),
                    const SizedBox(height: 16),
                  ],
                  
                  // Trending Section
                  if (trending.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.trending_up, color: Color(0xFF10B981), size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            "Trending Now",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF111827),
                            ),
                          ),
                        ],
                      ),
                    ),
                    ...trending.take(3).map((food) => FoodCard(
                          food: food,
                          onAdd: () => _addToCart(food),
                        )),
                    const SizedBox(height: 16),
                  ],
                  
                  // All Foods Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: const Text(
                      "All Items",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ),
                  ...foods.map((food) => FoodCard(
                        food: food,
                        onAdd: () => _addToCart(food),
                      )),
                ],
              ),
            ),
    );
  }
}
