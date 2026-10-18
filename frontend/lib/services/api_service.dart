import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/food.dart';
import '../models/order.dart';
import '../models/user.dart';

class ApiService {
  static String get baseUrl {
    if (kIsWeb) {
      return "http://localhost:5000/api";
    } else if (Platform.isAndroid) {
      return "http://10.0.2.2:5000/api";
    } else {
      return "http://localhost:5000/api";
    }
  }

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("token");
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("token", token);
  }

  // ===== Auth =====
  static Future<User?> login(String email, String password) async {
    final res = await http.post(
      Uri.parse("$baseUrl/auth/login"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "password": password}),
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      await saveToken(data['token']);
      return User.fromJson(data['user']);
    }
    return null;
  }

  static Future<User?> register(String name, String email, String password, {String? registrationNumber, String? studentId}) async {
    final body = <String, dynamic>{"name": name, "email": email, "password": password};
    if (registrationNumber != null && registrationNumber.isNotEmpty) {
      body["registrationNumber"] = registrationNumber;
    }
    if (studentId != null && studentId.isNotEmpty) {
      body["studentId"] = studentId;
    }
    final res = await http.post(
      Uri.parse("$baseUrl/auth/register"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );
    if (res.statusCode == 201) {
      final data = jsonDecode(res.body);
      await saveToken(data['token']);
      return User.fromJson(data['user']);
    }
    return null;
  }

  static Future<User?> getProfile() async {
    final token = await _getToken();
    final res = await http.get(
      Uri.parse("$baseUrl/auth/me"),
      headers: {"Authorization": "Bearer $token"},
    );
    if (res.statusCode == 200) {
      return User.fromJson(jsonDecode(res.body));
    }
    return null;
  }

  static Future<User?> updateProfile(String email, String password) async {
    final token = await _getToken();
    final res = await http.put(
      Uri.parse("$baseUrl/auth/me"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "email": email,
        "password": password,
      }),
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return User.fromJson(data['user']);
    }
    return null;
  }

  // ===== Foods =====
  static Future<List<Food>> getFoods() async {
    final res = await http.get(Uri.parse("$baseUrl/foods"));
    if (res.statusCode == 200) {
      final list = jsonDecode(res.body) as List;
      return list.map((e) => Food.fromJson(e)).toList();
    }
    return [];
  }

  // ===== Orders =====
  static Future<Order?> createOrder(List<Map<String, dynamic>> items) async {
    final token = await _getToken();
    final res = await http.post(
      Uri.parse("$baseUrl/orders"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      },
      body: jsonEncode({"items": items}),
    );
    if (res.statusCode == 201) {
      return Order.fromJson(jsonDecode(res.body));
    }
    return null;
  }

  static Future<List<Order>> getMyOrders() async {
    final token = await _getToken();
    final res = await http.get(
      Uri.parse("$baseUrl/orders/mine"),
      headers: {"Authorization": "Bearer $token"},
    );
    if (res.statusCode == 200) {
      final list = jsonDecode(res.body) as List;
      return list.map((e) => Order.fromJson(e)).toList();
    }
    return [];
  }

  static Future<Order?> getOrder(String orderId) async {
    final token = await _getToken();
    final res = await http.get(
      Uri.parse("$baseUrl/orders/$orderId"),
      headers: {"Authorization": "Bearer $token"},
    );
    if (res.statusCode == 200) {
      return Order.fromJson(jsonDecode(res.body));
    }
    return null;
  }

  // ===== Payments =====
  static Future<Map<String, dynamic>?> createRazorpayOrder(String orderId) async {
    final token = await _getToken();
    final res = await http.post(
      Uri.parse("$baseUrl/payments/razorpay/create-order"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({"orderId": orderId}),
    );
    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    return null;
  }

  static Future<bool> verifyRazorpayPayment({
    required String orderId,
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    final token = await _getToken();
    final res = await http.post(
      Uri.parse("$baseUrl/payments/razorpay/verify"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "orderId": orderId,
        "razorpay_order_id": razorpayOrderId,
        "razorpay_payment_id": razorpayPaymentId,
        "razorpay_signature": razorpaySignature,
      }),
    );
    return res.statusCode == 200;
  }

  // ===== Queue & ETA =====
  static Future<Map<String, dynamic>?> getOrderStatus(String orderId) async {
    final token = await _getToken();
    final res = await http.get(
      Uri.parse("$baseUrl/queue/order/$orderId/status"),
      headers: {"Authorization": "Bearer $token"},
    );
    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    return null;
  }

  // ===== Recommendations =====
  static Future<List<dynamic>> getRecommendations() async {
    final token = await _getToken();
    final res = await http.get(
      Uri.parse("$baseUrl/recommendations/me"),
      headers: {"Authorization": "Bearer $token"},
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return data['recommendations'] as List;
    }
    return [];
  }

  static Future<List<dynamic>> getTrendingFoods() async {
    final res = await http.get(Uri.parse("$baseUrl/recommendations/trending"));
    if (res.statusCode == 200) {
      return jsonDecode(res.body) as List;
    }
    return [];
  }

  static Future<bool> updatePreferences(Map<String, dynamic> preferences) async {
    final token = await _getToken();
    final res = await http.put(
      Uri.parse("$baseUrl/recommendations/preferences"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode(preferences),
    );
    return res.statusCode == 200;
  }

  // ===== Wallet =====
  static Future<Map<String, dynamic>?> getWallet() async {
    final token = await _getToken();
    final res = await http.get(
      Uri.parse("$baseUrl/wallet"),
      headers: {"Authorization": "Bearer $token"},
    );
    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    return null;
  }

  static Future<bool> topUpWallet(double amount, String paymentMethod) async {
    final token = await _getToken();
    final res = await http.post(
      Uri.parse("$baseUrl/wallet/topup"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({"amount": amount, "paymentMethod": paymentMethod}),
    );
    return res.statusCode == 200;
  }

  static Future<Map<String, dynamic>?> payWithWallet(String orderId) async {
    final token = await _getToken();
    final res = await http.post(
      Uri.parse("$baseUrl/wallet/pay"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({"orderId": orderId}),
    );
    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    return null;
  }

  static Future<List<dynamic>> getWalletTransactions() async {
    final token = await _getToken();
    final res = await http.get(
      Uri.parse("$baseUrl/wallet/transactions"),
      headers: {"Authorization": "Bearer $token"},
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return data['transactions'] as List;
    }
    return [];
  }

  static Future<Map<String, dynamic>?> getRewards() async {
    final token = await _getToken();
    final res = await http.get(
      Uri.parse("$baseUrl/wallet/rewards"),
      headers: {"Authorization": "Bearer $token"},
    );
    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    return null;
  }

  static Future<bool> redeemPoints(int points) async {
    final token = await _getToken();
    final res = await http.post(
      Uri.parse("$baseUrl/wallet/redeem"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({"points": points}),
    );
    return res.statusCode == 200;
  }

  // ===== QR Code =====
  static Future<Map<String, dynamic>?> generateQRCode(String orderId) async {
    final token = await _getToken();
    final res = await http.get(
      Uri.parse("$baseUrl/qr/order/$orderId"),
      headers: {"Authorization": "Bearer $token"},
    );
    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    return null;
  }

  // ===== Subscriptions =====
  static Future<Map<String, dynamic>?> createSubscription(Map<String, dynamic> data) async {
    final token = await _getToken();
    final res = await http.post(
      Uri.parse("$baseUrl/subscriptions"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode(data),
    );
    if (res.statusCode == 201) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    return null;
  }

  static Future<List<dynamic>> getMySubscriptions() async {
    final token = await _getToken();
    final res = await http.get(
      Uri.parse("$baseUrl/subscriptions/me"),
      headers: {"Authorization": "Bearer $token"},
    );
    if (res.statusCode == 200) {
      return jsonDecode(res.body) as List;
    }
    return [];
  }

  static Future<bool> cancelSubscription(String subscriptionId) async {
    final token = await _getToken();
    final res = await http.post(
      Uri.parse("$baseUrl/subscriptions/$subscriptionId/cancel"),
      headers: {"Authorization": "Bearer $token"},
    );
    return res.statusCode == 200;
  }

  // ===== Feedback =====
  static Future<bool> createFeedback(Map<String, dynamic> data) async {
    final token = await _getToken();
    final res = await http.post(
      Uri.parse("$baseUrl/feedback"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode(data),
    );
    return res.statusCode == 201;
  }

  static Future<List<dynamic>> getMyFeedback() async {
    final token = await _getToken();
    final res = await http.get(
      Uri.parse("$baseUrl/feedback/me"),
      headers: {"Authorization": "Bearer $token"},
    );
    if (res.statusCode == 200) {
      return jsonDecode(res.body) as List;
    }
    return [];
  }

  // ===== Nutrition & Dietary Goals =====
  static Future<bool> updateDietaryGoals(Map<String, double> goals) async {
    final token = await _getToken();
    final res = await http.patch(
      Uri.parse("$baseUrl/auth/me"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({"dietaryGoals": goals}),
    );
    return res.statusCode == 200;
  }

  // ===== Student ID Verification =====
  static Future<bool> verifyStudentId(String orderId, String studentId) async {
    final token = await _getToken();
    final res = await http.post(
      Uri.parse("$baseUrl/qr/verify-student"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({"orderId": orderId, "studentId": studentId}),
    );
    return res.statusCode == 200;
  }

  // ===== Order Prioritization =====
  static Future<Map<String, dynamic>?> getPrioritizedQueue() async {
    final token = await _getToken();
    final res = await http.get(
      Uri.parse("$baseUrl/prioritization/queue"),
      headers: {"Authorization": "Bearer $token"},
    );
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    return null;
  }

  // ===== Crowd Density =====
  static Future<Map<String, dynamic>?> getCrowdDensity() async {
    final token = await _getToken();
    final res = await http.get(
      Uri.parse("$baseUrl/crowd"),
      headers: {"Authorization": "Bearer $token"},
    );
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    return null;
  }

  static Future<Map<String, dynamic>?> getZoneCrowdDensity(String zone) async {
    final token = await _getToken();
    final res = await http.get(
      Uri.parse("$baseUrl/crowd/$zone"),
      headers: {"Authorization": "Bearer $token"},
    );
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    return null;
  }

  // ===== Chatbot =====
  static Future<Map<String, dynamic>> chatWithBot(String message) async {
    final token = await _getToken();
    final res = await http.post(
      Uri.parse("$baseUrl/chatbot/chat"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({"message": message}),
    );
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    return {
      'response': 'Sorry, I encountered an error.',
      'suggestions': ['Try Again', 'Menu'],
    };
  }

  // ===== Events =====
  static Future<List<Map<String, dynamic>>> getActiveEvents() async {
    final res = await http.get(Uri.parse("$baseUrl/events/active"));
    if (res.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(res.body));
    }
    return [];
  }

  static Future<List<Map<String, dynamic>>> getAllEvents({String? status}) async {
    final token = await _getToken();
    final url = status != null 
        ? "$baseUrl/events?status=$status"
        : "$baseUrl/events";
    final res = await http.get(
      Uri.parse(url),
      headers: {"Authorization": "Bearer $token"},
    );
    if (res.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(res.body));
    }
    return [];
  }

  static Future<Map<String, dynamic>?> getEvent(String eventId) async {
    final token = await _getToken();
    final res = await http.get(
      Uri.parse("$baseUrl/events/$eventId"),
      headers: {"Authorization": "Bearer $token"},
    );
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    return null;
  }

  static Future<bool> registerForEvent(String eventId) async {
    final token = await _getToken();
    final res = await http.post(
      Uri.parse("$baseUrl/events/$eventId/register"),
      headers: {"Authorization": "Bearer $token"},
    );
    return res.statusCode == 200;
  }

  static Future<Map<String, dynamic>?> orderEventBundle(String eventId, String bundleId) async {
    final token = await _getToken();
    final res = await http.post(
      Uri.parse("$baseUrl/events/$eventId/order-bundle"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({"bundleId": bundleId}),
    );
    if (res.statusCode == 201) {
      return jsonDecode(res.body);
    }
    return null;
  }
}
