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

  static Future<User?> register(String name, String email, String password) async {
    final res = await http.post(
      Uri.parse("$baseUrl/auth/register"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"name": name, "email": email, "password": password}),
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
}
