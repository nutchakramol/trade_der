import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/auth_service.dart';
import '../../services/bank_service.dart';
import '../../services/price_service.dart';
import '../../services/trade_service.dart';
import '../../models/trade_model.dart';
import '../../models/crypto_model.dart';
import '../penalty/camera_capture_screen.dart';

class LiveTradeScreen extends StatefulWidget {
  final String coinId;
  const LiveTradeScreen({super.key, required this.coinId});

  @override
  State<LiveTradeScreen> createState() => _LiveTradeScreenState();
}

enum TradeMode { spot, futures }

class _LiveTradeScreenState extends State<LiveTradeScreen> {
  final List<double> _priceHistory = [];
  double? _currentPrice;
  StreamSubscription<double>? _priceSub;
  Timer? _futuresPollTimer;
  String _status = '';
  bool _busy = false;

  double _selectedAmount = 10.0;
  TradeMode _mode = TradeMode.spot;
  int _leverage = 5;
  Duration _duration = const Duration(seconds: 30);

  late String _coinId;
  List<CryptoModel> _coins = [];

  String? get _uid => AuthService().currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _coinId = widget.coinId;
    _loadCoins();
    _subscribeToPrice();
  }

  Future<void> _loadCoins() async {
    try {
      final coins = await PriceService().getTopCoins(perPage: 15);
      setState(() => _coins = coins);
    } catch (_) {
      // non-fatal, coin picker just won't show options
    }
  }

  void _subscribeToPrice() {
    _priceSub?.cancel();
    _priceHistory.clear();
    _priceSub = PriceService().watchPrice(_coinId).listen((price) {
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
    _futuresPollTimer?.cancel();
    super.dispose();
  }

  Future<void> _openSpot(TradeDirection direction) async {
    if (_uid == null) { setState(() => _status = 'Not signed in.'); return; }
    setState(() { _busy = true; _status = ''; });
    try {
      await TradeService().openSpotTrade(
        uid: _uid!,
        coinId: _coinId,
        direction: direction,
        amount: _selectedAmount,
      );
      setState(() => _status = '${direction == TradeDirection.long ? "Bought" : "Sold"} \$${_selectedAmount.toStringAsFixed(2)}');
    } catch (e) {
      setState(() => _status = 'ERROR: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openFutures(TradeDirection direction) async {
    if (_uid == null) { setState(() => _status = 'Not signed in.'); return; }
    setState(() { _busy = true; _status = ''; });
    try {
      final trade = await TradeService().openFuturesTrade(
        uid: _uid!,
        coinId: _coinId,
        direction: direction,
        amount: _selectedAmount,
        leverage: _leverage,
        duration: _duration,
      );
      setState(() => _status = 'Opened ${_leverage}x ${direction.name.toUpperCase()} \$${_selectedAmount.toStringAsFixed(2)}, resolves in ${_duration.inSeconds}s');

      _futuresPollTimer?.cancel();
      _futuresPollTimer = Timer.periodic(const Duration(seconds: 3), (_) => _checkFuturesExpiry(trade.tradeId));
    } catch (e) {
      setState(() => _status = 'ERROR: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _checkFuturesExpiry(String tradeId) async {
    try {
      final resolved = await TradeService().resolveFuturesIfExpired(tradeId: tradeId);
      if (resolved.status != TradeStatus.open) {
        _futuresPollTimer?.cancel();
        setState(() => _status = 'Resolved: ${resolved.status.name}, pnl: \$${resolved.pnl?.toStringAsFixed(2)}');
        if (resolved.status == TradeStatus.closedLoss && mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CameraCaptureScreen(tradeId: resolved.tradeId, lossAmount: resolved.amount),
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _status = 'ERROR checking expiry: $e');
    }
  }

  Future<void> _closeSpotPosition(String tradeId) async {
    setState(() => _busy = true);
    try {
      final closed = await TradeService().closeTrade(tradeId: tradeId);
      setState(() => _status = 'Closed: ${closed.status.name}, pnl: \$${closed.pnl?.toStringAsFixed(2)}');
      if (closed.status == TradeStatus.closedLoss && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CameraCaptureScreen(tradeId: closed.tradeId, lossAmount: closed.amount),
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
    final leverageMultiplier = trade.leverage ?? 1;
    return trade.amount * percentChange * directionMultiplier * leverageMultiplier;
  }

  @override
  Widget build(BuildContext context) {
    final uid = _uid;
    return Scaffold(
      appBar: AppBar(title: Text('Live Trade: $_coinId')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Coin picker
            if (_coins.isNotEmpty)
              DropdownButton<String>(
                value: _coinId,
                isExpanded: true,
                items: _coins.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _coinId = value);
                  _subscribeToPrice();
                },
              ),
            const SizedBox(height: 8),
            Text(
              _currentPrice == null ? 'Loading price...' : '\$${_currentPrice!.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 160,
              child: _priceHistory.length < 2
                  ? const Center(child: Text('Waiting for price data...'))
                  : LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: false),
                        titlesData: const FlTitlesData(show: false),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: [for (int i = 0; i < _priceHistory.length; i++) FlSpot(i.toDouble(), _priceHistory[i])],
                            isCurved: true,
                            dotData: const FlDotData(show: false),
                            color: Colors.deepPurple,
                            barWidth: 3,
                          ),
                        ],
                      ),
                      duration: const Duration(milliseconds: 800),
                    ),
            ),
            const SizedBox(height: 8),

            // Spot / Futures mode toggle
            SegmentedButton<TradeMode>(
              segments: const [
                ButtonSegment(value: TradeMode.spot, label: Text('Spot')),
                ButtonSegment(value: TradeMode.futures, label: Text('Futures')),
              ],
              selected: {_mode},
              onSelectionChanged: (selection) => setState(() => _mode = selection.first),
            ),
            const SizedBox(height: 8),

            // Amount slider (shared)
            if (uid != null)
              StreamBuilder<double>(
                stream: BankService().watchBalance(uid),
                builder: (context, snapshot) {
                  final maxAmount = snapshot.data ?? 0.0;
                  final safeMax = maxAmount > 0 ? maxAmount : 1.0;
                  return Column(
                    children: [
                      Text('Amount: \$${_selectedAmount.toStringAsFixed(2)}'),
                      Slider(
                        value: _selectedAmount.clamp(0, safeMax),
                        min: 0,
                        max: safeMax,
                        divisions: 20,
                        label: '\$${_selectedAmount.toStringAsFixed(2)}',
                        onChanged: (value) => setState(() => _selectedAmount = value),
                      ),
                    ],
                  );
                },
              ),

            // Futures-only controls
            if (_mode == TradeMode.futures) ...[
              const Text('Leverage'),
              Wrap(
                spacing: 8,
                children: [2, 5, 10].map((lev) => ChoiceChip(
                  label: Text('${lev}x'),
                  selected: _leverage == lev,
                  onSelected: (_) => setState(() => _leverage = lev),
                )).toList(),
              ),
              const SizedBox(height: 8),
              const Text('Duration'),
              Wrap(
                spacing: 8,
                children: const [
                  Duration(seconds: 30),
                  Duration(seconds: 60),
                  Duration(minutes: 2),
                ].map((d) => ChoiceChip(
                  label: Text('${d.inSeconds}s'),
                  selected: _duration == d,
                  onSelected: (_) => setState(() => _duration = d),
                )).toList(),
              ),
              const SizedBox(height: 8),
            ],

            // Buy/Sell buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _busy ? null : () => _mode == TradeMode.spot ? _openSpot(TradeDirection.long) : _openFutures(TradeDirection.long),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    child: const Text('Buy (Long)'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _busy ? null : () => _mode == TradeMode.spot ? _openSpot(TradeDirection.short) : _openFutures(TradeDirection.short),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text('Sell (Short)'),
                  ),
                ),
              ],
            ),
            if (_status.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(_status, textAlign: TextAlign.center),
            ],
            const Divider(height: 20),
            const Text('Open Positions', style: TextStyle(fontWeight: FontWeight.bold)),
            Expanded(
              child: uid == null
                  ? const Text('Not signed in.')
                  : StreamBuilder<List<TradeModel>>(
                      stream: TradeService().watchUserTrades(uid),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const CircularProgressIndicator();
                        final openTrades = snapshot.data!.where((t) => t.status == TradeStatus.open).toList();
                        if (openTrades.isEmpty) return const Text('No open positions.');
                        return ListView.builder(
                          itemCount: openTrades.length,
                          itemBuilder: (context, i) {
                            final t = openTrades[i];
                            final pnl = _unrealizedPnl(t);
                            return Card(
                              child: ListTile(
                                title: Text('${t.type.name.toUpperCase()} ${t.direction.name.toUpperCase()} \$${t.amount} (${t.coinId})${t.leverage != null ? " ${t.leverage}x" : ""}'),
                                subtitle: Text('Unrealized: \$${pnl.toStringAsFixed(2)}',
                                    style: TextStyle(color: pnl >= 0 ? Colors.green : Colors.red)),
                                trailing: t.type == TradeType.spot
                                    ? ElevatedButton(
                                        onPressed: _busy ? null : () => _closeSpotPosition(t.tradeId),
                                        child: const Text('Close'),
                                      )
                                    : const Text('auto'),
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