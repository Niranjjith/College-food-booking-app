import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/order.dart';
import 'qr_pickup_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  List<Order> orders = [];
  Map<String, Map<String, dynamic>> orderStatuses = {};
  Timer? _statusTimer;

  @override
  void initState() {
    super.initState();
    _loadOrders();
    _startStatusPolling();
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    super.dispose();
  }

  void _loadOrders() async {
    final list = await ApiService.getMyOrders();
    setState(() {
      orders = list;
    });
    _updateOrderStatuses();
  }

  void _startStatusPolling() {
    _statusTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _updateOrderStatuses();
    });
  }

  void _updateOrderStatuses() async {
    for (final order in orders) {
      if (order.status == 'paid' || order.status == 'preparing' || order.status == 'ready') {
        final status = await ApiService.getOrderStatus(order.id);
        if (status != null && mounted) {
          setState(() {
            orderStatuses[order.id] = status;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Orders")),
      body: orders.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "No orders yet",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Your order history will appear here",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: orders.length,
              itemBuilder: (_, i) {
                final o = orders[i];
                final isPaid = o.status.toLowerCase() == 'paid' || o.status.toLowerCase() == 'preparing' || o.status.toLowerCase() == 'ready';
                final statusData = orderStatuses[o.id];
                final prepInfo = statusData?['preparation'];
                final remainingTime = prepInfo?['remainingTime'] as int?;
                
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "₹${o.subtotal.toStringAsFixed(2)}",
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF111827),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: isPaid
                                    ? const Color(0xFF10B981).withOpacity(0.1)
                                    : Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                o.status.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isPaid ? const Color(0xFF10B981) : Colors.orange.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (remainingTime != null && remainingTime > 0) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.access_time,
                                  color: Color(0xFF10B981),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "ETA: ${remainingTime} minutes",
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF10B981),
                                  ),
                                ),
                                if (prepInfo?['queuePosition'] != null) ...[
                                  const SizedBox(width: 12),
                                  Text(
                                    "Queue: #${prepInfo['queuePosition']}",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                        if (o.status == 'ready' || o.status == 'paid' || o.status == 'preparing') ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => QRPickupScreen(orderId: o.id),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.qr_code),
                              label: const Text("Show QR Code"),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF10B981),
                                side: const BorderSide(color: Color(0xFF10B981)),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
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
                        ...o.items.map((it) => Padding(
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
                                      "${it.name} × ${it.qty}",
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
