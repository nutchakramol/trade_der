import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/bank_service.dart';
import '../../services/price_service.dart';
import '../../models/crypto_model.dart';
import '../trade/live_trade_screen.dart';
import '../leaderboard/leaderboard_screen.dart';
import 'bank_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _status = '';
  List<CryptoModel> _coins = [];
  bool _loadingCoins = false;

  String? get _uid => AuthService().currentUser?.uid;

  Future<void> _loadCoins() async {
    setState(() { _loadingCoins = true; _status = ''; });
    try {
      final coins = await PriceService().getTopCoins(perPage: 10);
      setState(() => _coins = coins);
    } catch (e) {
      setState(() => _status = 'ERROR loading coins: $e');
    } finally {
      if (mounted) setState(() => _loadingCoins = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = _uid;
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard (Test)')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (uid == null)
              const Text('Not signed in.', style: TextStyle(color: Colors.red))
            else ...[
              Text('UID: $uid', style: const TextStyle(fontSize: 11, color: Colors.grey)),
              const SizedBox(height: 8),
              StreamBuilder<double>(
                stream: BankService().watchBalance(uid),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Text('Balance ERROR: ${snapshot.error}',
                        style: const TextStyle(color: Colors.red));
                  }
                  if (!snapshot.hasData) return const Text('Loading balance...');
                  return Text('Balance: \$${snapshot.data!.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold));
                },
              ),
            ],
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const BankScreen())),
              child: const Text('Bank Account (Top Up)'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadCoins,
              child: _loadingCoins
                  ? const CircularProgressIndicator()
                  : const Text('Load Top Coins'),
            ),
            if (_status.isNotEmpty)
              Text(_status, style: const TextStyle(color: Colors.red)),
            Expanded(
              child: ListView.builder(
                itemCount: _coins.length,
                itemBuilder: (context, i) {
                  final coin = _coins[i];
                  return ListTile(
                    title: Text(coin.name),
                    subtitle: Text('\$${coin.currentPrice}'),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => LiveTradeScreen(coinId: coin.id)),
                    ),
                  );
                },
              ),
            ),
            const Divider(),
            ElevatedButton(
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const LiveTradeScreen(coinId: 'bitcoin'))),
              child: const Text('Live Trading (Spot + Futures)'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const LeaderboardScreen())),
              child: const Text('View Leaderboard'),
            ),
          ],
        ),
      ),
    );
  }
}