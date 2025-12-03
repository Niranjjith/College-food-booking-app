import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/food.dart';
import 'package:intl/intl.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  List<dynamic> subscriptions = [];
  List<Food> foods = [];
  bool loading = true;
  bool showCreateForm = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    setState(() => loading = true);
    final subs = await ApiService.getMySubscriptions();
    final foodsList = await ApiService.getFoods();
    setState(() {
      subscriptions = subs;
      foods = foodsList;
      loading = false;
    });
  }

  void _createSubscription() {
    // Simplified - in real app, would have full form
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Create Subscription"),
        content: const Text("Select items and schedule for weekly meal plan"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Subscription feature coming soon")),
              );
            },
            child: const Text("Create"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Meal Plans"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _createSubscription,
            tooltip: "Create Subscription",
          ),
        ],
      ),
      body: subscriptions.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_today, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    "No active meal plans",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Create a subscription to pre-book meals",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _createSubscription,
                    icon: const Icon(Icons.add),
                    label: const Text("Create Meal Plan"),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: subscriptions.length,
              itemBuilder: (context, index) {
                final sub = subscriptions[index];
                final startDate = DateTime.parse(sub['startDate']);
                final endDate = DateTime.parse(sub['endDate']);
                final status = sub['status'] ?? 'active';

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            sub['name'] ?? 'Weekly Meal Plan',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF111827),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: status == 'active'
                                  ? const Color(0xFF10B981).withOpacity(0.1)
                                  : Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: status == 'active'
                                    ? const Color(0xFF10B981)
                                    : Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "${DateFormat('MMM dd').format(startDate)} - ${DateFormat('MMM dd, yyyy').format(endDate)}",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      if (sub['pickupTime'] != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.access_time, size: 16, color: Color(0xFF10B981)),
                            const SizedBox(width: 4),
                            Text(
                              "Pickup: ${sub['pickupTime']}",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 12),
                      const Text(
                        "Items:",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...(sub['items'] as List).map((item) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF10B981),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    "${item['name']} × ${item['qty']}",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ),
                                Text(
                                  "₹${(item['price'] * item['qty']).toStringAsFixed(2)}",
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          )),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Total: ₹${sub['totalPrice'].toStringAsFixed(2)}",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF111827),
                            ),
                          ),
                          if (status == 'active')
                            TextButton(
                              onPressed: () async {
                                final success = await ApiService.cancelSubscription(sub['_id']);
                                if (success) {
                                  _loadData();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Subscription cancelled"),
                                      backgroundColor: Color(0xFF10B981),
                                    ),
                                  );
                                }
                              },
                              child: const Text("Cancel"),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

