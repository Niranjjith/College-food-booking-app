import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../models/order.dart';
import 'qr_pickup_screen.dart';
import 'student_id_verification_screen.dart';
import 'crowd_monitor_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  List<Order> orders = [];
  Map<String, Map<String, dynamic>> orderStatuses = {};
  Timer? _statusTimer;
  bool _loadingOrders = false;
  bool _initialLoading = true;
  String? _loadError;
  String? _statusError;

  @override
  void initState() {
    super.initState();
    _loadOrders(initial: true);
    _statusTimer = Timer.periodic(const Duration(seconds: 20), (_) => _loadOrders());
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadOrders({bool initial = false}) async {
    if (_loadingOrders) return;
    _loadingOrders = true;
    if (initial && mounted) setState(() => _initialLoading = true);

    try {
      final list = await ApiService.getMyOrders();
      if (!mounted) return;
      setState(() {
        orders = list;
        _loadError = null;
      });
      await _updateOrderStatuses(list);
    } catch (error) {
      if (mounted) setState(() => _loadError = "Couldn't refresh your orders. $error");
    } finally {
      _loadingOrders = false;
      if (mounted) setState(() => _initialLoading = false);
    }
  }

  Future<void> _updateOrderStatuses(List<Order> currentOrders) async {
    final nextStatuses = Map<String, Map<String, dynamic>>.from(orderStatuses);
    var hadError = false;

    for (final order in currentOrders) {
      final currentStatus =
          nextStatuses[order.id]?['order']?['status'] as String? ?? order.status;
      if (!['paid', 'preparing', 'ready'].contains(currentStatus)) continue;

      try {
        final status = await ApiService.getOrderStatus(order.id);
        if (status == null) {
          hadError = true;
        } else {
          nextStatuses[order.id] = status;
        }
      } catch (_) {
        hadError = true;
      }
    }

    if (!mounted) return;
    setState(() {
      orderStatuses = nextStatuses;
      _statusError = hadError ? "Live updates are temporarily unavailable. Pull to refresh." : null;
    });
  }

  String _liveStatus(Order order) =>
      orderStatuses[order.id]?['order']?['status'] as String? ?? order.status;

  Color _statusColor(String status) {
    switch (status) {
      case 'ready':
      case 'completed':
        return const Color(0xFF0B8F6B);
      case 'preparing':
        return const Color(0xFFB7791F);
      case 'paid':
        return const Color(0xFF2563A6);
      case 'cancelled':
        return const Color(0xFFB45345);
      default:
        return Colors.orange.shade700;
    }
  }

  Widget _buildProgress(String status) {
    if (status == 'cancelled') {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF1EF),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Row(
          children: [
            Icon(Icons.cancel_outlined, color: Color(0xFFB45345), size: 19),
            SizedBox(width: 8),
            Text("This order was cancelled", style: TextStyle(color: Color(0xFF9F4338), fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }

    if (status == 'pending') {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7E8),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Row(
          children: [
            Icon(Icons.hourglass_top_rounded, color: Color(0xFFB7791F), size: 19),
            SizedBox(width: 8),
            Expanded(child: Text("Waiting for payment confirmation", style: TextStyle(color: Color(0xFF94601C), fontWeight: FontWeight.w600))),
          ],
        ),
      );
    }

    const steps = ['Confirmed', 'Preparing', 'Ready', 'Picked up'];
    final activeStep = switch (status) {
      'paid' => 0,
      'preparing' => 1,
      'ready' => 2,
      'completed' => 3,
      _ => 0,
    };

    return Column(
      children: [
        Row(
          children: List.generate(steps.length, (index) {
            final reached = index <= activeStep;
            return Expanded(
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: reached ? const Color(0xFF0B8F6B) : const Color(0xFFE5E7EB),
                    ),
                    child: Icon(
                      reached ? Icons.check : Icons.circle,
                      size: reached ? 12 : 6,
                      color: Colors.white,
                    ),
                  ),
                  if (index < steps.length - 1)
                    Expanded(
                      child: Container(
                        height: 2,
                        color: index < activeStep
                            ? const Color(0xFF0B8F6B)
                            : const Color(0xFFE5E7EB),
                      ),
                    ),
                ],
              ),
            );
          }),
        ),
        const SizedBox(height: 7),
        Row(
          children: List.generate(
            steps.length,
            (index) => Expanded(
              child: Text(
                steps[index],
                textAlign: index == 0
                    ? TextAlign.left
                    : index == steps.length - 1
                        ? TextAlign.right
                        : TextAlign.center,
                style: TextStyle(
                  color: index <= activeStep ? const Color(0xFF39765C) : Colors.grey.shade500,
                  fontSize: 9,
                  fontWeight: index == activeStep ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOrderCard(Order order) {
    final status = _liveStatus(order);
    final statusData = orderStatuses[order.id];
    final preparation = statusData?['preparation'];
    final remaining = preparation is Map ? preparation['remainingTime'] : null;
    final remainingTime = remaining is num ? remaining.toInt() : null;
    final queuePosition = preparation is Map ? preparation['queuePosition'] : null;
    final statusColor = _statusColor(status);
    final canPickUp = ['paid', 'preparing', 'ready'].contains(status);
    final createdAt = DateTime.tryParse(order.createdAt);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.045),
            blurRadius: 12,
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
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "ORDER #${order.id.length > 6 ? order.id.substring(order.id.length - 6).toUpperCase() : order.id.toUpperCase()}",
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: Colors.grey.shade500),
                      ),
                      if (createdAt != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('EEE, d MMM · h:mm a').format(createdAt),
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                        ),
                      ],
                    ],
                  ),
                ),
                Text(
                  "₹${order.subtotal.toStringAsFixed(2)}",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF111827)),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                ),
                const SizedBox(width: 7),
                Text(
                  status.replaceAll('-', ' ').toUpperCase(),
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: statusColor, letterSpacing: 0.4),
                ),
              ],
            ),
            const SizedBox(height: 13),
            _buildProgress(status),
            if (remainingTime != null && status != 'ready' && status != 'completed') ...[
              const SizedBox(height: 13),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF7F1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.schedule_rounded, color: Color(0xFF0B8F6B), size: 18),
                    const SizedBox(width: 8),
                    Text(
                      remainingTime > 0 ? "About $remainingTime min remaining" : "Your order is almost ready",
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF087856)),
                    ),
                    if (queuePosition is num && queuePosition > 0) ...[
                      const Spacer(),
                      Text(
                        "Queue #${queuePosition.toInt()}",
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            if (status == 'ready') ...[
              const SizedBox(height: 13),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(color: const Color(0xFFEAF7F1), borderRadius: BorderRadius.circular(10)),
                child: const Text("Your meal is ready for pickup!", textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF087856), fontWeight: FontWeight.w700)),
              ),
            ],
            const SizedBox(height: 13),
            const Divider(height: 1),
            const SizedBox(height: 11),
            ...order.items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      const Icon(Icons.circle, size: 6, color: Color(0xFF0B8F6B)),
                      const SizedBox(width: 9),
                      Expanded(child: Text("${item.name} × ${item.qty}", style: TextStyle(fontSize: 12, color: Colors.grey.shade800))),
                      Text("₹${(item.price * item.qty).toStringAsFixed(0)}", style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                    ],
                  ),
                )),
            if (canPickUp) ...[
              const SizedBox(height: 7),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => QRPickupScreen(orderId: order.id)),
                      ),
                      icon: const Icon(Icons.qr_code_2_rounded, size: 18),
                      label: const Text("Pickup QR"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0B8F6B),
                        side: const BorderSide(color: Color(0xFF0B8F6B)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => StudentIdVerificationScreen(orderId: order.id)),
                      ),
                      icon: const Icon(Icons.badge_outlined, size: 18),
                      label: const Text("Verify ID"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0B8F6B),
                        side: const BorderSide(color: Color(0xFF0B8F6B)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Orders"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: "Refresh orders",
            onPressed: () => _loadOrders(),
          ),
          IconButton(
            icon: const Icon(Icons.people_outline),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CrowdMonitorScreen()),
            ),
            tooltip: "Crowd Monitor",
          ),
        ],
      ),
      body: _initialLoading && orders.isEmpty
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0B8F6B)))
          : _loadError != null && orders.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.wifi_off_rounded, size: 42, color: Color(0xFF9CA3AF)),
                        const SizedBox(height: 12),
                        Text(_loadError!, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: () => _loadOrders(initial: true),
                          icon: const Icon(Icons.refresh),
                          label: const Text("Try again"),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  color: const Color(0xFF0B8F6B),
                  onRefresh: () => _loadOrders(),
                  child: orders.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(
                              height: MediaQuery.sizeOf(context).height * 0.58,
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.receipt_long_outlined, size: 60, color: Colors.grey.shade400),
                                    const SizedBox(height: 14),
                                    Text("No orders yet", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.grey.shade800)),
                                    const SizedBox(height: 6),
                                    Text("Your order history will appear here", style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                      : ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.only(top: 5, bottom: 20),
                          children: [
                            if (_loadError != null || _statusError != null)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                                child: Text(
                                  _loadError ?? _statusError!,
                                  style: TextStyle(color: Colors.orange.shade900, fontSize: 12),
                                ),
                              ),
                            ...orders.map(_buildOrderCard),
                          ],
                        ),
                ),
    );
  }
}
