import 'package:flutter/material.dart';
import '../services/api_service.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  List<Map<String, dynamic>> _events = [];
  bool _loading = true;
  String _filter = 'all'; // all, upcoming, active, ended

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  void _loadEvents() async {
    setState(() => _loading = true);
    try {
      List<Map<String, dynamic>> events;
      if (_filter == 'all') {
        events = await ApiService.getAllEvents();
      } else {
        events = await ApiService.getAllEvents(status: _filter);
      }
      setState(() {
        _events = events;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading events: $e")),
      );
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'upcoming':
        return Colors.blue;
      case 'ended':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Campus Events"),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _filter = value;
              });
              _loadEvents();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text("All Events")),
              const PopupMenuItem(value: 'upcoming', child: Text("Upcoming")),
              const PopupMenuItem(value: 'active', child: Text("Active")),
              const PopupMenuItem(value: 'ended', child: Text("Ended")),
            ],
            child: const Icon(Icons.filter_list),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _events.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.event_busy, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        "No events available",
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async => _loadEvents(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _events.length,
                    itemBuilder: (context, index) {
                      final event = _events[index];
                      return _buildEventCard(event);
                    },
                  ),
                ),
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
    final status = event['status'] as String? ?? 'upcoming';
    final startDate = DateTime.parse(event['startDate']);
    final endDate = DateTime.parse(event['endDate']);
    final now = DateTime.now();
    final isActive = now.isAfter(startDate) && now.isBefore(endDate);
    final bundles = event['bundles'] as List? ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? const Color(0xFF10B981) : Colors.grey.shade200,
          width: isActive ? 2 : 1,
        ),
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
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getStatusColor(status).withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.event, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event['name'] ?? 'Event',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${startDate.day}/${startDate.month}/${startDate.year} - ${endDate.day}/${endDate.month}/${endDate.year}",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Description
          if (event['description'] != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                event['description'],
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
              ),
            ),

          // Bundles
          if (bundles.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                "Special Bundles",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: bundles.length,
                itemBuilder: (context, idx) {
                  final bundle = bundles[idx];
                  return _buildBundleCard(event, bundle);
                },
              ),
            ),
          ],

          // Actions
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                if (event['registrationRequired'] == true)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _registerForEvent(event['_id']),
                      icon: const Icon(Icons.person_add),
                      label: const Text("Register"),
                    ),
                  ),
                if (event['registrationRequired'] == true) const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: isActive ? () => _viewEventDetails(event) : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                    ),
                    child: const Text("View Details"),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBundleCard(Map<String, dynamic> event, Map<String, dynamic> bundle) {
    final discount = bundle['discount'] ?? 0;
    final originalPrice = bundle['price'] as num;
    final discountedPrice = originalPrice * (1 - discount / 100);

    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image placeholder
          Container(
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: const Center(
              child: Icon(Icons.restaurant_menu, size: 40, color: Color(0xFF10B981)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bundle['name'] ?? 'Bundle',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                if (discount > 0) ...[
                  Text(
                    "₹${originalPrice.toStringAsFixed(2)}",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                ],
                Text(
                  "₹${discountedPrice.toStringAsFixed(2)}",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF10B981),
                  ),
                ),
                if (discount > 0)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      "${discount.toStringAsFixed(0)}% OFF",
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _orderBundle(event['_id'], bundle['_id']),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: const Text("Order Now", style: TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _registerForEvent(String eventId) async {
    try {
      final success = await ApiService.registerForEvent(eventId);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Registered successfully!"),
            backgroundColor: Color(0xFF10B981),
          ),
        );
        _loadEvents();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  void _orderBundle(String eventId, String bundleId) async {
    try {
      final result = await ApiService.orderEventBundle(eventId, bundleId);
      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Bundle ordered successfully!"),
            backgroundColor: Color(0xFF10B981),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  void _viewEventDetails(Map<String, dynamic> event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(event['name'] ?? 'Event'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (event['description'] != null) ...[
                Text(event['description']),
                const SizedBox(height: 16),
              ],
              Text(
                "Bundles: ${(event['bundles'] as List).length}",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }
}

