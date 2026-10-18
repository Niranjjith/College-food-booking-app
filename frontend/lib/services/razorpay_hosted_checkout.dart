import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/order.dart';
import 'api_service.dart';

/// Opens Razorpay Checkout in the system browser (Windows/macOS/Linux/Web).
Future<bool> completeRazorpayHostedCheckout(
  BuildContext context, {
  required String appOrderId,
  required String checkoutUrl,
}) async {
  final uri = Uri.parse(checkoutUrl);
  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open payment page in browser')),
      );
    }
    return false;
  }

  if (!context.mounted) return false;

  final paid = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => _HostedCheckoutDialog(appOrderId: appOrderId),
  );

  return paid == true;
}

class _HostedCheckoutDialog extends StatefulWidget {
  const _HostedCheckoutDialog({required this.appOrderId});

  final String appOrderId;

  @override
  State<_HostedCheckoutDialog> createState() => _HostedCheckoutDialogState();
}

class _HostedCheckoutDialogState extends State<_HostedCheckoutDialog> {
  Timer? _pollTimer;
  String _statusText = 'Waiting for payment…';
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) => _poll());
    _poll();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _poll() async {
    final Order? order = await ApiService.getOrder(widget.appOrderId);
    if (!mounted) return;

    if (order != null && order.status == 'paid') {
      _pollTimer?.cancel();
      Navigator.of(context).pop(true);
      return;
    }

    setState(() {
      _checking = true;
      _statusText = order == null
          ? 'Checking payment status…'
          : 'Order status: ${order.status}. Complete payment in the browser.';
    });
  }

  void _cancel() {
    _pollTimer?.cancel();
    Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Complete payment'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Razorpay opened in your browser. Finish payment there, then return here.',
          ),
          const SizedBox(height: 16),
          if (_checking)
            const LinearProgressIndicator(
              minHeight: 2,
              color: Color(0xFF10B981),
            ),
          const SizedBox(height: 12),
          Text(
            _statusText,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: _cancel, child: const Text('Cancel')),
        TextButton(onPressed: _poll, child: const Text('Refresh')),
      ],
    );
  }
}
