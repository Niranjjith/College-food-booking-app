import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  bool loading = false;
  String error = "";

  void _login() async {
    setState(() { loading = true; error = ""; });
    final user = await ApiService.login(emailCtrl.text, passCtrl.text);
    setState(() { loading = false; });
    if (user != null) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
    } else {
      setState(() { error = "Invalid email or password"; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: "Email")),
            TextField(controller: passCtrl, decoration: const InputDecoration(labelText: "Password"), obscureText: true),
            const SizedBox(height: 20),
            if (error.isNotEmpty) Text(error, style: const TextStyle(color: Colors.red)),
            ElevatedButton(onPressed: loading ? null : _login, child: loading ? const CircularProgressIndicator() : const Text("Login")),
            TextButton(onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen()));
            }, child: const Text("No account? Register"))
          ],
        ),
      ),
    );
  }
}
