import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/trade_service.dart';
import '../../models/trade_model.dart';
import '../penalty/camera_capture_screen.dart';

class FuturesTradeScreen extends StatefulWidget {
  final String coinId;
  const FuturesTradeScreen({super.key, required this.coinId});

  @override
  State<FuturesTradeScreen> createState() => _FuturesTradeScreenState();
}

class _FuturesTradeScreenState extends State<FuturesTradeScreen> {
  String _status = 'No trade yet.';
  TradeModel? _openTrade;
  bool _loading = false;
  Timer? _pollTimer;

  String? get _uid => AuthService().currentUser?.uid;

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _openFutures() async {
    if (_uid == null) { setState(() => _status = 'Not signed in.'); return; }
    setState(() { _loading = true; _status = ''; });
    try {
      final trade = await TradeService().openFuturesTrade(
        uid: _uid!,
        coinId: widget.coinId,
        direction: TradeDirection.long,
        amount: 50.0,
        leverage: 5,
        duration: const Duration(seconds: 15),
      );
      setState(() {
        _openTrade = trade;
        _status = 'Opened 5x LONG @ \$${trade.entryPrice}, expires ${trade.expiresAt}';
      });
      _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) => _checkExpiry());
    } catch (e) {
      setState(() => _status = 'ERROR: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _checkExpiry() async {
    if (_openTrade == null) return;
    try {
      final resolved = await TradeService().resolveFuturesIfExpired(tradeId: _openTrade!.tradeId);
      if (resolved.status != TradeStatus.open) {
        _pollTimer?.cancel();
        setState(() {
          _status = 'Resolved: ${resolved.status.name}, pnl: ${resolved.pnl?.toStringAsFixed(2)}';
          _openTrade = null;
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
      } else {
        setState(() => _status = 'Still open, waiting for expiry...');
      }
    } catch (e) {
      setState(() => _status = 'ERROR checking expiry: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Futures: ${widget.coinId}')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_loading) const CircularProgressIndicator(),
            ElevatedButton(
              onPressed: _openTrade == null && !_loading ? _openFutures : null,
              child: const Text('Open 5x Long \$50, 15s'),
            ),
            const SizedBox(height: 16),
            Text(_status, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}