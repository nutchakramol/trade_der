import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/auth_service.dart';
import '../../services/price_service.dart';
import '../../services/trade_service.dart';
import '../../models/trade_model.dart';
import '../penalty/camera_capture_screen.dart';

class LiveTradeScreen extends StatefulWidget {
  final String coinId;
  const LiveTradeScreen({super.key, required this.coinId});

  @override
  State<LiveTradeScreen> createState() => _LiveTradeScreenState();
}

class _LiveTradeScreenState extends State<LiveTradeScreen> {
  final List<double> _priceHistory = [];
  double? _currentPrice;
  StreamSubscription<double>? _priceSub;
  String _status = '';
  bool _busy = false;

  String? get _uid => AuthService().currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _priceSub = PriceService().watchPrice(widget.coinId).listen((price) {
      setState(() {
        _currentPrice = price;
        _priceHistory.add(price);
        if (_priceHistory.length > 30) _priceHistory.removeAt(0);
      });
    });
  }

  @override
  void dispose() {
    _priceSub?.cancel();
    super.dispose();
  }

  Future<void> _openPosition(TradeDirection direction) async {
    if (_uid == null) { setState(() => _status = 'Not signed in.'); return; }
    setState(() { _busy = true; _status = ''; });
    try {
      await TradeService().openSpotTrade(
        uid: _uid!,
        coinId: widget.coinId,
        direction: direction,
        amount: 50.0,
      );
      setState(() => _status = '${direction == TradeDirection.long ? "Bought" : "Sold"} \$50');
    } catch (e) {
      setState(() => _status = 'ERROR: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _closePosition(String tradeId) async {
    setState(() => _busy = true);
    try {
      final closed = await TradeService().closeTrade(tradeId: tradeId);
      setState(() => _status = 'Closed: ${closed.status.name}, pnl: \$${closed.pnl?.toStringAsFixed(2)}');
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
      setState(() => _status = 'ERROR: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  double _unrealizedPnl(TradeModel trade) {
    if (_currentPrice == null) return 0.0;
    final percentChange = (_currentPrice! - trade.entryPrice) / trade.entryPrice;
    final directionMultiplier = trade.direction == TradeDirection.long ? 1 : -1;
    return trade.amount * percentChange * directionMultiplier;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Live Trade: ${widget.coinId}')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _currentPrice == null ? 'Loading price...' : '\$${_currentPrice!.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 180,
              child: _priceHistory.length < 2
                  ? const Center(child: Text('Waiting for price data...'))
                  : LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: false),
                        titlesData: const FlTitlesData(show: false),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: [
                              for (int i = 0; i < _priceHistory.length; i++)
                                FlSpot(i.toDouble(), _priceHistory[i]),
                            ],
                            isCurved: true,
                            dotData: const FlDotData(show: false),
                            color: Colors.deepPurple,
                            barWidth: 3,
                          ),
                        ],
                      ),
                      duration: const Duration(milliseconds: 800), // eases between updates
                    ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _busy ? null : () => _openPosition(TradeDirection.long),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    child: const Text('Buy (Long) \$50'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _busy ? null : () => _openPosition(TradeDirection.short),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text('Sell (Short) \$50'),
                  ),
                ),
              ],
            ),
            if (_status.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(_status, textAlign: TextAlign.center),
            ],
            const Divider(height: 24),
            const Text('Open Positions', style: TextStyle(fontWeight: FontWeight.bold)),
            Expanded(
              child: _uid == null
                  ? const Text('Not signed in.')
                  : StreamBuilder<List<TradeModel>>(
                      stream: TradeService().watchUserTrades(_uid!),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Text('ERROR: ${snapshot.error}', style: const TextStyle(color: Colors.red));
                        }
                        if (!snapshot.hasData) return const CircularProgressIndicator();
                        final openTrades = snapshot.data!
                            .where((t) => t.status == TradeStatus.open && t.coinId == widget.coinId)
                            .toList();
                        if (openTrades.isEmpty) {
                          return const Text('No open positions.');
                        }
                        return ListView.builder(
                          itemCount: openTrades.length,
                          itemBuilder: (context, i) {
                            final t = openTrades[i];
                            final pnl = _unrealizedPnl(t);
                            return Card(
                              child: ListTile(
                                title: Text('${t.direction.name.toUpperCase()} \$${t.amount} @ \$${t.entryPrice.toStringAsFixed(2)}'),
                                subtitle: Text(
                                  'Unrealized: \$${pnl.toStringAsFixed(2)}',
                                  style: TextStyle(color: pnl >= 0 ? Colors.green : Colors.red),
                                ),
                                trailing: ElevatedButton(
                                  onPressed: _busy ? null : () => _closePosition(t.tradeId),
                                  child: const Text('Close'),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}