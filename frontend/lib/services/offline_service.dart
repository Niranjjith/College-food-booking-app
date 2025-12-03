import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/food.dart';
import '../models/order.dart';

class OfflineService {
  static const String _foodsKey = 'cached_foods';
  static const String _cartKey = 'cached_cart';
  static const String _ordersKey = 'cached_orders';
  static const String _pendingOrdersKey = 'pending_orders';
  static const String _lastSyncKey = 'last_sync';

  // Cache foods
  static Future<void> cacheFoods(List<Food> foods) async {
    final prefs = await SharedPreferences.getInstance();
    final foodsJson = foods.map((f) => f.toJson()).toList();
    await prefs.setString(_foodsKey, jsonEncode(foodsJson));
    await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());
  }

  // Get cached foods
  static Future<List<Food>> getCachedFoods() async {
    final prefs = await SharedPreferences.getInstance();
    final foodsJson = prefs.getString(_foodsKey);
    if (foodsJson != null) {
      final List<dynamic> decoded = jsonDecode(foodsJson);
      return decoded.map((json) => Food.fromJson(json)).toList();
    }
    return [];
  }

  // Cache cart
  static Future<void> cacheCart(List<Map<String, dynamic>> cartItems) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cartKey, jsonEncode(cartItems));
  }

  // Get cached cart
  static Future<List<Map<String, dynamic>>> getCachedCart() async {
    final prefs = await SharedPreferences.getInstance();
    final cartJson = prefs.getString(_cartKey);
    if (cartJson != null) {
      return List<Map<String, dynamic>>.from(jsonDecode(cartJson));
    }
    return [];
  }

  // Cache orders
  static Future<void> cacheOrders(List<Order> orders) async {
    final prefs = await SharedPreferences.getInstance();
    final ordersJson = orders.map((o) => o.toJson()).toList();
    await prefs.setString(_ordersKey, jsonEncode(ordersJson));
  }

  // Get cached orders
  static Future<List<Order>> getCachedOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final ordersJson = prefs.getString(_ordersKey);
    if (ordersJson != null) {
      final List<dynamic> decoded = jsonDecode(ordersJson);
      return decoded.map((json) => Order.fromJson(json)).toList();
    }
    return [];
  }

  // Add pending order (for offline mode)
  static Future<void> addPendingOrder(Map<String, dynamic> orderData) async {
    final prefs = await SharedPreferences.getInstance();
    final pendingJson = prefs.getString(_pendingOrdersKey);
    List<Map<String, dynamic>> pending = [];
    if (pendingJson != null) {
      pending = List<Map<String, dynamic>>.from(jsonDecode(pendingJson));
    }
    pending.add(orderData);
    await prefs.setString(_pendingOrdersKey, jsonEncode(pending));
  }

  // Get pending orders
  static Future<List<Map<String, dynamic>>> getPendingOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final pendingJson = prefs.getString(_pendingOrdersKey);
    if (pendingJson != null) {
      return List<Map<String, dynamic>>.from(jsonDecode(pendingJson));
    }
    return [];
  }

  // Clear pending orders
  static Future<void> clearPendingOrders() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingOrdersKey);
  }

  // Check if data is stale (older than 1 hour)
  static Future<bool> isDataStale() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSyncStr = prefs.getString(_lastSyncKey);
    if (lastSyncStr == null) return true;
    final lastSync = DateTime.parse(lastSyncStr);
    final now = DateTime.now();
    return now.difference(lastSync).inHours > 1;
  }

  // Check connectivity (simple check)
  static Future<bool> isOnline() async {
    try {
      // This is a simple check - in production, use connectivity_plus package
      return true; // Assume online for now
    } catch (e) {
      return false;
    }
  }
}

