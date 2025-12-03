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
  static const String _offlineOrdersKey = 'offline_orders';

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

  // ===== Offline Pre-Order Mode =====
  
  // Save offline order
  static Future<void> saveOfflineOrder(Map<String, dynamic> orderData) async {
    final prefs = await SharedPreferences.getInstance();
    final offlineJson = prefs.getString(_offlineOrdersKey);
    List<Map<String, dynamic>> offlineOrders = [];
    if (offlineJson != null) {
      offlineOrders = List<Map<String, dynamic>>.from(jsonDecode(offlineJson));
    }
    
    // Add timestamp and unique ID
    orderData['_offlineId'] = DateTime.now().millisecondsSinceEpoch.toString();
    orderData['_offlineTimestamp'] = DateTime.now().toIso8601String();
    orderData['_synced'] = false;
    
    offlineOrders.add(orderData);
    await prefs.setString(_offlineOrdersKey, jsonEncode(offlineOrders));
  }

  // Get offline orders
  static Future<List<Map<String, dynamic>>> getOfflineOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final offlineJson = prefs.getString(_offlineOrdersKey);
    if (offlineJson != null) {
      return List<Map<String, dynamic>>.from(jsonDecode(offlineJson));
    }
    return [];
  }

  // Get unsynced orders
  static Future<List<Map<String, dynamic>>> getUnsyncedOrders() async {
    final orders = await getOfflineOrders();
    return orders.where((order) => order['_synced'] == false).toList();
  }

  // Mark order as synced
  static Future<void> markOrderSynced(String offlineId) async {
    final prefs = await SharedPreferences.getInstance();
    final orders = await getOfflineOrders();
    final updated = orders.map((order) {
      if (order['_offlineId'] == offlineId) {
        order['_synced'] = true;
      }
      return order;
    }).toList();
    await prefs.setString(_offlineOrdersKey, jsonEncode(updated));
  }

  // Remove synced orders
  static Future<void> removeSyncedOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final orders = await getOfflineOrders();
    final unsynced = orders.where((order) => order['_synced'] == false).toList();
    await prefs.setString(_offlineOrdersKey, jsonEncode(unsynced));
  }

  // Sync offline orders to server
  static Future<Map<String, dynamic>> syncOfflineOrders(Future<Map<String, dynamic>?> Function(Map<String, dynamic>) createOrderFn) async {
    final unsynced = await getUnsyncedOrders();
    int successCount = 0;
    int failCount = 0;
    List<String> syncedIds = [];

    for (final order in unsynced) {
      try {
        // Remove offline metadata before sending
        final orderData = Map<String, dynamic>.from(order);
        orderData.remove('_offlineId');
        orderData.remove('_offlineTimestamp');
        orderData.remove('_synced');

        final result = await createOrderFn(orderData);
        if (result != null) {
          await markOrderSynced(order['_offlineId'] as String);
          syncedIds.add(order['_offlineId'] as String);
          successCount++;
        } else {
          failCount++;
        }
      } catch (e) {
        failCount++;
      }
    }

    // Clean up synced orders
    await removeSyncedOrders();

    return {
      'total': unsynced.length,
      'success': successCount,
      'failed': failCount,
      'syncedIds': syncedIds,
    };
  }
}

