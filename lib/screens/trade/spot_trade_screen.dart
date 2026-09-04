import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/trade_service.dart';
import '../../models/trade_model.dart';
import '../penalty/camera_capture_screen.dart';

class SpotTradeScreen extends StatefulWidget {
  final String coinId;
  const SpotTradeScreen({super.key, required this.coinId});

  @override
  State<SpotTradeScreen> createState() => _SpotTradeScreenState();
}

class _SpotTradeScreenState extends State<SpotTradeScreen> {
  String _status = 'No trade yet.';
  TradeModel? _openTrade;
  bool _loading = false;

  String? get _uid => AuthService().currentUser?.uid;

  Future<void> _openLong() async {
    if (_uid == null) { setState(() => _status = 'Not signed in.'); return; }
    setState(() { _loading = true; _status = ''; });
    try {
      final trade = await TradeService().openSpotTrade(
        uid: _uid!,
        coinId: widget.coinId,
        direction: TradeDirection.long,
        amount: 50.0,
      );
      setState(() {
        _openTrade = trade;
        _status = 'Opened LONG @ \$${trade.entryPrice}';
      });
    } catch (e) {
      setState(() => _status = 'ERROR: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _close() async {
    if (_openTrade == null) return;
    setState(() => _loading = true);
    try {
      final closed = await TradeService().closeTrade(tradeId: _openTrade!.tradeId);
      setState(() {
        _status = 'Closed: ${closed.status.name}, pnl: ${closed.pnl?.toStringAsFixed(2)}';
        _openTrade = null;
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
      setState(() => _status = 'ERROR: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Spot Trade: ${widget.coinId}')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_loading) const CircularProgressIndicator(),
            ElevatedButton(
              onPressed: _openTrade == null && !_loading ? _openLong : null,
              child: const Text('Open Long \$50'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _openTrade != null && !_loading ? _close : null,
              child: const Text('Close Trade'),
            ),
            const SizedBox(height: 16),
            Text(_status, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}