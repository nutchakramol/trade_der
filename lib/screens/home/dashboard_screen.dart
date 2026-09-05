import 'package:flutter/material.dart';

import '../../models/crypto_model.dart';
import '../../services/auth_service.dart';
import '../../services/bank_service.dart';
import '../../services/price_service.dart';
import '../../widgets/crypto888_ui.dart';
import '../leaderboard/leaderboard_screen.dart';
import '../minigame/roulette_screen.dart';
import '../trade/live_trade_screen.dart';
import 'bank_screen.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _status = '';
  List<CryptoModel> _coins = [];
  bool _loadingCoins = false;
  bool _loadingMore = false;
  bool _showAllCoins = false;

  String? get _uid => AuthService().currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _loadCoins();
  }

  Future<void> _loadCoins({int perPage = 10}) async {
    setState(() {
      _loadingCoins = true;
      _status = '';
    });

    try {
      final coins = await PriceService().getTopCoins(perPage: perPage);
      if (!mounted) return;
      setState(() => _coins = coins);
    } catch (_) {
      if (mounted) {
        setState(() => _status = 'Unable to load coin prices.');
      }
    } finally {
      if (mounted) {
        setState(() => _loadingCoins = false);
      }
    }
  }

  Future<void> _toggleShowMore() async {
    if (_showAllCoins) {
      setState(() => _showAllCoins = false);
      return;
    }

    if (_coins.length < 20) {
      setState(() => _loadingMore = true);
      try {
        final coins = await PriceService().getTopCoins(perPage: 30);
        if (!mounted) return;
        setState(() {
          _coins = coins;
          _showAllCoins = true;
        });
      } catch (_) {
        if (mounted) {
          setState(() => _status = 'Unable to load more crypto assets.');
        }
      } finally {
        if (mounted) setState(() => _loadingMore = false);
      }
    } else {
      setState(() => _showAllCoins = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = _uid;
    final visibleCoins = _showAllCoins ? _coins : _coins.take(3).toList();

    return Scaffold(
      backgroundColor: C8.bg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _loadCoins(perPage: _showAllCoins ? 30 : 10),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                C8Header(
                  title: 'Dashboard',
                  action: InkWell(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    ),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: C8.lime.withValues(alpha: .10),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: C8.lime, width: .5),
                      ),
                      child: const Icon(
                        Icons.settings_outlined,
                        color: Colors.white,
                        size: 21,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                _buildBalanceAndMascot(uid),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _smallAction(
                        Icons.account_balance_wallet_outlined,
                        'Bank Account',
                        true,
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const BankScreen()),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _smallAction(
                        Icons.casino_rounded,
                        'Spin Roulette',
                        true,
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RouletteScreen(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 26),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Top Coins',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _loadingCoins ? null : _loadCoins,
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: const Text('Refresh'),
                      style: TextButton.styleFrom(foregroundColor: C8.lime),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (_loadingCoins && _coins.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(28),
                      child: CircularProgressIndicator(color: C8.lime),
                    ),
                  )
                else if (_coins.isEmpty)
                  _emptyCard('No coin data available')
                else ...[
                  AnimatedSize(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeInOut,
                    child: Column(
                      children: visibleCoins
                          .map(
                            (coin) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _coinTile(coin),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: OutlinedButton.icon(
                      onPressed: _loadingMore ? null : _toggleShowMore,
                      icon: _loadingMore
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: C8.lime,
                              ),
                            )
                          : Icon(
                              _showAllCoins
                                  ? Icons.keyboard_arrow_up_rounded
                                  : Icons.keyboard_arrow_down_rounded,
                            ),
                      label: Text(_showAllCoins ? 'Show Less' : 'Show More'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: C8.lime,
                        backgroundColor: C8.card,
                        side: const BorderSide(color: C8.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
                if (_status.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  C8Status(text: _status),
                ],
                const SizedBox(height: 26),
                const Text(
                  'Trading',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                _fullAction(
                  Icons.show_chart_rounded,
                  'Open Live Trading Chart',
                  true,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LiveTradeScreen(coinId: 'bitcoin'),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _fullAction(
                  Icons.emoji_events_outlined,
                  'View Leaderboard',
                  false,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LeaderboardScreen(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceAndMascot(String? uid) {
    if (uid == null) {
      return const C8Status(text: 'Not signed in.');
    }

    return StreamBuilder<double>(
      stream: BankService().watchBalance(uid),
      builder: (context, snapshot) {
        final balance = snapshot.data ?? 0;
        final negative = balance < 0;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: C8.card,
            border: Border.all(color: negative ? C8.red : C8.border),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'AVAILABLE BALANCE',
                      style: TextStyle(
                        color: C8.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 7),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '\$${balance.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: negative ? C8.red : Colors.white,
                          fontSize: 36,
                          height: 1,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      negative
                          ? 'Debt / liquidation status'
                          : 'Virtual trading funds',
                      style: TextStyle(
                        color: negative ? C8.red : C8.green,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 88,
                height: 88,
                child: Image.asset(
                  'assets/images/baby_tweety.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => Container(
                    decoration: BoxDecoration(
                      color: C8.lime.withValues(alpha: .08),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: C8.lime.withValues(alpha: .35)),
                    ),
                    child: const Icon(
                      Icons.flutter_dash_rounded,
                      color: C8.lime,
                      size: 48,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _coinTile(CryptoModel coin) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => LiveTradeScreen(coinId: coin.id)),
      ),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: C8.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: C8.border),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                color: C8.border,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.currency_bitcoin,
                color: C8.lime,
                size: 19,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    coin.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    coin.id.toUpperCase(),
                    style: const TextStyle(color: C8.muted, fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Text(
              '\$${coin.currentPrice.toStringAsFixed(2)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyCard(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: C8.card,
        border: Border.all(color: C8.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Text(text, style: const TextStyle(color: C8.muted)),
      ),
    );
  }

  Widget _smallAction(
    IconData icon,
    String label,
    bool accent,
    VoidCallback? tap,
  ) {
    return SizedBox(
      height: 46,
      child: OutlinedButton.icon(
        onPressed: tap,
        icon: Icon(icon, size: 16),
        label: Text(
          label,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: accent ? C8.lime : Colors.white,
          backgroundColor: C8.card,
          side: BorderSide(color: accent ? C8.lime : C8.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _fullAction(
    IconData icon,
    String label,
    bool accent,
    VoidCallback tap,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: tap,
        icon: Icon(icon, size: 18),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
        style: OutlinedButton.styleFrom(
          foregroundColor: accent ? C8.lime : Colors.white,
          backgroundColor: accent ? C8.lime.withValues(alpha: .10) : C8.card,
          side: BorderSide(color: accent ? C8.lime : C8.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}