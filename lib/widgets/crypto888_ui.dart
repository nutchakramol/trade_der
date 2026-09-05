import 'dart:async';

import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/bank_service.dart';

class C8 {
  static const bg = Color.fromARGB(255, 244, 243, 243);
  static const card = Color.fromARGB(255, 226, 220, 220);
  static const ink = Color(0xFF111111);
  static const border = Color(0xFFE7E9EE);
  static const lime = Color.fromARGB(255, 120, 97, 182);
  static const limeSoft = Color(0xFFF5FFD0);
  static const muted = Color.fromARGB(255, 0, 0, 0);
  static const green = Color(0xFF35C86F);
  static const red = Color(0xFFF06A93);

  static const softShadow = <BoxShadow>[
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
  ];
}

class C8Header extends StatelessWidget {
  const C8Header({
    super.key,
    required this.title,
    this.leading,
    this.trailing,
    this.onBack,
    this.action,
  });

  final String title;

  // New API
  final Widget? leading;
  final Widget? trailing;

  // Backward-compatible API used by the existing screens.
  final VoidCallback? onBack;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final effectiveLeading = leading ??
        (onBack == null
            ? null
            : IconButton(
                onPressed: onBack,
                tooltip: 'Back',
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: C8.ink,
                ),
              ));

    final effectiveTrailing = trailing ?? action;

    return Stack(
      children: [
        Container(
          constraints: const BoxConstraints(minHeight: 68),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: const BoxDecoration(
            color: C8.bg,
            border: Border(
              bottom: BorderSide(color: C8.border),
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 48,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: effectiveLeading,
                ),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Crypto888',
                      style: TextStyle(
                        color: C8.ink,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      title,
                      style: const TextStyle(
                        color: C8.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 48,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: effectiveTrailing,
                ),
              ),
            ],
          ),
        ),
        const C8NegativeBalanceGuard(),
      ],
    );
  }
}

InputDecoration c8Input({
  String? label,
  String? hint,

  // New API
  Widget? prefixIcon,
  Widget? suffixIcon,

  // Backward-compatible API.
  IconData? icon,
  bool limeIcon = false,
  Widget? suffix,
}) {
  final effectivePrefix = prefixIcon ??
      (icon == null
          ? null
          : Icon(
              icon,
              color: limeIcon ? C8.ink : C8.muted,
              size: 20,
            ));

  return InputDecoration(
    labelText: label,
    hintText: hint,
    prefixIcon: effectivePrefix,
    suffixIcon: suffixIcon ?? suffix,
    labelStyle: const TextStyle(
      color: C8.muted,
      fontWeight: FontWeight.w600,
    ),
    hintStyle: const TextStyle(color: C8.muted),
    filled: true,
    fillColor: C8.card,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 16,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: C8.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(
        color: C8.ink,
        width: 1.4,
      ),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: C8.red),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(
        color: C8.red,
        width: 1.4,
      ),
    ),
  );
}

class C8PrimaryButton extends StatelessWidget {
  const C8PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: loading ? null : onPressed,
        icon: loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: C8.ink,
                ),
              )
            : Icon(icon ?? Icons.arrow_forward_rounded),
        iconAlignment: IconAlignment.end,
        label: Text(label),
      ),
    );
  }
}

class C8Status extends StatelessWidget {
  const C8Status({
    super.key,
    required this.text,
    this.success = false,
  });

  final String text;

  // Backward-compatible parameter used by existing screens.
  final bool success;

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) {
      return const SizedBox.shrink();
    }

    final accent = success ? C8.green : C8.lime;
    final background =
        success ? C8.green.withValues(alpha: 0.10) : C8.limeSoft;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            success
                ? Icons.check_circle_outline_rounded
                : Icons.info_outline_rounded,
            color: success ? C8.green : C8.ink,
            size: 18,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: success ? C8.green : C8.ink,
                fontSize: 12,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class C8NegativeBalanceGuard extends StatefulWidget {
  const C8NegativeBalanceGuard({super.key});

  @override
  State<C8NegativeBalanceGuard> createState() =>
      _C8NegativeBalanceGuardState();
}

class _C8NegativeBalanceGuardState extends State<C8NegativeBalanceGuard> {
  StreamSubscription<double>? _subscription;
  bool _dialogOpen = false;
  bool _acknowledged = false;

  @override
  void initState() {
    super.initState();

    final uid = AuthService().currentUser?.uid;
    if (uid == null) return;

    _subscription = BankService().watchBalance(uid).listen((balance) {
      if (!mounted) return;

      if (balance >= 0) {
        _acknowledged = false;
        return;
      }

      if (!_dialogOpen && !_acknowledged) {
        _showDebtDialog(balance);
      }
    });
  }

  Future<void> _showDebtDialog(double balance) async {
    _dialogOpen = true;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: C8.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          icon: Container(
            width: 58,
            height: 58,
            decoration: const BoxDecoration(
              color: C8.limeSoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.local_police_rounded,
              color: C8.ink,
              size: 30,
            ),
          ),
          title: const Text(
            'Account warning',
            style: TextStyle(
              color: C8.ink,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Text(
            'Your balance is \$${balance.toStringAsFixed(2)}. '
            'The account is now in debt / liquidation status.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: C8.muted,
              height: 1.45,
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('I understand'),
            ),
          ],
        );
      },
    );

    if (mounted) {
      _acknowledged = true;
      _dialogOpen = false;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

ThemeData crypto888Theme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: C8.lime,
    brightness: Brightness.light,
    primary: C8.ink,
    surface: C8.card,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: C8.bg,
    colorScheme: scheme,
    fontFamily: 'SUSEMono',
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        color: C8.ink,
        fontWeight: FontWeight.w800,
      ),
      headlineMedium: TextStyle(
        color: C8.ink,
        fontWeight: FontWeight.w800,
      ),
      titleLarge: TextStyle(
        color: C8.ink,
        fontWeight: FontWeight.w800,
      ),
      titleMedium: TextStyle(
        color: C8.ink,
        fontWeight: FontWeight.w700,
      ),
      bodyLarge: TextStyle(
        color: C8.ink,
        fontWeight: FontWeight.w500,
      ),
      bodyMedium: TextStyle(
        color: C8.ink,
        fontWeight: FontWeight.w500,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: C8.lime,
        foregroundColor: C8.ink,
        elevation: 0,
        textStyle: const TextStyle(
          fontWeight: FontWeight.w800,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: C8.ink,
        backgroundColor: C8.card,
        side: const BorderSide(color: C8.border),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w800,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: C8.ink,
        textStyle: const TextStyle(
          fontWeight: FontWeight.w800,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: C8.card,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: C8.border),
      ),
    ),
    cardTheme: CardThemeData(
      color: C8.card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: C8.border),
      ),
    ),
    dividerColor: C8.border,
  );
}
