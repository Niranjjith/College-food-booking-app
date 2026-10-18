import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../services/api_service.dart';
import '../services/offline_service.dart';
import '../services/razorpay_hosted_checkout.dart';
import '../models/order.dart';
import '../utils/payment_platform.dart';
import 'wallet_screen.dart';

class CartScreen extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;
  final VoidCallback onOrderPlaced;

  const CartScreen({super.key, required this.cartItems, required this.onOrderPlaced});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  Razorpay? _razorpay;
  String _selectedPaymentMethod = 'razorpay';
  bool _isProcessing = false;
  Order? _currentOrder;
  Map<String, dynamic>? _wallet;
  Map<String, dynamic>? _rewards;

  @override
  void initState() {
    super.initState();
    if (razorpayNativeCheckoutSupported) {
      _razorpay = Razorpay();
      _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
      _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
      _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    }
    _loadWalletData();
  }

  void _loadWalletData() async {
    final wallet = await ApiService.getWallet();
    final rewards = await ApiService.getRewards();
    setState(() {
      _wallet = wallet;
      _rewards = rewards;
    });
  }

  @override
  void dispose() {
    _razorpay?.clear();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    if (_currentOrder == null) return;

    final verified = await ApiService.verifyRazorpayPayment(
      orderId: _currentOrder!.id,
      razorpayOrderId: response.orderId ?? '',
      razorpayPaymentId: response.paymentId ?? '',
      razorpaySignature: response.signature ?? '',
    );

    setState(() {
      _isProcessing = false;
    });

    if (verified) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Payment successful! Order placed."),
            backgroundColor: Color(0xFF10B981),
          ),
        );
        widget.onOrderPlaced();
        Navigator.pop(context);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("❌ Payment verification failed"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    setState(() {
      _isProcessing = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Payment failed: ${response.message ?? 'Unknown error'}"),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("External wallet selected: ${response.walletName}"),
      ),
    );
  }

  Future<void> _checkout(BuildContext context) async {
    if (widget.cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cart is empty")),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // Check if online
      bool isOnline = await OfflineService.isOnline();
      
      // Try to create order
      Order? order;
      try {
        order = await ApiService.createOrder(widget.cartItems);
        isOnline = true; // If successful, we're online
      } catch (e) {
        isOnline = false;
      }

      // If offline, save order locally
      if (!isOnline || order == null) {
        // Save as offline order
        final orderData = {
          'items': widget.cartItems,
          'subtotal': _calculateTotal(),
          'paymentMethod': _selectedPaymentMethod,
          'timestamp': DateTime.now().toIso8601String(),
        };
        
        await OfflineService.saveOfflineOrder(orderData);
        
        setState(() {
          _isProcessing = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("📱 Order saved offline! Will sync when online."),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 4),
          ),
        );
        
        widget.onOrderPlaced();
        Navigator.pop(context);
        return;
      }

      _currentOrder = order;

      if (_selectedPaymentMethod == 'wallet') {
        // Pay with wallet
        final result = await ApiService.payWithWallet(order.id);
        if (result != null && result['success'] == true) {
          setState(() {
            _isProcessing = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? "Payment successful!"),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
          widget.onOrderPlaced();
          Navigator.pop(context);
        } else {
          setState(() {
            _isProcessing = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Payment failed. Insufficient balance?"),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else if (_selectedPaymentMethod == 'razorpay') {
        // Create Razorpay order
        final razorpayOrder = await ApiService.createRazorpayOrder(order.id);
        if (razorpayOrder == null) {
          setState(() {
            _isProcessing = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("❌ Failed to initialize payment")),
          );
          return;
        }

        if (razorpayNativeCheckoutSupported) {
          final options = {
            'key': razorpayOrder['key'],
            'amount': razorpayOrder['amount'],
            'name': 'Food Booking App',
            'description': 'Order Payment',
            'order_id': razorpayOrder['id'],
            'prefill': {
              'contact': '',
              'email': '',
            },
            'external': {
              'wallets': ['paytm']
            }
          };

          _razorpay!.open(options);
        } else {
          final checkoutUrl = razorpayOrder['checkoutUrl'] as String?;
          if (checkoutUrl == null || checkoutUrl.isEmpty) {
            setState(() {
              _isProcessing = false;
            });
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("❌ Failed to initialize payment")),
              );
            }
            return;
          }

          final paid = await completeRazorpayHostedCheckout(
            context,
            appOrderId: order.id,
            checkoutUrl: checkoutUrl,
          );

          setState(() {
            _isProcessing = false;
          });

          if (!mounted) return;

          if (paid) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("✅ Payment successful! Order placed."),
                backgroundColor: Color(0xFF10B981),
              ),
            );
            widget.onOrderPlaced();
            Navigator.pop(context);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Payment not completed"),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      } else {
        // Cash on delivery or other payment methods
        setState(() {
          _isProcessing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Order placed successfully!"),
            backgroundColor: Color(0xFF10B981),
          ),
        );
        widget.onOrderPlaced();
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  double _calculateTotal() {
    double subtotal = widget.cartItems.fold<double>(0, (sum, item) => sum + (item["qty"] * (item["price"] as double)));
    
    // Apply discounts from rewards
    if (_rewards != null && _rewards!['discounts'] != null) {
      double maxDiscount = 0;
      for (var discount in _rewards!['discounts']) {
        maxDiscount = math.max(maxDiscount, (discount['discount'] as num).toDouble());
      }
      if (maxDiscount > 0) {
        subtotal = subtotal * (1 - maxDiscount / 100);
      }
    }
    
    return subtotal;
  }

  @override
  Widget build(BuildContext context) {
    final total = _calculateTotal();

    return Scaffold(
      appBar: AppBar(title: const Text("Shopping Cart")),
      body: widget.cartItems.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Your cart is empty",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Add items to get started",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: widget.cartItems.length,
                    itemBuilder: (_, i) {
                      final item = widget.cartItems[i];
                      final itemTotal = (item["qty"] * item["price"] as double);
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
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.restaurant_menu,
                              color: Color(0xFF10B981),
                            ),
                          ),
                          title: Text(
                            item["name"],
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Text(
                            "Qty: ${item["qty"]} × ₹${item["price"].toStringAsFixed(2)}",
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                          trailing: Text(
                            "₹${itemTotal.toStringAsFixed(2)}",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Total",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF111827),
                            ),
                          ),
                          Text(
                            "₹${total.toStringAsFixed(2)}",
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Payment Method Selection
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  "Payment Method",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF111827),
                                  ),
                                ),
                                const Spacer(),
                                if (_wallet != null)
                                  TextButton.icon(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const WalletScreen(),
                                        ),
                                      ).then((_) => _loadWalletData());
                                    },
                                    icon: const Icon(Icons.account_balance_wallet, size: 16),
                                    label: Text(
                                      "₹${(_wallet!['balance'] ?? 0.0).toStringAsFixed(2)}",
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            RadioListTile<String>(
                              value: 'wallet',
                              groupValue: _selectedPaymentMethod,
                              onChanged: _isProcessing
                                  ? null
                                  : (value) {
                                      setState(() {
                                        _selectedPaymentMethod = value!;
                                      });
                                    },
                              title: const Text("Wallet"),
                              subtitle: _wallet != null
                                  ? Text("Balance: ₹${(_wallet!['balance'] ?? 0.0).toStringAsFixed(2)}")
                                  : const Text("Digital wallet payment"),
                              activeColor: const Color(0xFF10B981),
                              contentPadding: EdgeInsets.zero,
                            ),
                            RadioListTile<String>(
                              value: 'razorpay',
                              groupValue: _selectedPaymentMethod,
                              onChanged: _isProcessing
                                  ? null
                                  : (value) {
                                      setState(() {
                                        _selectedPaymentMethod = value!;
                                      });
                                    },
                              title: const Text("Razorpay"),
                              subtitle: Text(
                                razorpayNativeCheckoutSupported
                                    ? "Pay with UPI, Cards, Wallets"
                                    : "Opens secure checkout in your browser",
                              ),
                              activeColor: const Color(0xFF10B981),
                              contentPadding: EdgeInsets.zero,
                            ),
                            RadioListTile<String>(
                              value: 'cod',
                              groupValue: _selectedPaymentMethod,
                              onChanged: _isProcessing
                                  ? null
                                  : (value) {
                                      setState(() {
                                        _selectedPaymentMethod = value!;
                                      });
                                    },
                              title: const Text("Cash on Delivery"),
                              subtitle: const Text("Pay when you receive"),
                              activeColor: const Color(0xFF10B981),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isProcessing ? null : () => _checkout(context),
                          child: _isProcessing
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text(
                                  "Place Order",
                                  style: TextStyle(fontSize: 16),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
