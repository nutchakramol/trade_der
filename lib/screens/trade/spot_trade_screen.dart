import 'package:flutter/material.dart';

import '../../models/trade_model.dart';
import '../../services/auth_service.dart';
import '../../services/price_service.dart';
import '../../services/trade_service.dart';
import '../../widgets/crypto888_ui.dart';
import '../penalty/camera_capture_screen.dart';

class SpotTradeScreen extends StatefulWidget {
  final String coinId;

  const SpotTradeScreen({super.key, required this.coinId});

  @override
  State<SpotTradeScreen> createState() => _SpotTradeScreenState();
}

class _SpotTradeScreenState extends State<SpotTradeScreen> {
  final TextEditingController _amountController = TextEditingController(
    text: '50',
  );
  double _tradeAmount = 50.0;

  TradeDirection _selectedDirection = TradeDirection.long;
  TradeModel? _openTrade;
  bool _loading = false;
  String _status = '';

  String? get _uid => AuthService().currentUser?.uid;

  @override
  void dispose() {
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

  Future<void> _openSpotTrade() async {
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
      final trade = await TradeService().openSpotTrade(
        uid: uid,
        coinId: widget.coinId,
        direction: _selectedDirection,
        amount: _tradeAmount,
      );

      if (!mounted) return;

      setState(() {
        _openTrade = trade;
        _status =
            'Opened ${trade.direction.name.toUpperCase()} @ \$${trade.entryPrice.toStringAsFixed(2)}';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _status = 'Unable to open trade: $e');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _closeTrade() async {
    final trade = _openTrade;
    if (trade == null) return;

    setState(() {
      _loading = true;
      _status = '';
    });

    try {
      final closed = await TradeService().closeTrade(tradeId: trade.tradeId);

      if (!mounted) return;

      setState(() {
        _openTrade = null;
        _status =
            'Closed ${closed.status.name}. P&L: \$${closed.pnl?.toStringAsFixed(2) ?? '0.00'}';
      });

      if (closed.status == TradeStatus.closedLoss && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CameraCaptureScreen(
              tradeId: closed.tradeId,
              lossAmount: closed.amount,
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _status = 'Unable to close trade: $e');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
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

    return trade.amount * change * directionMultiplier;
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
                    title: 'Spot Trade',
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
                    'Spot Position',
                    style: TextStyle(
                      color: Color.fromARGB(255, 0, 0, 0),
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Choose Long or Short. Spot trades have no expiry, so you close the position manually.',
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
                            color: Color.fromARGB(255, 0, 0, 0),
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
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  if (_openTrade == null)
                    C8PrimaryButton(
                      label:
                          'Open ${_selectedDirection.name.toUpperCase()} Spot Trade',
                      onPressed: _openSpotTrade,
                      loading: _loading,
                      icon: _selectedDirection == TradeDirection.long
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                    )
                  else ...[
                    _OpenSpotPositionCard(
                      trade: _openTrade!,
                      currentPrice: currentPrice,
                      unrealizedPnl: currentPrice == null
                          ? null
                          : _unrealizedPnl(currentPrice),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton.icon(
                        onPressed: _loading ? null : _closeTrade,
                        icon: const Icon(Icons.close_rounded),
                        label: _loading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: C8.red,
                                ),
                              )
                            : const Text(
                                'Close Position',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: C8.red,
                          backgroundColor: C8.red.withValues(alpha: 0.08),
                          side: const BorderSide(color: C8.red),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],

                  if (_status.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    C8Status(
                      text: _status,
                      success:
                          _status.startsWith('Opened') ||
                          _status.startsWith('Closed'),
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
                color: Color.fromARGB(255, 0, 0, 0),
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
            color: selected ? C8.lime : const Color.fromARGB(255, 0, 0, 0),
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
                color: selected ? color : const Color.fromARGB(255, 0, 0, 0),
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OpenSpotPositionCard extends StatelessWidget {
  final TradeModel trade;
  final double? currentPrice;
  final double? unrealizedPnl;

  const _OpenSpotPositionCard({
    required this.trade,
    required this.currentPrice,
    required this.unrealizedPnl,
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
                  trade.direction.name.toUpperCase(),
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
          const SizedBox(height: 14),
          const Text(
            'No expiry • Close manually',
            style: TextStyle(color: C8.muted, fontSize: 12),
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
            color: valueColor ?? const Color.fromARGB(255, 0, 0, 0),
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
