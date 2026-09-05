import 'dart:math';

import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../services/bank_service.dart';
import '../../widgets/crypto888_ui.dart';

class RouletteScreen extends StatefulWidget {
  const RouletteScreen({super.key});

  @override
  State<RouletteScreen> createState() => _RouletteScreenState();
}

class _RouletteScreenState extends State<RouletteScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _wagerController = TextEditingController();
  final Random _random = Random();

  late final AnimationController _controller;
  late Animation<double> _rotation;

  final List<double> _multipliers = const [0, 0.5, 1, 1.5, 2, 3, 5, 10];

  bool _spinning = false;
  String _status = 'Enter a wager before spinning.';
  double? _lastMultiplier;
  double? _lastPayout;

  String? get _uid => AuthService().currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2700),
    );
    _rotation = const AlwaysStoppedAnimation(0);
  }

  @override
  void dispose() {
    _wagerController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _spin() async {
    if (_spinning) return;

    final uid = _uid;
    if (uid == null) {
      setState(() => _status = 'You must be signed in to play.');
      return;
    }

    final wager = double.tryParse(_wagerController.text.trim());
    if (wager == null || wager <= 0) {
      setState(() => _status = 'Enter a valid wager greater than \$0 first.');
      return;
    }

    final balance = await BankService().watchBalance(uid).first;
    if (!mounted) return;

    if (wager > balance) {
      setState(() => _status = 'Wager cannot exceed your available balance.');
      return;
    }

    final index = _random.nextInt(_multipliers.length);
    final multiplier = _multipliers[index];
    final payout = wager * multiplier;

    setState(() {
      _spinning = true;
      _status = 'Wheel spinning…';
      _lastMultiplier = null;
      _lastPayout = null;
    });

    await BankService().adjustBalance(uid, -wager);

    final start = _rotation.value;
    final extraTurns = 6 + _random.nextInt(3);
    final segmentAngle = 2 * pi / _multipliers.length;
    final targetSegmentCenter = index * segmentAngle + segmentAngle / 2;
    final target = start + extraTurns * 2 * pi + (2 * pi - targetSegmentCenter);

    _rotation = Tween<double>(
      begin: start,
      end: target,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.reset();
    try {
      await _controller.forward().orCancel;
    } catch (_) {
      return;
    }

    if (payout > 0) {
      await BankService().adjustBalance(uid, payout);
    }

    if (!mounted) return;

    setState(() {
      _spinning = false;
      _lastMultiplier = multiplier;
      _lastPayout = payout;
      final net = payout - wager;
      if (net > 0) {
        _status = 'You won +\$${net.toStringAsFixed(2)} net profit!';
      } else if (net == 0) {
        _status = 'Break-even spin. Your wager was returned.';
      } else {
        _status = 'You lost \$${(-net).toStringAsFixed(2)} this spin.';
      }
    });
  }

  void _setQuickWager(int amount) {
    if (_spinning) return;
    _wagerController.text = amount.toString();
    setState(() => _status = 'Wager set to \$$amount. Ready to spin.');
  }

  @override
  Widget build(BuildContext context) {
    final uid = _uid;

    return Scaffold(
      backgroundColor: C8.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              C8Header(
                title: 'Spinning Roulette',
                onBack: () => Navigator.pop(context),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Multiply Your Funds',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Set your wager first. The spin button remains unavailable until you enter a valid amount.',
                          style: TextStyle(color: C8.muted, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 78,
                    height: 78,
                    child: Image.asset(
                      'assets/images/baby_tweety.png',
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => Container(
                        decoration: BoxDecoration(
                          color: C8.lime.withValues(alpha: .10),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: C8.lime),
                        ),
                        child: const Icon(
                          Icons.flutter_dash_rounded,
                          color: C8.lime,
                          size: 44,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              if (uid != null)
                StreamBuilder<double>(
                  stream: BankService().watchBalance(uid),
                  builder: (context, snapshot) {
                    final balance = snapshot.data ?? 0;
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: C8.card,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: C8.border),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Available Balance',
                            style: TextStyle(color: C8.muted),
                          ),
                          Text(
                            '\$${balance.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: balance < 0 ? C8.red : Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              const SizedBox(height: 24),
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _rotation,
                      builder: (_, child) => Transform.rotate(
                        angle: _rotation.value,
                        child: child,
                      ),
                      child: CustomPaint(
                        size: const Size.square(280),
                        painter: _RoulettePainter(_multipliers),
                      ),
                    ),
                    Container(
                      width: 74,
                      height: 74,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: C8.bg,
                        boxShadow: [
                          BoxShadow(color: Colors.black54, blurRadius: 18),
                        ],
                      ),
                      child: const Icon(
                        Icons.casino_rounded,
                        color: C8.lime,
                        size: 36,
                      ),
                    ),
                    const Positioned(
                      top: -2,
                      child: Icon(
                        Icons.arrow_drop_down_rounded,
                        color: Colors.white,
                        size: 46,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'WAGER AMOUNT',
                style: TextStyle(
                  color: C8.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _wagerController,
                enabled: !_spinning,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
                onChanged: (_) => setState(() {}),
                decoration: c8Input(
                  hint: 'Enter wager before spinning',
                  icon: Icons.attach_money_rounded,
                  limeIcon: true,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [10, 25, 50, 100]
                    .map(
                      (amount) => ActionChip(
                        label: Text('\$$amount'),
                        onPressed: _spinning
                            ? null
                            : () => _setQuickWager(amount),
                        backgroundColor: C8.card,
                        side: const BorderSide(color: C8.border),
                        labelStyle: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),
              if (_lastMultiplier != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: C8.lime.withValues(alpha: .08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: C8.lime.withValues(alpha: .35)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Result: ${_lastMultiplier}x',
                        style: const TextStyle(
                          color: C8.lime,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Payout: \$${_lastPayout!.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),
              C8Status(
                text: _status,
                success:
                    _status.startsWith('You won') ||
                    _status.startsWith('Break-even') ||
                    _status.startsWith('Wager set'),
              ),
              const SizedBox(height: 14),
              C8PrimaryButton(
                label: _spinning ? 'Spinning…' : 'Spin Roulette',
                icon: Icons.casino_rounded,
                loading: _spinning,
                onPressed: _wagerController.text.trim().isEmpty || _spinning
                    ? null
                    : _spin,
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoulettePainter extends CustomPainter {
  final List<double> values;

  _RoulettePainter(this.values);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final segment = 2 * pi / values.length;
    final rect = Rect.fromCircle(center: center, radius: radius);

    for (var i = 0; i < values.length; i++) {
      final paint = Paint()
        ..color = i.isEven ? C8.card : C8.border
        ..style = PaintingStyle.fill;

      canvas.drawArc(rect, -pi / 2 + i * segment, segment, true, paint);

      final borderPaint = Paint()
        ..color = C8.bg
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;

      canvas.drawArc(rect, -pi / 2 + i * segment, segment, true, borderPaint);

      final angle = -pi / 2 + (i + .5) * segment;
      final textRadius = radius * .70;
      final textOffset = Offset(
        center.dx + cos(angle) * textRadius,
        center.dy + sin(angle) * textRadius,
      );

      final painter = TextPainter(
        text: TextSpan(
          text: '${values[i]}x',
          style: const TextStyle(
            color: C8.lime,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      painter.paint(
        canvas,
        textOffset - Offset(painter.width / 2, painter.height / 2),
      );
    }

    canvas.drawCircle(
      center,
      radius - 1,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = C8.lime,
    );
  }

  @override
  bool shouldRepaint(covariant _RoulettePainter oldDelegate) => false;
}
