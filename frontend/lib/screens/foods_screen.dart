import 'package:flutter/material.dart';
import '../models/food.dart';
import '../services/api_service.dart';
import '../services/offline_service.dart';
import '../theme/app_colors.dart';
import '../widgets/food_card.dart';
import 'cart_screen.dart';
import 'chatbot_screen.dart';
import 'events_screen.dart';
import 'nutrition_screen.dart';
import 'subscription_screen.dart';
import 'voice_order_screen.dart';

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
  bool loading = true;
  String? userName;
  String greeting = "Good morning";
  String query = "";
  String selectedCategory = "All";
  double walletBalance = 0;
  int activeOrders = 0;
  final searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _updateGreeting();
    _loadDashboard();
  }

  @override
  void dispose() {
    searchCtrl.dispose();
    super.dispose();
  }

  void _updateGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      greeting = "Good morning";
    } else if (hour < 17) {
      greeting = "Good afternoon";
    } else {
      greeting = "Good evening";
    }
  }

  Future<void> _loadDashboard() async {
    setState(() => loading = true);
    await Future.wait([
      _loadUserProfile(),
      _loadFoods(),
      _loadRecommendations(),
      _loadTrending(),
      _loadStats(),
    ]);
    if (mounted) setState(() => loading = false);
  }

  Future<void> _loadUserProfile() async {
    final user = await ApiService.getProfile();
    if (user != null && mounted) {
      setState(() => userName = user.name);
    }
  }

  Future<void> _loadFoods() async {
    try {
      final list = await ApiService.getFoods();
      if (mounted) setState(() => foods = list);
      await OfflineService.cacheFoods(list);
    } catch (_) {
      final cached = await OfflineService.getCachedFoods();
      if (cached.isNotEmpty && mounted) setState(() => foods = cached);
    }
  }

  Future<void> _loadRecommendations() async {
    try {
      final list = await ApiService.getRecommendations();
      if (!mounted) return;
      setState(() {
        recommendations = list
            .where((item) => item['food'] != null)
            .map((item) => Food.fromJson(item['food'] as Map<String, dynamic>))
            .toList();
      });
    } catch (_) {}
  }

  Future<void> _loadTrending() async {
    try {
      final list = await ApiService.getTrendingFoods();
      if (!mounted) return;
      setState(() {
        trending = list.map((item) {
          final map = Map<String, dynamic>.from(item as Map);
          return Food.fromJson(Map<String, dynamic>.from(map['food'] ?? map));
        }).toList();
      });
    } catch (_) {}
  }

  Future<void> _loadStats() async {
    try {
      final wallet = await ApiService.getWallet();
      final orders = await ApiService.getMyOrders();
      if (!mounted) return;
      setState(() {
        walletBalance = (wallet?['balance'] as num?)?.toDouble() ?? 0;
        activeOrders = orders
            .where((o) => ['pending', 'paid', 'preparing', 'ready'].contains(o.status))
            .length;
      });
    } catch (_) {}
  }

  List<String> get categories {
    final set = <String>{};
    for (final food in foods) {
      if (food.category.isNotEmpty) set.add(food.category);
    }
    return ["All", ...set];
  }

  List<Food> get filteredFoods {
    return foods.where((food) {
      final matchesCategory = selectedCategory == "All" || food.category == selectedCategory;
      final q = query.trim().toLowerCase();
      final matchesQuery = q.isEmpty ||
          food.name.toLowerCase().contains(q) ||
          food.category.toLowerCase().contains(q) ||
          food.description.toLowerCase().contains(q);
      return matchesCategory && matchesQuery;
    }).toList();
  }

  List<Food> get featured {
    if (trending.isNotEmpty) return trending.take(8).toList();
    if (recommendations.isNotEmpty) return recommendations.take(8).toList();
    return foods.take(8).toList();
  }

  int get cartCount => cart.fold<int>(0, (sum, item) => sum + (item["qty"] as int));

  double get cartTotal => cart.fold<double>(
        0,
        (sum, item) => sum + ((item["qty"] as int) * (item["price"] as num).toDouble()),
      );

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
        content: Text("${food.name} added to cart"),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
    setState(() => cart.clear());
  }

  @override
  Widget build(BuildContext context) {
    final firstName = userName?.split(' ').first ?? "there";
    final width = MediaQuery.sizeOf(context).width;
    final horizontal = width > 900 ? (width - 880) / 2 : 20.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _loadDashboard,
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(horizontal, 12, horizontal, 0),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Header(
                        greeting: greeting,
                        firstName: firstName,
                        cartCount: cartCount,
                        onCart: _goToCart,
                      ),
                      const SizedBox(height: 18),
                      TextField(
                        controller: searchCtrl,
                        onChanged: (value) => setState(() => query = value),
                        decoration: InputDecoration(
                          hintText: "Search meals, snacks, drinks...",
                          prefixIcon: const Icon(Icons.search_rounded),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              label: "Wallet",
                              value: "₹${walletBalance.toStringAsFixed(0)}",
                              icon: Icons.account_balance_wallet_outlined,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _StatCard(
                              label: "Active orders",
                              value: "$activeOrders",
                              icon: Icons.receipt_long_outlined,
                              color: AppColors.accent,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _StatCard(
                              label: "Menu",
                              value: "${foods.length}",
                              icon: Icons.restaurant_outlined,
                              color: const Color(0xFF7C3AED),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        "Quick actions",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _ActionChip(
                            icon: Icons.event_available_outlined,
                            label: "Events",
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const EventsScreen()),
                            ),
                          ),
                          _ActionChip(
                            icon: Icons.mic_none_rounded,
                            label: "Voice order",
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => VoiceOrderScreen()),
                            ),
                          ),
                          _ActionChip(
                            icon: Icons.smart_toy_outlined,
                            label: "AI help",
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => ChatbotScreen()),
                            ),
                          ),
                          _ActionChip(
                            icon: Icons.monitor_heart_outlined,
                            label: "Nutrition",
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const NutritionScreen()),
                            ),
                          ),
                          _ActionChip(
                            icon: Icons.calendar_month_outlined,
                            label: "Meal plans",
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (categories.length > 1)
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 52,
                    child: ListView.separated(
                      padding: EdgeInsets.fromLTRB(horizontal, 16, horizontal, 0),
                      scrollDirection: Axis.horizontal,
                      itemCount: categories.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final category = categories[i];
                        final selected = category == selectedCategory;
                        return ChoiceChip(
                          label: Text(category),
                          selected: selected,
                          onSelected: (_) => setState(() => selectedCategory = category),
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(
                            color: selected ? Colors.white : AppColors.ink,
                            fontWeight: FontWeight.w600,
                          ),
                          backgroundColor: Colors.white,
                          side: BorderSide.none,
                          showCheckmark: false,
                        );
                      },
                    ),
                  ),
                ),
              if (featured.isNotEmpty && query.isEmpty && selectedCategory == "All")
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(horizontal, 22, horizontal, 12),
                        child: const Text(
                          "Today's specials",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 196,
                        child: ListView.separated(
                          padding: EdgeInsets.symmetric(horizontal: horizontal),
                          scrollDirection: Axis.horizontal,
                          itemCount: featured.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 12),
                          itemBuilder: (_, i) {
                            final food = featured[i];
                            return FeaturedFoodCard(food: food, onAdd: () => _addToCart(food));
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(horizontal, 22, horizontal, cart.isEmpty ? 28 : 108),
                sliver: loading
                    ? const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.only(top: 48),
                          child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                        ),
                      )
                    : filteredFoods.isEmpty
                        ? const SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.only(top: 48),
                              child: Column(
                                children: [
                                  Icon(Icons.ramen_dining_outlined, size: 56, color: AppColors.muted),
                                  SizedBox(height: 12),
                                  Text(
                                    "No dishes match that search",
                                    style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : SliverList.separated(
                            itemCount: filteredFoods.length + 1,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (_, i) {
                              if (i == 0) {
                                return const Text(
                                  "Campus menu",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.ink,
                                  ),
                                );
                              }
                              final food = filteredFoods[i - 1];
                              return FoodCard(food: food, onAdd: () => _addToCart(food));
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: cart.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Material(
                  color: AppColors.ink,
                  borderRadius: BorderRadius.circular(18),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: _goToCart,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              "$cartCount",
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            "View cart",
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
                          ),
                          const Spacer(),
                          Text(
                            "₹${cartTotal.toStringAsFixed(0)}",
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.greeting,
    required this.firstName,
    required this.cartCount,
    required this.onCart,
  });

  final String greeting;
  final String firstName;
  final int cartCount;
  final VoidCallback onCart;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  "$firstName, hungry?",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Nilgiri College kitchen · skip the queue",
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onCart,
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.18),
              foregroundColor: Colors.white,
            ),
            icon: Badge(
              isLabelVisible: cartCount > 0,
              label: Text("$cartCount"),
              child: const Icon(Icons.shopping_bag_outlined),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.ink),
          ),
          Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.ink)),
            ],
          ),
        ),
      ),
    );
  }
}
