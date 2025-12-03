import 'package:flutter/material.dart';
import '../services/api_service.dart';

class StudentIdVerificationScreen extends StatefulWidget {
  final String orderId;
  
  const StudentIdVerificationScreen({super.key, required this.orderId});

  @override
  State<StudentIdVerificationScreen> createState() => _StudentIdVerificationScreenState();
}

class _StudentIdVerificationScreenState extends State<StudentIdVerificationScreen> {
  final _studentIdController = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _verified = false;

  void _verifyStudentId() async {
    if (_studentIdController.text.isEmpty) {
      setState(() => _error = "Please enter your Student ID");
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final success = await ApiService.verifyStudentId(
      widget.orderId,
      _studentIdController.text,
    );

    setState(() {
      _loading = false;
      _verified = success;
      if (!success) {
        _error = "Verification failed. Please check your Student ID.";
      }
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Student ID verified successfully!"),
          backgroundColor: Color(0xFF10B981),
        ),
      );
      Future.delayed(const Duration(seconds: 1), () {
        Navigator.pop(context, true);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Student ID Verification"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.verified_user,
                size: 50,
                color: Color(0xFF10B981),
              ),
            ),
            const SizedBox(height: 32),

            // Title
            const Text(
              "Verify Your Identity",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              "Enter your Student ID to verify pickup",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Student ID Field
            TextField(
              controller: _studentIdController,
              decoration: const InputDecoration(
                labelText: "Student ID",
                prefixIcon: Icon(Icons.badge_outlined),
                hintText: "Enter your student identification number",
              ),
              enabled: !_verified,
            ),
            const SizedBox(height: 24),

            // Error Message
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: TextStyle(color: Colors.red.shade700, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            if (_error != null) const SizedBox(height: 16),

            // Success Message
            if (_verified)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF10B981)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Color(0xFF10B981), size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Student ID verified successfully!",
                        style: TextStyle(color: Color(0xFF10B981), fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            if (_verified) const SizedBox(height: 16),

            // Verify Button
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _loading || _verified ? null : _verifyStudentId,
                child: _loading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(_verified ? "Verified" : "Verify Student ID"),
              ),
            ),
            const SizedBox(height: 24),

            // Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        const Text(
                          "Why verify?",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Student ID verification ensures that only authorized students can pick up orders. "
                      "This helps maintain security and prevents order mix-ups.",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


