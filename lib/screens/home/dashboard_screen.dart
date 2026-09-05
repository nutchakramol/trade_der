import 'package:flutter/material.dart';

import '../../models/crypto_model.dart';
import '../../services/auth_service.dart';
import '../../services/bank_service.dart';
import '../../services/price_service.dart';
import '../../widgets/crypto888_ui.dart';
import '../auth/login_screen.dart';
import '../leaderboard/leaderboard_screen.dart';
import '../minigame/roulette_screen.dart';
import '../trade/futures_trade_screen.dart';
import '../trade/live_trade_screen.dart';
import '../trade/spot_trade_screen.dart';
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
        if (mounted) {
          setState(() => _loadingMore = false);
        }
      }
    } else {
      setState(() => _showAllCoins = true);
    }
  }

  Future<void> _logout() async {
    await AuthService().signOut();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = _uid;
    final visibleCoins = _showAllCoins ? _coins : _coins.take(3).toList();

    return Scaffold(
      backgroundColor: C8.bg,
      body: SafeArea(
        child: RefreshIndicator(
          color: C8.ink,
          backgroundColor: C8.lime,
          onRefresh: () => _loadCoins(perPage: _showAllCoins ? 30 : 10),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _topBar(),
                const SizedBox(height: 16),
                _heroBanner(),
                const SizedBox(height: 16),
                _buildBalanceAndMascot(uid),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _smallAction(
                        Icons.account_balance_wallet_outlined,
                        'Bank',
                        false,
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
                        'Roulette',
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
                const SizedBox(height: 28),
                _sectionTitle(
                  'Top Coins',
                  trailing: TextButton.icon(
                    onPressed: _loadingCoins ? null : _loadCoins,
                    icon: const Icon(Icons.refresh_rounded, size: 17),
                    label: const Text('Refresh'),
                  ),
                ),
                const SizedBox(height: 10),
                if (_loadingCoins && _coins.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(28),
                      child: CircularProgressIndicator(color: C8.ink),
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
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _coinTile(coin),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: _loadingMore ? null : _toggleShowMore,
                      icon: _loadingMore
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: C8.ink,
                              ),
                            )
                          : Icon(
                              _showAllCoins
                                  ? Icons.keyboard_arrow_up_rounded
                                  : Icons.keyboard_arrow_down_rounded,
                            ),
                      label: Text(_showAllCoins ? 'Show Less' : 'Show More'),
                    ),
                  ),
                ],
                if (_status.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  C8Status(text: _status),
                ],
                const SizedBox(height: 28),
                _sectionTitle('Trading'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 54,
                        child: ElevatedButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const SpotTradeScreen(coinId: 'bitcoin'),
                            ),
                          ),
                          child: const Text('Buy / Spot'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _wideDark(
                        'Futures',
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const FuturesTradeScreen(coinId: 'bitcoin'),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _fullAction(
                  Icons.show_chart_rounded,
                  'Open Live Chart',
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
                  'Leaderboard',
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

  Widget _topBar() {
    return Container(
      height: 68,
      decoration: const BoxDecoration(color: C8.bg),
      child: Row(
        children: [
          _roundIcon(
            icon: Icons.logout_rounded,
            tooltip: 'Log out',
            onTap: _logout,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Crypto888',
                  style: TextStyle(
                    color: C8.ink,
                    fontSize: 24,
                    height: 1,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Dashboard',
                  style: TextStyle(
                    color: C8.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          _roundIcon(
            icon: Icons.settings_rounded,
            tooltip: 'Settings',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _roundIcon({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: C8.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: C8.border),
          ),
          child: Icon(icon, color: C8.ink, size: 21),
        ),
      ),
    );
  }

  Widget _heroBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),

        image: const DecorationImage(
          image: AssetImage(
            'assets/images/trade.jpg',
          ),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        // Optional dark/light overlay so text remains readable.
        padding: const EdgeInsets.all(2),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Hi!',
                    style: TextStyle(
                      color: Color.fromARGB(255, 236, 234, 234),
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 14),

                  const Text(
                    'Trade smarter with a simple,\nfriendly\nsimulator.',
                    style: TextStyle(
                      color: Color.fromARGB(255, 240, 238, 238),
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 22),

                  ElevatedButton.icon(
                    onPressed: () {
                      // your trading navigation
                    },
                    iconAlignment: IconAlignment.end,
                    icon: const Icon(
                      Icons.arrow_forward_rounded,
                    ),
                    label: const Text('Start trading'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
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
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: C8.card,
            border: Border.all(
              color: negative ? C8.red : C8.border,
              width: negative ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: C8.softShadow,
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
                        fontSize: 11,
                        letterSpacing: .4,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '\$${balance.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: negative ? C8.red : C8.ink,
                          fontSize: 38,
                          height: 1,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: negative ? C8.red : C8.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 7),
                        Text(
                          negative
                              ? 'Debt / liquidation status'
                              : 'Virtual trading funds',
                          style: TextStyle(
                            color: negative ? C8.red : C8.muted,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 90,
                height: 90,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: C8.limeSoft,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Image.asset(
                  'assets/images/baby_tweety.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const Icon(
                    Icons.flutter_dash_rounded,
                    color: C8.ink,
                    size: 48,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _sectionTitle(String title, {Widget? trailing}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: C8.ink,
              fontSize: 21,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        ?trailing,
      ],
    );
  }

  Widget _coinTile(CryptoModel coin) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => SpotTradeScreen(coinId: coin.id)),
      ),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: C8.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: C8.border),
          boxShadow: C8.softShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: C8.limeSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.currency_bitcoin_rounded,
                color: C8.ink,
                size: 22,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    coin.name,
                    style: const TextStyle(
                      color: C8.ink,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    coin.id.toUpperCase(),
                    style: const TextStyle(
                      color: C8.muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '\$${coin.currentPrice.toStringAsFixed(2)}',
              style: const TextStyle(
                color: C8.ink,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right_rounded, color: C8.muted, size: 20),
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
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(color: C8.muted, fontWeight: FontWeight.w600),
        ),
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
      height: 50,
      child: OutlinedButton.icon(
        onPressed: tap,
        icon: Icon(icon, size: 18),
        label: Text(
          label,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: C8.ink,
          backgroundColor: accent ? C8.lime : C8.card,
          side: BorderSide(color: accent ? C8.lime : C8.border),
        ),
      ),
    );
  }

  Widget _wideDark(String label, VoidCallback tap) {
    return SizedBox(
      height: 54,
      child: OutlinedButton(
        onPressed: tap,
        style: OutlinedButton.styleFrom(
          foregroundColor: C8.ink,
          backgroundColor: C8.card,
          side: const BorderSide(color: C8.border),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
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
      height: 54,
      child: OutlinedButton.icon(
        onPressed: tap,
        icon: Icon(icon, size: 19),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
        style: OutlinedButton.styleFrom(
          foregroundColor: C8.ink,
          backgroundColor: accent ? C8.limeSoft : C8.card,
          side: BorderSide(color: accent ? C8.lime : C8.border),
        ),
      ),
    );
  }
}
