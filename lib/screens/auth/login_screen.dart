import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/trade_service.dart';
import '../../models/trade_model.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            try {
              final cred = await AuthService()
                  .signIn(email: "test@test.com", password: "test1234");
              final uid = cred.user!.uid;
              print("Signed in as UID: $uid");

              final trade = await TradeService().openFuturesTrade(
                uid: uid,
                coinId: "bitcoin",
                direction: TradeDirection.long,
                amount: 100.0,
                leverage: 5,
                duration: const Duration(seconds: 10),
              );
              print("Opened futures trade: ${trade.tradeId}, entry: ${trade.entryPrice}, expires: ${trade.expiresAt}");

              print("Waiting 12 seconds for it to expire...");
              await Future.delayed(const Duration(seconds: 12));

              final resolved = await TradeService()
                  .resolveFuturesIfExpired(tradeId: trade.tradeId);
              print("Resolved: status=${resolved.status}, closePrice=${resolved.closePrice}, pnl=${resolved.pnl}");
            } catch (e, stack) {
              print('ERROR: $e');
              print('STACK: $stack');
            }
          },
          child: const Text('Test Futures Trade'),
        ),
      ),
    );
  }
}