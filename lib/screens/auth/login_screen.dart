import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../home/dashboard_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _status = '';
  bool _loading = false;

  Future<void> _signIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => _status = 'Please enter both email and password.');
      return;
    }

    setState(() { _loading = true; _status = ''; });
    try {
      await AuthService().signIn(email: email, password: password);
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
    if (msg.contains('user-not-found') || msg.contains('wrong-password') || msg.contains('invalid-credential')) {
      return 'Incorrect email or password.';
    }
    if (msg.contains('invalid-email')) {
      return 'Please enter a valid email address.';
    }
    if (msg.contains('too-many-requests')) {
      return 'Too many attempts. Try again later.';
    }
    return 'Error: $msg';
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Crypto Trade Sim',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 32),
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
              const SizedBox(height: 24),
              _loading
                  ? const CircularProgressIndicator()
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(onPressed: _signIn, child: const Text('Log In')),
                    ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.push(
                    context, MaterialPageRoute(builder: (_) => const SignupScreen())),
                child: const Text("Don't have an account? Sign up"),
              ),
              if (_status.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(_status, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
              ],
            ],
          ),
        ),
      ),
    );
  }
}