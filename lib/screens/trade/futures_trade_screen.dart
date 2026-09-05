import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/trade_model.dart';
import '../../services/auth_service.dart';
import '../../services/price_service.dart';
import '../../services/trade_service.dart';
import '../../widgets/crypto888_ui.dart';
import '../penalty/camera_capture_screen.dart';

class FuturesTradeScreen extends StatefulWidget {
  final String coinId;

  const FuturesTradeScreen({super.key, required this.coinId});

  @override
  State<FuturesTradeScreen> createState() => _FuturesTradeScreenState();
}

class _FuturesTradeScreenState extends State<FuturesTradeScreen> {
  final TextEditingController _amountController = TextEditingController(
    text: '50',
  );
  double _tradeAmount = 50.0;

  TradeDirection _selectedDirection = TradeDirection.long;
  int _selectedLeverage = 5;
  Duration _selectedDuration = const Duration(seconds: 60);

  TradeModel? _openTrade;
  bool _loading = false;
  bool _resolving = false;
  String _status = '';

  Timer? _countdownTimer;
  DateTime? _localExpiry;
  Duration _remaining = Duration.zero;

  String? get _uid => AuthService().currentUser?.uid;

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _amountController.dispose();
    super.dispose();
  }

  bool _syncTradeAmount() {
    final value = double.tryParse(_amountController.text.trim());
    if (value == null || value <= 0) {
      setState(() => _status = 'Enter a valid trade amount greater than \$0.');
      return false;
    }
    _tradeAmount = value;
    return true;
  }

  void _setQuickAmount(double amount) {
    setState(() {
      _tradeAmount = amount;
      _amountController.text = amount.toStringAsFixed(0);
      _status = '';
    });
  }

  Future<void> _openFuturesTrade() async {
    if (!_syncTradeAmount()) return;

    final uid = _uid;
    if (uid == null) {
      setState(() => _status = 'Not signed in.');
      return;
    }

    setState(() {
      _loading = true;
      _status = '';
    });

    try {
      final trade = await TradeService().openFuturesTrade(
        uid: uid,
        coinId: widget.coinId,
        direction: _selectedDirection,
        amount: _tradeAmount,
        leverage: _selectedLeverage,
        duration: _selectedDuration,
      );

      if (!mounted) return;

      final expiry = DateTime.now().add(_selectedDuration);

      setState(() {
        _openTrade = trade;
        _localExpiry = expiry;
        _remaining = _selectedDuration;
        _status =
            'Opened ${_selectedLeverage}x ${_selectedDirection.name.toUpperCase()} @ \$${trade.entryPrice.toStringAsFixed(2)}';
      });

      _startCountdown();
    } catch (e) {
      if (!mounted) return;
      setState(() => _status = 'Unable to open futures trade: $e');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _startCountdown() {
    _countdownTimer?.cancel();

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final expiry = _localExpiry;
      if (expiry == null || _openTrade == null) return;

      final difference = expiry.difference(DateTime.now());

      if (difference <= Duration.zero) {
        if (mounted) {
          setState(() => _remaining = Duration.zero);
        }
        _countdownTimer?.cancel();
        _resolveExpiredTrade();
        return;
      }

      if (mounted) {
        setState(() => _remaining = difference);
      }
    });
  }

  Future<void> _resolveExpiredTrade() async {
    final trade = _openTrade;
    if (trade == null || _resolving) return;

    setState(() => _resolving = true);

    try {
      final resolved = await TradeService().resolveFuturesIfExpired(
        tradeId: trade.tradeId,
      );

      if (!mounted) return;

      if (resolved.status == TradeStatus.open) {
        // Small clock differences can occasionally make the backend think the
        // trade is not expired yet. Try again shortly instead of losing it.
        _localExpiry = DateTime.now().add(const Duration(seconds: 2));
        _remaining = const Duration(seconds: 2);
        _startCountdown();
        return;
      }

      _countdownTimer?.cancel();

      setState(() {
        _openTrade = null;
        _localExpiry = null;
        _remaining = Duration.zero;
        _status =
            'Resolved ${resolved.status.name}. P&L: \$${resolved.pnl?.toStringAsFixed(2) ?? '0.00'}';
      });

      if (resolved.status == TradeStatus.closedLoss && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CameraCaptureScreen(
              tradeId: resolved.tradeId,
              lossAmount: resolved.amount,
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _status = 'Unable to resolve trade: $e');
    } finally {
      if (mounted) {
        setState(() => _resolving = false);
      }
    }
  }

  double _unrealizedPnl(double currentPrice) {
    final trade = _openTrade;
    if (trade == null || trade.entryPrice == 0) return 0;

    final change = (currentPrice - trade.entryPrice) / trade.entryPrice;
    final directionMultiplier = trade.direction == TradeDirection.long
        ? 1.0
        : -1.0;

    return trade.amount * change * directionMultiplier * _selectedLeverage;
  }

  String _formatDuration(Duration duration) {
    final totalSeconds = duration.inSeconds.clamp(0, 999999);
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;

    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _durationLabel(Duration duration) {
    if (duration.inMinutes >= 5) return '5 min';
    return '${duration.inSeconds}s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C8.bg,
      body: SafeArea(
        child: StreamBuilder<double>(
          stream: PriceService().watchPrice(widget.coinId),
          builder: (context, priceSnapshot) {
            final currentPrice = priceSnapshot.data;

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  C8Header(
                    title: 'Futures',
                    onBack: () => Navigator.pop(context),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    widget.coinId.toUpperCase(),
                    style: const TextStyle(
                      color: C8.muted,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Futures Position',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Choose direction, leverage, and duration. The position automatically resolves when the countdown reaches zero.',
                    style: TextStyle(color: C8.muted, height: 1.4),
                  ),
                  const SizedBox(height: 24),

                  _PriceCard(
                    price: currentPrice,
                    loading:
                        priceSnapshot.connectionState ==
                            ConnectionState.waiting &&
                        currentPrice == null,
                  ),

                  const SizedBox(height: 18),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: C8.card,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: C8.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'INVESTMENT',
                          style: TextStyle(
                            color: C8.muted,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _amountController,
                          enabled: _openTrade == null && !_loading,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                          onChanged: (value) {
                            final parsed = double.tryParse(value);
                            if (parsed != null && parsed > 0) {
                              _tradeAmount = parsed;
                            }
                          },
                          decoration: InputDecoration(
                            prefixText: '\$ ',
                            prefixStyle: const TextStyle(
                              color: C8.lime,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                            hintText: 'Enter amount',
                            hintStyle: const TextStyle(color: C8.muted),
                            filled: true,
                            fillColor: C8.bg.withValues(alpha: 0.45),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: C8.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: C8.lime),
                            ),
                            disabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: C8.border),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            for (final amount in const [
                              10.0,
                              50.0,
                              100.0,
                              500.0,
                            ]) ...[
                              Expanded(
                                child: _AmountChip(
                                  label: '\$${amount.toStringAsFixed(0)}',
                                  selected:
                                      (_tradeAmount - amount).abs() < 0.001,
                                  onTap: _openTrade == null && !_loading
                                      ? () => _setQuickAmount(amount)
                                      : null,
                                ),
                              ),
                              if (amount != 500.0) const SizedBox(width: 8),
                            ],
                          ],
                        ),
                        const SizedBox(height: 22),

                        const Text(
                          'DIRECTION',
                          style: TextStyle(
                            color: C8.muted,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _SelectionButton(
                                label: 'LONG',
                                icon: Icons.trending_up_rounded,
                                selected:
                                    _selectedDirection == TradeDirection.long,
                                positive: true,
                                onTap: _openTrade == null && !_loading
                                    ? () {
                                        setState(() {
                                          _selectedDirection =
                                              TradeDirection.long;
                                        });
                                      }
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _SelectionButton(
                                label: 'SHORT',
                                icon: Icons.trending_down_rounded,
                                selected:
                                    _selectedDirection == TradeDirection.short,
                                positive: false,
                                onTap: _openTrade == null && !_loading
                                    ? () {
                                        setState(() {
                                          _selectedDirection =
                                              TradeDirection.short;
                                        });
                                      }
                                    : null,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 22),
                        const Text(
                          'LEVERAGE',
                          style: TextStyle(
                            color: C8.muted,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            for (final leverage in const [2, 5, 10]) ...[
                              Expanded(
                                child: _OptionChip(
                                  label: '${leverage}x',
                                  selected: _selectedLeverage == leverage,
                                  onTap: _openTrade == null && !_loading
                                      ? () {
                                          setState(() {
                                            _selectedLeverage = leverage;
                                          });
                                        }
                                      : null,
                                ),
                              ),
                              if (leverage != 10) const SizedBox(width: 10),
                            ],
                          ],
                        ),

                        const SizedBox(height: 22),
                        const Text(
                          'DURATION',
                          style: TextStyle(
                            color: C8.muted,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            for (final duration in const [
                              Duration(seconds: 30),
                              Duration(seconds: 60),
                              Duration(minutes: 5),
                            ]) ...[
                              Expanded(
                                child: _OptionChip(
                                  label: _durationLabel(duration),
                                  selected: _selectedDuration == duration,
                                  onTap: _openTrade == null && !_loading
                                      ? () {
                                          setState(() {
                                            _selectedDuration = duration;
                                          });
                                        }
                                      : null,
                                ),
                              ),
                              if (duration != const Duration(minutes: 5))
                                const SizedBox(width: 10),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  if (_openTrade == null)
                    C8PrimaryButton(
                      label:
                          'Open ${_selectedLeverage}x ${_selectedDirection.name.toUpperCase()}',
                      onPressed: _openFuturesTrade,
                      loading: _loading,
                      icon: Icons.bolt_rounded,
                    )
                  else
                    _OpenFuturesPositionCard(
                      trade: _openTrade!,
                      currentPrice: currentPrice,
                      leverage: _selectedLeverage,
                      durationLabel: _durationLabel(_selectedDuration),
                      countdown: _formatDuration(_remaining),
                      unrealizedPnl: currentPrice == null
                          ? null
                          : _unrealizedPnl(currentPrice),
                      resolving: _resolving,
                    ),

                  if (_status.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    C8Status(
                      text: _status,
                      success:
                          _status.startsWith('Opened') ||
                          _status.startsWith('Resolved'),
                    ),
                  ],

                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PriceCard extends StatelessWidget {
  final double? price;
  final bool loading;

  const _PriceCard({required this.price, required this.loading});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: C8.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: C8.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'LIVE PRICE',
            style: TextStyle(
              color: C8.muted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          if (loading)
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2, color: C8.lime),
            )
          else
            Text(
              price == null
                  ? 'Price unavailable'
                  : '\$${price!.toStringAsFixed(2)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
        ],
      ),
    );
  }
}

class _AmountChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const _AmountChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? C8.lime.withValues(alpha: 0.12)
              : C8.bg.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? C8.lime : C8.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? C8.lime : Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _SelectionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final bool positive;
  final VoidCallback? onTap;

  const _SelectionButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.positive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = positive ? C8.green : C8.red;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 52,
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.12)
              : C8.bg.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? color : C8.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: selected ? color : C8.muted, size: 19),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: selected ? color : Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const _OptionChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? C8.lime.withValues(alpha: 0.12)
              : C8.bg.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? C8.lime : C8.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? C8.lime : Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _OpenFuturesPositionCard extends StatelessWidget {
  final TradeModel trade;
  final double? currentPrice;
  final int leverage;
  final String durationLabel;
  final String countdown;
  final double? unrealizedPnl;
  final bool resolving;

  const _OpenFuturesPositionCard({
    required this.trade,
    required this.currentPrice,
    required this.leverage,
    required this.durationLabel,
    required this.countdown,
    required this.unrealizedPnl,
    required this.resolving,
  });

  @override
  Widget build(BuildContext context) {
    final isLong = trade.direction == TradeDirection.long;
    final directionColor = isLong ? C8.green : C8.red;
    final pnl = unrealizedPnl;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: C8.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: C8.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'OPEN POSITION',
                style: TextStyle(
                  color: C8.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: directionColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${trade.direction.name.toUpperCase()} • ${leverage}x',
                  style: TextStyle(
                    color: directionColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _RowMetric(
            label: 'Amount',
            value: '\$${trade.amount.toStringAsFixed(2)}',
          ),
          const SizedBox(height: 10),
          _RowMetric(
            label: 'Entry',
            value: '\$${trade.entryPrice.toStringAsFixed(2)}',
          ),
          const SizedBox(height: 10),
          _RowMetric(
            label: 'Current',
            value: currentPrice == null
                ? 'Loading...'
                : '\$${currentPrice!.toStringAsFixed(2)}',
          ),
          const SizedBox(height: 10),
          _RowMetric(label: 'Duration', value: durationLabel),
          const SizedBox(height: 10),
          _RowMetric(
            label: 'Unrealized P&L',
            value: pnl == null
                ? 'Loading...'
                : '${pnl >= 0 ? '+' : ''}\$${pnl.toStringAsFixed(2)}',
            valueColor: pnl == null
                ? C8.muted
                : pnl >= 0
                ? C8.green
                : C8.red,
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            decoration: BoxDecoration(
              color: C8.lime.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: C8.lime.withValues(alpha: 0.35)),
            ),
            child: Column(
              children: [
                const Text(
                  'TIME REMAINING',
                  style: TextStyle(
                    color: C8.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  resolving ? 'Resolving...' : countdown,
                  style: const TextStyle(
                    color: C8.lime,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Center(
            child: Text(
              'Position automatically closes at 00:00',
              style: TextStyle(color: C8.muted, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _RowMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _RowMetric({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: C8.muted, fontSize: 13)),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
