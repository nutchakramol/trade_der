import 'dart:async';

import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/bank_service.dart';

class C8 {
  static const bg = Color(0xFF090D1A);
  static const card = Color(0xFF141A29);
  static const border = Color(0xFF222D3D);
  static const lime = Color(0xFFF8FF74);
  static const muted = Color(0xFF8A99AD);
  static const green = Color(0xFF00F5A0);
  static const red = Color(0xFFFF5C6C);
}

class C8Header extends StatelessWidget {
  final String title;
  final VoidCallback? onBack;
  final Widget? action;

  const C8Header({super.key, required this.title, this.onBack, this.action});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const C8NegativeBalanceGuard(),
        Container(
          height: 72,
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: C8.border)),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 44,
                child: onBack == null
                    ? const SizedBox.shrink()
                    : InkWell(
                        onTap: onBack,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: C8.card,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: C8.border),
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Text(
                          'Crypto888',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            letterSpacing: .2,
                          ),
                        ),
                        SizedBox(width: 8),
                        _C8ProBadge(),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: C8.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 44, height: 44, child: action),
            ],
          ),
        ),
      ],
    );
  }
}

class _C8ProBadge extends StatelessWidget {
  const _C8ProBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: C8.lime.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: C8.lime, width: .6),
      ),
      child: const Text(
        'PRO',
        style: TextStyle(
          color: C8.lime,
          fontSize: 9,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class C8NegativeBalanceGuard extends StatefulWidget {
  const C8NegativeBalanceGuard({super.key});

  @override
  State<C8NegativeBalanceGuard> createState() => _C8NegativeBalanceGuardState();
}

class _C8NegativeBalanceGuardState extends State<C8NegativeBalanceGuard> {
  StreamSubscription<double>? _subscription;
  bool _dialogOpen = false;
  bool _negativeStateAcknowledged = false;

  @override
  void initState() {
    super.initState();
    _startListening();
  }

  void _startListening() {
    final uid = AuthService().currentUser?.uid;
    if (uid == null) return;

    _subscription = BankService().watchBalance(uid).listen((balance) {
      if (!mounted) return;

      if (balance >= 0) {
        _negativeStateAcknowledged = false;
        return;
      }

      if (_dialogOpen || _negativeStateAcknowledged) return;
      _negativeStateAcknowledged = true;
      _showNegativeBalanceWarning(balance);
    });
  }

  Future<void> _showNegativeBalanceWarning(double balance) async {
    if (!mounted) return;
    _dialogOpen = true;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: C8.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: const BorderSide(color: C8.red),
          ),
          title: const Row(
            children: [
              Icon(Icons.local_police_rounded, color: C8.red, size: 34),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Police Warning',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: C8.red.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: C8.red.withValues(alpha: .35)),
                ),
                child: Text(
                  'Current balance: -\$${balance.abs().toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: C8.red,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Your account has entered a negative balance. This indicates liquidation or debt status in the simulator. Add funds or resolve the outstanding balance before taking more risk.',
                style: TextStyle(color: C8.muted, height: 1.45),
              ),
            ],
          ),
          actions: [
            FilledButton.icon(
              onPressed: () => Navigator.pop(dialogContext),
              icon: const Icon(Icons.warning_amber_rounded),
              label: const Text('I Understand'),
              style: FilledButton.styleFrom(
                backgroundColor: C8.red,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );

    _dialogOpen = false;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

InputDecoration c8Input({
  required String hint,
  IconData? icon,
  Widget? suffix,
  bool limeIcon = false,
}) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: C8.muted, fontSize: 15),
    prefixIcon: icon == null
        ? null
        : Icon(icon, size: 20, color: limeIcon ? C8.lime : C8.muted),
    suffixIcon: suffix,
    filled: true,
    fillColor: C8.card,
    counterText: '',
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: C8.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: C8.lime),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: C8.red),
    ),
  );
}

class C8PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;

  const C8PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final child = loading
        ? const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2, color: C8.bg),
          )
        : Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          );

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: icon == null
          ? ElevatedButton(
              onPressed: loading ? null : onPressed,
              style: _buttonStyle(),
              child: child,
            )
          : ElevatedButton.icon(
              onPressed: loading ? null : onPressed,
              icon: Icon(icon, size: 18),
              label: child,
              style: _buttonStyle(),
            ),
    );
  }

  ButtonStyle _buttonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: C8.lime,
      foregroundColor: C8.bg,
      disabledBackgroundColor: C8.lime.withValues(alpha: .45),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }
}

class C8Status extends StatelessWidget {
  final String text;
  final bool success;

  const C8Status({super.key, required this.text, this.success = false});

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();
    final color = success ? C8.green : C8.red;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: .35)),
      ),
      child: Row(
        children: [
          Icon(
            success ? Icons.check_circle_outline : Icons.error_outline,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: TextStyle(color: color, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
