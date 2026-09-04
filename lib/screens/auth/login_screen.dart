import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../home/dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String _status = '';
  bool _loading = false;

  Future<void> _signIn() async {
    setState(() { _loading = true; _status = ''; });
    try {
      await AuthService().signIn(email: "test@test.com", password: "test1234");
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    } catch (e) {
      setState(() => _status = 'ERROR: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login (Test)')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Crypto Trade Sim',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              _loading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _signIn,
                      child: const Text('Sign In (test@test.com)'),
                    ),
              const SizedBox(height: 16),
              if (_status.isNotEmpty)
                Text(_status, style: const TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ),
    );
  }
}