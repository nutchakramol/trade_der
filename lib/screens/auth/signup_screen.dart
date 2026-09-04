import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../home/dashboard_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  String _status = '';
  bool _loading = false;

  Future<void> _signUp() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirm = _confirmController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => _status = 'Please fill in all fields.');
      return;
    }
    if (password.length < 6) {
      setState(() => _status = 'Password must be at least 6 characters.');
      return;
    }
    if (password != confirm) {
      setState(() => _status = 'Passwords do not match.');
      return;
    }

    setState(() { _loading = true; _status = ''; });
    try {
      await AuthService().signUp(email: email, password: password);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    } catch (e) {
      setState(() => _status = _friendlyError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _friendlyError(Object e) {
    final msg = e.toString();
    if (msg.contains('email-already-in-use')) {
      return 'An account already exists with this email.';
    }
    if (msg.contains('invalid-email')) {
      return 'Please enter a valid email address.';
    }
    if (msg.contains('weak-password')) {
      return 'Password is too weak.';
    }
    return 'Error: $msg';
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirmController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Confirm Password', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 24),
            _loading
                ? const CircularProgressIndicator()
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(onPressed: _signUp, child: const Text('Sign Up')),
                  ),
            if (_status.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(_status, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
            ],
          ],
        ),
      ),
    );
  }
}