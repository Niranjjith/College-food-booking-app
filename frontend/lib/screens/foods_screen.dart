import 'package:flutter/material.dart';
import '../models/food.dart';
import '../services/api_service.dart';
import '../services/offline_service.dart';
import '../widgets/food_card.dart';
import 'cart_screen.dart';
import 'voice_order_screen.dart';
import 'chatbot_screen.dart';

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
    try {
      final list = await ApiService.getFoods();
      setState(() {
        foods = list;
      });
      // Cache foods for offline mode
      await OfflineService.cacheFoods(list);
    } catch (e) {
      // If online fails, try loading from cache
      final cached = await OfflineService.getCachedFoods();
      if (cached.isNotEmpty) {
        setState(() {
          foods = cached;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Showing cached data. Check your connection."),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Nilgiri College",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF6B7280),
              ),
            ),
            const Text(
              "Food Menu",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.mic),
            tooltip: "Voice Order",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => VoiceOrderScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            tooltip: "AI Assistant",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ChatbotScreen()),
              );
            },
          ),
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
                  
                  // Footer
                  Container(
                    margin: const EdgeInsets.only(top: 32, bottom: 16),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF10B981).withOpacity(0.1),
                          const Color(0xFF059669).withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF10B981).withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.school,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "Nilgiri College",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF111827),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Food Booking System",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          width: 100,
                          height: 2,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF10B981),
                                const Color(0xFF059669),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Order your favorite meals with ease",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "© 2024 Nilgiri College. All rights reserved.",
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade400,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
