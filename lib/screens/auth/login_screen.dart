import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../home/dashboard_screen.dart';
import 'signup_screen.dart';
import '../../widgets/crypto888_ui.dart';

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
  bool _hidePassword = true;

  Future<void> _signIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) {
      setState(() => _status = 'Please enter both email and password.');
      return;
    }
    setState(() {
      _loading = true;
      _status = '';
    });
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
    if (msg.contains('user-not-found') ||
        msg.contains('wrong-password') ||
        msg.contains('invalid-credential')) {
      return 'Incorrect email or password.';
    }
    if (msg.contains('invalid-email')) {
      return 'Please enter a valid email address.';
    }
    if (msg.contains('too-many-requests')) {
      return 'Too many attempts. Try again later.';
    }
    return 'Login failed. Please try again.';
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
      backgroundColor: C8.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              C8Header(title: 'Log In', onBack: () => Navigator.pop(context)),
              const SizedBox(height: 24),
              const Text(
                'Welcome Back',
                style: TextStyle(
                  color: Color.fromARGB(255, 17, 8, 8),
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Log in to safely manage your digital assets.',
                style: TextStyle(color: C8.muted, fontSize: 15),
              ),
              const SizedBox(height: 32),
              const Text(
                'EMAIL ADDRESS',
                style: TextStyle(
                  color: C8.muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                cursorColor: C8.lime,
                style: const TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
                decoration: c8Input(
                  hint: 'Enter email address',
                  icon: Icons.mail_outline_rounded,
                  limeIcon: true,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'SECURE PASSWORD',
                style: TextStyle(
                  color: C8.muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: _hidePassword,
                cursorColor: C8.lime,
                style: const TextStyle(color: Color.fromARGB(255, 3, 1, 1)),
                decoration: c8Input(
                  hint: 'Enter password',
                  icon: Icons.lock_outline_rounded,
                  suffix: IconButton(
                    onPressed: () =>
                        setState(() => _hidePassword = !_hidePassword),
                    icon: Icon(
                      _hidePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: C8.muted,
                      size: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  child: const Text(
                    'Forgot Password?',
                    style: TextStyle(
                      color: C8.lime,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              if (_status.isNotEmpty) ...[
                const SizedBox(height: 8),
                C8Status(text: _status),
              ],
              const SizedBox(height: 20),
              C8PrimaryButton(
                label: 'Access Vault',
                onPressed: _signIn,
                loading: _loading,
              ),
              const SizedBox(height: 28),
              const Row(
                children: [
                  Expanded(child: Divider(color: C8.border)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'OR CONTINUE WITH',
                      style: TextStyle(color: C8.muted, fontSize: 12),
                    ),
                  ),
                  Expanded(child: Divider(color: C8.border)),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: _social(Icons.language_rounded)),
                  const SizedBox(width: 12),
                  Expanded(child: _social(Icons.apple)),
                  const SizedBox(width: 12),
                  Expanded(child: _social(Icons.fingerprint_rounded)),
                ],
              ),
              const SizedBox(height: 36),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'New to Crypto888?',
                    style: TextStyle(color: C8.muted, fontSize: 14),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SignupScreen()),
                    ),
                    child: const Text(
                      'Create Account',
                      style: TextStyle(
                        color: C8.lime,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }

  Widget _social(IconData icon) => Container(
    height: 52,
    decoration: BoxDecoration(
      color: C8.card,
      border: Border.all(color: C8.border),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Icon(icon, color: const Color.fromARGB(255, 0, 0, 0), size: 24),
  );
}
