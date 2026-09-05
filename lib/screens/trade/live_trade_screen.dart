import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../models/trade_model.dart';
import '../../services/auth_service.dart';
import '../../services/price_service.dart';
import '../../services/trade_service.dart';
import '../../widgets/crypto888_ui.dart';
import '../penalty/camera_capture_screen.dart';

class LiveTradeScreen extends StatefulWidget {
  final String coinId;

  const LiveTradeScreen({super.key, required this.coinId});

  @override
  State<LiveTradeScreen> createState() => _LiveTradeScreenState();
}

class _LiveTradeScreenState extends State<LiveTradeScreen> {
  final List<double> _priceHistory = [];
  final TextEditingController _amountController = TextEditingController(
    text: '50',
  );

  StreamSubscription<double>? _priceSubscription;
  double? _currentPrice;
  double? _previousPrice;
  bool _busy = false;
  String _status = '';

  String? get _uid => AuthService().currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _listenToPrice();
  }

  void _listenToPrice() {
    _priceSubscription = PriceService()
        .watchPrice(widget.coinId)
        .listen(
          (price) {
            if (!mounted) return;
            setState(() {
              _previousPrice = _currentPrice;
              _currentPrice = price;
              _priceHistory.add(price);
              if (_priceHistory.length > 60) {
                _priceHistory.removeAt(0);
              }
            });
          },
          onError: (_) {
            if (mounted) {
              setState(() => _status = 'Unable to receive live price updates.');
            }
          },
        );
  }

  @override
  void dispose() {
    _priceSubscription?.cancel();
    _amountController.dispose();
    super.dispose();
  }

  double? _readAmount() {
    final value = double.tryParse(_amountController.text.trim());
    if (value == null || value <= 0) {
      setState(() => _status = 'Enter a valid trade amount greater than \$0.');
      return null;
    }
    return value;
  }

  Future<void> _openPosition(TradeDirection direction) async {
    final uid = _uid;
    final amount = _readAmount();
    if (amount == null) return;

    if (uid == null) {
      setState(() => _status = 'Not signed in.');
      return;
    }

    setState(() {
      _busy = true;
      _status = '';
    });

    try {
      final trade = await TradeService().openSpotTrade(
        uid: uid,
        coinId: widget.coinId,
        direction: direction,
        amount: amount,
      );

      if (!mounted) return;
      setState(() {
        _status =
            'Opened ${trade.direction.name.toUpperCase()} \$${trade.amount.toStringAsFixed(2)} @ \$${trade.entryPrice.toStringAsFixed(2)}';
      });
    } catch (e) {
      if (mounted) {
        setState(() => _status = 'Unable to open position: $e');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _closePosition(String tradeId) async {
    setState(() {
      _busy = true;
      _status = '';
    });

    try {
      final closed = await TradeService().closeTrade(tradeId: tradeId);
      if (!mounted) return;

      setState(() {
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
      if (mounted) {
        setState(() => _status = 'Unable to close position: $e');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  double _unrealizedPnl(TradeModel trade) {
    final price = _currentPrice;
    if (price == null || trade.entryPrice == 0) return 0;

    final percentChange = (price - trade.entryPrice) / trade.entryPrice;
    final direction = trade.direction == TradeDirection.long ? 1.0 : -1.0;
    return trade.amount * percentChange * direction;
  }

  double get _priceChange {
    final current = _currentPrice;
    final previous = _previousPrice;
    if (current == null || previous == null || previous == 0) return 0;
    return ((current - previous) / previous) * 100;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C8.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              C8Header(
                title: 'Live Trading',
                onBack: () => Navigator.pop(context),
                action: const _LiveBadge(),
              ),
              const SizedBox(height: 16),
              _buildMarketSummary(),
              const SizedBox(height: 16),
              Expanded(flex: 4, child: _buildChart()),
              const SizedBox(height: 14),
              _buildOrderControls(),
              if (_status.isNotEmpty) ...[
                const SizedBox(height: 10),
                C8Status(
                  text: _status,
                  success:
                      _status.startsWith('Opened') ||
                      _status.startsWith('Closed'),
                ),
              ],
              const SizedBox(height: 14),
              const Text(
                'Open Positions',
                style: TextStyle(
                  color: Color.fromARGB(255, 0, 0, 0),
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Expanded(flex: 3, child: _buildPositions()),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMarketSummary() {
    final change = _priceChange;
    final rising = change >= 0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${widget.coinId.toUpperCase()} / USD',
                style: const TextStyle(
                  color: C8.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  _currentPrice == null
                      ? 'Loading price…'
                      : '\$${_currentPrice!.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Color.fromARGB(255, 0, 0, 0),
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: (rising ? C8.green : C8.red).withValues(alpha: .10),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(
                rising
                    ? Icons.arrow_drop_up_rounded
                    : Icons.arrow_drop_down_rounded,
                color: rising ? C8.green : C8.red,
                size: 20,
              ),
              Text(
                '${change.abs().toStringAsFixed(3)}%',
                style: TextStyle(
                  color: rising ? C8.green : C8.red,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChart() {
    if (_priceHistory.length < 2) {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: C8.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: C8.border),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: C8.lime),
              SizedBox(height: 12),
              Text(
                'Waiting for live market ticks…',
                style: TextStyle(color: C8.muted),
              ),
            ],
          ),
        ),
      );
    }

    var minPrice = _priceHistory.first;
    var maxPrice = _priceHistory.first;
    for (final price in _priceHistory) {
      if (price < minPrice) minPrice = price;
      if (price > maxPrice) maxPrice = price;
    }

    var range = maxPrice - minPrice;
    if (range == 0) range = maxPrice.abs() * .002;
    if (range == 0) range = 1;

    final chartMin = minPrice - range * .18;
    final chartMax = maxPrice + range * .18;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 18, 12, 8),
      decoration: BoxDecoration(
        color: C8.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: C8.border),
        boxShadow: [
          BoxShadow(
            color: C8.lime.withValues(alpha: .04),
            blurRadius: 28,
            spreadRadius: 1,
          ),
        ],
      ),
      child: LineChart(
        LineChartData(
          minY: chartMin,
          maxY: chartMax,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            horizontalInterval: range / 4,
            getDrawingHorizontalLine: (_) =>
                FlLine(color: C8.border.withValues(alpha: .65), strokeWidth: 1),
            getDrawingVerticalLine: (_) =>
                FlLine(color: C8.border.withValues(alpha: .28), strokeWidth: 1),
          ),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineTouchData: const LineTouchData(enabled: true),
          lineBarsData: [
            LineChartBarData(
              spots: [
                for (var i = 0; i < _priceHistory.length; i++)
                  FlSpot(i.toDouble(), _priceHistory[i]),
              ],
              isCurved: true,
              curveSmoothness: .28,
              dotData: const FlDotData(show: false),
              color: C8.lime,
              barWidth: 3,
              belowBarData: BarAreaData(
                show: true,
                color: C8.lime.withValues(alpha: .08),
              ),
            ),
          ],
        ),
        duration: const Duration(milliseconds: 350),
      ),
    );
  }

  Widget _buildOrderControls() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: C8.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: C8.border),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 92,
            child: TextField(
              controller: _amountController,
              enabled: !_busy,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: const TextStyle(
                color: Color.fromARGB(255, 0, 0, 0),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
              decoration: InputDecoration(
                isDense: true,
                prefixText: '\$ ',
                prefixStyle: const TextStyle(
                  color: C8.lime,
                  fontWeight: FontWeight.w800,
                ),
                filled: true,
                fillColor: C8.bg.withValues(alpha: .45),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 12,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: C8.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: C8.lime),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SizedBox(
              height: 44,
              child: ElevatedButton(
                onPressed: _busy
                    ? null
                    : () => _openPosition(TradeDirection.long),
                style: ElevatedButton.styleFrom(
                  backgroundColor: C8.green,
                  foregroundColor: C8.bg,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'BUY',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SizedBox(
              height: 44,
              child: ElevatedButton(
                onPressed: _busy
                    ? null
                    : () => _openPosition(TradeDirection.short),
                style: ElevatedButton.styleFrom(
                  backgroundColor: C8.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'SELL',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPositions() {
    final uid = _uid;
    if (uid == null) {
      return const Center(
        child: Text('Not signed in.', style: TextStyle(color: C8.muted)),
      );
    }

    return StreamBuilder<List<TradeModel>>(
      stream: TradeService().watchUserTrades(uid),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Text(
              'Unable to load positions.',
              style: TextStyle(color: C8.red),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: C8.lime));
        }

        final openTrades = snapshot.data!
            .where(
              (trade) =>
                  trade.status == TradeStatus.open &&
                  trade.coinId == widget.coinId,
            )
            .toList();

        if (openTrades.isEmpty) {
          return const Center(
            child: Text(
              'No open positions.',
              style: TextStyle(color: C8.muted),
            ),
          );
        }

        return ListView.separated(
          itemCount: openTrades.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final trade = openTrades[index];
            final pnl = _unrealizedPnl(trade);
            final positive = pnl >= 0;

            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: C8.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: C8.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 46,
                    decoration: BoxDecoration(
                      color: trade.direction == TradeDirection.long
                          ? C8.green
                          : C8.red,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${trade.direction.name.toUpperCase()} · \$${trade.amount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Entry \$${trade.entryPrice.toStringAsFixed(2)}',
                          style: const TextStyle(color: C8.muted, fontSize: 12),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${positive ? '+' : ''}\$${pnl.toStringAsFixed(2)} unrealized',
                          style: TextStyle(
                            color: positive ? C8.green : C8.red,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton(
                    onPressed: _busy
                        ? null
                        : () => _closePosition(trade.tradeId),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: C8.lime,
                      side: const BorderSide(color: C8.lime),
                    ),
                    child: const Text('Close'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _LiveBadge extends StatelessWidget {
  const _LiveBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: C8.green.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: C8.green.withValues(alpha: .45)),
      ),
      child: const Icon(Icons.graphic_eq_rounded, color: C8.green, size: 20),
    );
  }
}
