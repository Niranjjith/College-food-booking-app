import 'package:flutter/material.dart';
import '../models/food.dart';
import '../services/api_service.dart';
import '../models/user.dart';

class NutritionScreen extends StatefulWidget {
  const NutritionScreen({super.key});

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> {
  User? _user;
  Map<String, double> _dailyTotals = {};
  Map<String, double> _goals = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    final user = await ApiService.getProfile();
    setState(() {
      _user = user;
      if (user?.dietaryGoals != null) {
        _goals = {
          'calories': user!.dietaryGoals!['dailyCalories']?.toDouble() ?? 2000,
          'protein': user.dietaryGoals!['protein']?.toDouble() ?? 50,
          'carbs': user.dietaryGoals!['carbs']?.toDouble() ?? 250,
          'fats': user.dietaryGoals!['fats']?.toDouble() ?? 65,
        };
      } else {
        _goals = {
          'calories': 2000,
          'protein': 50,
          'carbs': 250,
          'fats': 65,
        };
      }
      _loading = false;
    });
    _calculateDailyTotals();
  }

  void _calculateDailyTotals() async {
    // Get today's orders and calculate nutrition totals
    final orders = await ApiService.getMyOrders();
    final today = DateTime.now();
    double calories = 0, protein = 0, carbs = 0, fats = 0;

    for (var order in orders) {
      final orderDate = DateTime.parse(order.createdAt);
      if (orderDate.year == today.year &&
          orderDate.month == today.month &&
          orderDate.day == today.day) {
        // Calculate nutrition from order items
        // This would require fetching food details with nutrition info
        // For now, we'll show a placeholder
      }
    }

    setState(() {
      _dailyTotals = {
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fats': fats,
      };
    });
  }

  void _showSetGoalsDialog() {
    final caloriesCtrl = TextEditingController(
      text: _goals['calories']?.toStringAsFixed(0) ?? '2000',
    );
    final proteinCtrl = TextEditingController(
      text: _goals['protein']?.toStringAsFixed(0) ?? '50',
    );
    final carbsCtrl = TextEditingController(
      text: _goals['carbs']?.toStringAsFixed(0) ?? '250',
    );
    final fatsCtrl = TextEditingController(
      text: _goals['fats']?.toStringAsFixed(0) ?? '65',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Set Dietary Goals"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: caloriesCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Daily Calories (kcal)",
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: proteinCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Protein (g)",
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: carbsCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Carbs (g)",
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: fatsCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Fats (g)",
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final success = await ApiService.updateDietaryGoals({
                'dailyCalories': double.tryParse(caloriesCtrl.text) ?? 2000,
                'protein': double.tryParse(proteinCtrl.text) ?? 50,
                'carbs': double.tryParse(carbsCtrl.text) ?? 250,
                'fats': double.tryParse(fatsCtrl.text) ?? 65,
              });
              if (success) {
                _loadData();
                Navigator.pop(context);
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionCard(String label, String unit, double current, double goal, Color color) {
    final percentage = goal > 0 ? (current / goal * 100).clamp(0, 100) : 0;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  "${current.toStringAsFixed(0)} / ${goal.toStringAsFixed(0)} $unit",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: percentage / 100,
                minHeight: 8,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "${percentage.toStringAsFixed(0)}%",
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Nutrition Tracker"),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _showSetGoalsDialog,
            tooltip: "Set Goals",
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Daily Summary Card
            Card(
              color: const Color(0xFF10B981).withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text(
                      "Today's Nutrition",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      DateTime.now().toString().split(' ')[0],
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Calories
            _buildNutritionCard(
              "Calories",
              "kcal",
              _dailyTotals['calories'] ?? 0,
              _goals['calories'] ?? 2000,
              Colors.orange,
            ),
            const SizedBox(height: 16),

            // Protein
            _buildNutritionCard(
              "Protein",
              "g",
              _dailyTotals['protein'] ?? 0,
              _goals['protein'] ?? 50,
              Colors.blue,
            ),
            const SizedBox(height: 16),

            // Carbs
            _buildNutritionCard(
              "Carbs",
              "g",
              _dailyTotals['carbs'] ?? 0,
              _goals['carbs'] ?? 250,
              Colors.purple,
            ),
            const SizedBox(height: 16),

            // Fats
            _buildNutritionCard(
              "Fats",
              "g",
              _dailyTotals['fats'] ?? 0,
              _goals['fats'] ?? 65,
              Colors.green,
            ),
            const SizedBox(height: 24),

            // Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        const Text(
                          "Nutrition Info",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Track your daily nutrition intake from ordered meals. "
                      "Set your dietary goals to monitor your progress throughout the day.",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


