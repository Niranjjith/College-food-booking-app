import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/user.dart';
import 'login_screen.dart';
import 'subscription_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? user;
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  bool loading = false;
  String message = "";

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() async {
    final u = await ApiService.getProfile();
    if (u != null) {
      setState(() {
        user = u;
        emailCtrl.text = u.email;
      });
    }
  }

  void _updateProfile() async {
    setState(() { loading = true; message = ""; });
    final updated = await ApiService.updateProfile(emailCtrl.text, passCtrl.text);
    setState(() {
      loading = false;
      message = updated != null ? "✅ Profile updated" : "❌ Failed to update";
    });
  }

  void _logout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Profile")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Profile Header
            Center(
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 50,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user!.name ?? 'User',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user!.email,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            
            // Form Fields
            const Text(
              "Update Profile",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 20),
            
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: "Email",
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: 16),
            
            TextField(
              controller: passCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "New Password (leave empty to keep current)",
                prefixIcon: Icon(Icons.lock_outlined),
              ),
            ),
            const SizedBox(height: 24),
            
            // Message
            if (message.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: message.contains("✅")
                      ? const Color(0xFF10B981).withOpacity(0.1)
                      : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: message.contains("✅")
                        ? const Color(0xFF10B981).withOpacity(0.3)
                        : Colors.red.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      message.contains("✅") ? Icons.check_circle : Icons.error_outline,
                      color: message.contains("✅")
                          ? const Color(0xFF10B981)
                          : Colors.red.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        message,
                        style: TextStyle(
                          color: message.contains("✅")
                              ? const Color(0xFF10B981)
                              : Colors.red.shade700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (message.isNotEmpty) const SizedBox(height: 16),
            
            // Save Button
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: loading ? null : _updateProfile,
                child: loading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text("Save Changes"),
              ),
            ),
            const SizedBox(height: 24),
            
            // Logout Button
            SizedBox(
              height: 56,
              child: OutlinedButton(
                onPressed: _logout,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.red.shade300),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  "Logout",
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
