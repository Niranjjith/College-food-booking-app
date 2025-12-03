import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class CrowdMonitorScreen extends StatefulWidget {
  const CrowdMonitorScreen({super.key});

  @override
  State<CrowdMonitorScreen> createState() => _CrowdMonitorScreenState();
}

class _CrowdMonitorScreenState extends State<CrowdMonitorScreen> {
  Map<String, dynamic>? _crowdData;
  bool _loading = true;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadCrowdData();
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) => _loadCrowdData());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _loadCrowdData() async {
    final data = await ApiService.getCrowdDensity();
    setState(() {
      _crowdData = data;
      _loading = false;
    });
  }

  Color _getDensityColor(double density) {
    if (density < 30) return Colors.green;
    if (density < 60) return Colors.orange;
    if (density < 85) return Colors.deepOrange;
    return Colors.red;
  }

  String _getDensityStatus(double density) {
    if (density < 30) return 'Low';
    if (density < 60) return 'Medium';
    if (density < 85) return 'High';
    return 'Very High';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Crowd Density Monitor"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCrowdData,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _crowdData == null
              ? const Center(child: Text("No data available"))
              : RefreshIndicator(
                  onRefresh: () async => _loadCrowdData(),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Best Zone Card
                        if (_crowdData!['bestZone'] != null)
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFF10B981),
                                  const Color(0xFF059669),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                const Icon(Icons.location_on, color: Colors.white, size: 40),
                                const SizedBox(height: 12),
                                const Text(
                                  "Best Pickup Zone",
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _crowdData!['bestZone']['zone'].toString().replaceAll('Counter', ' Counter'),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "Wait time: ${_crowdData!['bestZone']['waitTime']} minutes",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 24),

                        // All Zones
                        const Text(
                          "All Pickup Zones",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...((_crowdData!['zones'] as List).map((zone) {
                          final density = (zone['density'] as num).toDouble();
                          final status = zone['status'] as String;
                          final waitTime = zone['waitTime'] as int;
                          final recommendation = zone['recommendedAction'] as Map<String, dynamic>;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _getDensityColor(density).withOpacity(0.3),
                                width: 2,
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
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      zone['zone'].toString().replaceAll('Counter', ' Counter'),
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF111827),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getDensityColor(density).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        _getDensityStatus(density),
                                        style: TextStyle(
                                          color: _getDensityColor(density),
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                // Density Bar
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          "Crowd Density",
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Color(0xFF6B7280),
                                          ),
                                        ),
                                        Text(
                                          "${density.toStringAsFixed(0)}%",
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: _getDensityColor(density),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: LinearProgressIndicator(
                                        value: density / 100,
                                        minHeight: 8,
                                        backgroundColor: Colors.grey.shade200,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          _getDensityColor(density),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.access_time,
                                      size: 16,
                                      color: Colors.grey.shade600,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      "Estimated wait: $waitTime minutes",
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: _getRecommendationColor(recommendation['urgency']).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: _getRecommendationColor(recommendation['urgency']).withOpacity(0.3),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        _getRecommendationIcon(recommendation['action']),
                                        color: _getRecommendationColor(recommendation['urgency']),
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          recommendation['message'] ?? '',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey.shade700,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList()),
                      ],
                    ),
                  ),
                ),
    );
  }

  Color _getRecommendationColor(String urgency) {
    switch (urgency) {
      case 'very-high':
        return Colors.red;
      case 'high':
        return Colors.deepOrange;
      case 'medium':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  IconData _getRecommendationIcon(String action) {
    switch (action) {
      case 'go':
        return Icons.check_circle;
      case 'wait-or-redirect':
      case 'redirect':
        return Icons.warning;
      default:
        return Icons.info;
    }
  }
}

