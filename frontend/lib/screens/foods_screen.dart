import 'package:flutter/material.dart';
import '../models/food.dart';
import '../services/api_service.dart';
import '../services/offline_service.dart';
import '../widgets/food_card.dart';
import 'cart_screen.dart';
import 'voice_order_screen.dart';
import 'chatbot_screen.dart';
import 'events_screen.dart';

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
  String? userName;
  String greeting = "Good Morning";

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadFoods();
    _loadRecommendations();
    _loadTrending();
    _updateGreeting();
  }

  void _updateGreeting() {
    final hour = DateTime.now().hour;
    setState(() {
      if (hour < 12) {
        greeting = "Good Morning";
      } else if (hour < 17) {
        greeting = "Good Afternoon";
      } else {
        greeting = "Good Evening";
      }
    });
  }

  void _loadUserProfile() async {
    final user = await ApiService.getProfile();
    if (user != null) {
      setState(() {
        userName = user.name;
      });
    }
  }

  void _loadFoods() async {
    try {
      final list = await ApiService.getFoods();
      setState(() {
        foods = list;
      });
      await OfflineService.cacheFoods(list);
    } catch (e) {
      final cached = await OfflineService.getCachedFoods();
      if (cached.isNotEmpty) {
        setState(() {
          foods = cached;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Showing cached data. Check your connection."),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    }
  }

  void _loadRecommendations() async {
    try {
      final list = await ApiService.getRecommendations();
      setState(() {
        recommendations = list.map((item) => Food.fromJson(item['food'])).toList();
      });
    } catch (e) {
      // Silent fail
    }
  }

  void _loadTrending() async {
    try {
      final list = await ApiService.getTrendingFoods();
      setState(() {
        trending = list.map((item) => Food.fromJson(item)).toList();
      });
    } catch (e) {
      // Silent fail
    }
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
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text("${food.name} added to cart"),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
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
      body: CustomScrollView(
        slivers: [
          // Premium Welcome Header
          SliverAppBar(
            expandedHeight: 220,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF10B981),
                      const Color(0xFF059669),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    greeting,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.white70,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    userName != null ? "Welcome, ${userName!.split(' ').first}!" : "Welcome!",
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: -0.5,
                                      height: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Row(
                                    children: [
                                      Icon(Icons.school, color: Colors.white70, size: 16),
                                      SizedBox(width: 6),
                                      Text(
                                        "Nilgiri College",
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.white70,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.restaurant_menu,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.event, color: Colors.white),
                tooltip: "Campus Events",
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const EventsScreen()),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.mic, color: Colors.white),
                tooltip: "Voice Order",
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => VoiceOrderScreen()),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
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
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      onPressed: _goToCart,
                      icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
                    ),
                  ),
                  if (cart.isNotEmpty)
                    Positioned(
                      right: 4,
                      top: 4,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: const BoxDecoration(
                          color: Color(0xFFEF4444),
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 22,
                          minHeight: 22,
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

          // Quick Actions
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 16),
              height: 100,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildQuickAction(
                    icon: Icons.event,
                    label: "Events",
                    color: Colors.purple,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const EventsScreen()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _buildQuickAction(
                    icon: Icons.mic,
                    label: "Voice",
                    color: Colors.blue,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => VoiceOrderScreen()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _buildQuickAction(
                    icon: Icons.chat_bubble,
                    label: "AI Chat",
                    color: Colors.orange,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ChatbotScreen()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _buildQuickAction(
                    icon: Icons.trending_up,
                    label: "Trending",
                    color: Colors.red,
                    onTap: () {
                      // Scroll to trending
                    },
                  ),
                ],
              ),
            ),
          ),

          // Content
          foods.isEmpty
              ? SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.restaurant_menu,
                          size: 80,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "No foods available",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Check back later for delicious meals",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Recommendations Section
                      if (recommendations.isNotEmpty && showRecommendations) ...[
                        _buildSectionHeader(
                          icon: Icons.star,
                          title: "Recommended for You",
                          onHide: () {
                            setState(() {
                              showRecommendations = false;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        ...recommendations.map((food) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: FoodCard(
                                food: food,
                                onAdd: () => _addToCart(food),
                              ),
                            )),
                        const SizedBox(height: 24),
                      ],

                      // Trending Section
                      if (trending.isNotEmpty) ...[
                        _buildSectionHeader(
                          icon: Icons.trending_up,
                          title: "Trending Now",
                        ),
                        const SizedBox(height: 12),
                        ...trending.take(3).map((food) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: FoodCard(
                                food: food,
                                onAdd: () => _addToCart(food),
                              ),
                            )),
                        const SizedBox(height: 24),
                      ],

                      // All Foods Section
                      _buildSectionHeader(
                        icon: Icons.restaurant_menu,
                        title: "All Items",
                      ),
                      const SizedBox(height: 12),
                      ...foods.map((food) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: FoodCard(
                              food: food,
                              onAdd: () => _addToCart(food),
                            ),
                          )),

                      // Premium Footer
                      const SizedBox(height: 32),
                      _buildPremiumFooter(),
                      const SizedBox(height: 24),
                    ]),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 90,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.1),
              color.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: color.withOpacity(0.2),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    VoidCallback? onHide,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF10B981), size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
            letterSpacing: -0.5,
          ),
        ),
        const Spacer(),
        if (onHide != null)
          TextButton(
            onPressed: onHide,
            child: const Text(
              "Hide",
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPremiumFooter() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF10B981).withOpacity(0.08),
            const Color(0xFF059669).withOpacity(0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF10B981).withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF059669)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF10B981).withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(
              Icons.school,
              color: Colors.white,
              size: 36,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "Nilgiri College",
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Food Booking System",
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: 120,
            height: 3,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF059669)],
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "Order your favorite meals with ease",
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
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
    );
  }
}
