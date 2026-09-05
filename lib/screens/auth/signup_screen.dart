import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../home/dashboard_screen.dart';
import '../../widgets/crypto888_ui.dart';

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
  bool _hidePassword = true;
  bool _hideConfirm = true;

  Future<void> _signUp() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirm = _confirmController.text.trim();
    if (email.isEmpty || password.isEmpty || confirm.isEmpty) {
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
    setState(() {
      _loading = true;
      _status = '';
    });
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
    return 'Sign up failed. Please try again.';
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
      backgroundColor: C8.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              C8Header(
                title: 'Create Account',
                onBack: () => Navigator.pop(context),
              ),
              const SizedBox(height: 24),
              const Text(
                'Join Crypto888',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Create your account and start trading with virtual funds.',
                style: TextStyle(color: C8.muted, fontSize: 15, height: 1.4),
              ),
              const SizedBox(height: 32),
              _label('EMAIL ADDRESS'),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                cursorColor: C8.lime,
                style: const TextStyle(color: Colors.white),
                decoration: c8Input(
                  hint: 'you@example.com',
                  icon: Icons.mail_outline_rounded,
                  limeIcon: true,
                ),
              ),
              const SizedBox(height: 20),
              _label('PASSWORD'),
              TextField(
                controller: _passwordController,
                obscureText: _hidePassword,
                cursorColor: C8.lime,
                style: const TextStyle(color: Colors.white),
                decoration: c8Input(
                  hint: 'At least 6 characters',
                  icon: Icons.lock_outline_rounded,
                  suffix: IconButton(
                    onPressed: () =>
                        setState(() => _hidePassword = !_hidePassword),
                    icon: Icon(
                      _hidePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: C8.muted,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _label('CONFIRM PASSWORD'),
              TextField(
                controller: _confirmController,
                obscureText: _hideConfirm,
                cursorColor: C8.lime,
                style: const TextStyle(color: Colors.white),
                decoration: c8Input(
                  hint: 'Re-enter password',
                  icon: Icons.verified_user_outlined,
                  suffix: IconButton(
                    onPressed: () =>
                        setState(() => _hideConfirm = !_hideConfirm),
                    icon: Icon(
                      _hideConfirm
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: C8.muted,
                    ),
                  ),
                ),
              ),
              if (_status.isNotEmpty) ...[
                const SizedBox(height: 20),
                C8Status(text: _status),
              ],
              const SizedBox(height: 28),
              C8PrimaryButton(
                label: 'Create Account',
                onPressed: _signUp,
                loading: _loading,
              ),
              const SizedBox(height: 18),
              const Center(
                child: Text(
                  'New accounts start with virtual trading funds.',
                  style: TextStyle(color: C8.muted, fontSize: 12),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: const TextStyle(
        color: C8.muted,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}
