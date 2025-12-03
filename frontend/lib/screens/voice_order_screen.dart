import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../services/api_service.dart';
import 'cart_screen.dart';

class VoiceOrderScreen extends StatefulWidget {
  const VoiceOrderScreen({super.key});

  @override
  State<VoiceOrderScreen> createState() => _VoiceOrderScreenState();
}

class _VoiceOrderScreenState extends State<VoiceOrderScreen> {
  stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _text = '';
  String _status = 'Tap the microphone to start ordering';
  List<Map<String, dynamic>> _voiceCart = [];
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _initializeSpeech();
  }

  void _initializeSpeech() async {
    bool available = await _speech.initialize(
      onStatus: (status) {
        setState(() {
          if (status == 'done' || status == 'notListening') {
            _isListening = false;
            _status = 'Tap to speak again';
          }
        });
      },
      onError: (error) {
        setState(() {
          _status = 'Error: ${error.errorMsg}';
          _isListening = false;
        });
      },
    );
    if (!available) {
      setState(() {
        _status = 'Speech recognition not available';
      });
    }
  }


  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() {
          _isListening = true;
          _text = '';
          _status = 'Listening... Speak your order';
        });
        await _speech.listen(
          onResult: (result) {
            setState(() {
              _text = result.recognizedWords;
              if (result.finalResult) {
                _processVoiceOrder(_text);
              }
            });
          },
          listenFor: const Duration(seconds: 10),
          pauseFor: const Duration(seconds: 3),
          localeId: 'en_US',
        );
      }
    } else {
      await _speech.stop();
      setState(() {
        _isListening = false;
        _status = 'Stopped listening';
      });
    }
  }

  void _processVoiceOrder(String text) async {
    setState(() {
      _isProcessing = true;
      _status = 'Processing your order...';
    });

    // Simple voice command parsing
    // In production, use NLP/AI for better understanding
    final lowerText = text.toLowerCase();
    
    // Extract food items and quantities
    final foods = await ApiService.getFoods();
    List<Map<String, dynamic>> foundItems = [];

    for (var food in foods) {
      if (lowerText.contains(food.name.toLowerCase())) {
        // Try to extract quantity
        int qty = 1;
        final qtyMatch = RegExp(r'(\d+)\s*' + food.name.toLowerCase()).firstMatch(lowerText);
        if (qtyMatch != null) {
          qty = int.tryParse(qtyMatch.group(1) ?? '1') ?? 1;
        } else if (lowerText.contains('two') || lowerText.contains('2')) {
          qty = 2;
        } else if (lowerText.contains('three') || lowerText.contains('3')) {
          qty = 3;
        }

        foundItems.add({
          'foodId': food.id,
          'name': food.name,
          'qty': qty,
          'price': food.price,
        });
      }
    }

    if (foundItems.isNotEmpty) {
      setState(() {
        _voiceCart.addAll(foundItems);
        _status = 'Added ${foundItems.length} item(s) to cart! ${foundItems.map((i) => '${i['qty']} ${i['name']}').join(', ')}';
      });
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added ${foundItems.map((i) => '${i['qty']} ${i['name']}').join(', ')} to cart'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    } else {
      setState(() {
        _status = 'Could not find items. Please try again or browse the menu.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sorry, I could not find those items. Please try again or browse the menu.'),
          backgroundColor: Colors.orange,
        ),
      );
    }

    setState(() {
      _isProcessing = false;
    });
  }

  void _clearCart() {
    setState(() {
      _voiceCart.clear();
      _text = '';
      _status = 'Cart cleared. Tap to order again';
    });
  }

  void _goToCart() {
    if (_voiceCart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Your cart is empty")),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CartScreen(
          cartItems: _voiceCart,
          onOrderPlaced: _clearCart,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Voice Ordering"),
        actions: [
          if (_voiceCart.isNotEmpty)
            Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_cart),
                  onPressed: _goToCart,
                ),
                Positioned(
                  right: 4,
                  top: 4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Center(
                      child: Text(
                        "${_voiceCart.length}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            
            // Status Text
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isListening 
                    ? const Color(0xFF10B981).withOpacity(0.1)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _status,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: _isListening ? const Color(0xFF10B981) : Colors.grey.shade700,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),

            // Microphone Button
            GestureDetector(
              onTap: _isProcessing ? null : _listen,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: _isListening
                        ? [
                            const Color(0xFF10B981),
                            const Color(0xFF059669),
                          ]
                        : [
                            Colors.grey.shade300,
                            Colors.grey.shade400,
                          ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (_isListening ? const Color(0xFF10B981) : Colors.grey)
                          .withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: _isProcessing
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Icon(
                        _isListening ? Icons.mic : Icons.mic_none,
                        size: 60,
                        color: Colors.white,
                      ),
              ),
            ),
            const SizedBox(height: 32),

            // Recognized Text
            if (_text.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "You said:",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _text,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Voice Cart Items
            if (_voiceCart.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF10B981)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Voice Cart",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF111827),
                          ),
                        ),
                        TextButton(
                          onPressed: _clearCart,
                          child: const Text("Clear"),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ..._voiceCart.map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "${item['qty']}x ${item['name']}",
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF111827),
                                ),
                              ),
                              Text(
                                "₹${(item['price'] * item['qty']).toStringAsFixed(2)}",
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF10B981),
                                ),
                              ),
                            ],
                          ),
                        )),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _goToCart,
                        child: const Text("Proceed to Checkout"),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 32),

            // Instructions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        "How to use:",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "• Tap the microphone and speak your order\n"
                    "• Say item names clearly (e.g., 'I want 2 biryani')\n"
                    "• The app will recognize and add items to cart\n"
                    "• Multiple languages supported\n"
                    "• Review your cart before checkout",
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF374151),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

