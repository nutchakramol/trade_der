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

              final trade = await TradeService().openSpotTrade(
                uid: uid,
                coinId: "bitcoin",
                direction: TradeDirection.long,
                amount: 100.0,
              );
              print("Opened trade: ${trade.tradeId}, entry price: ${trade.entryPrice}");

              final closed = await TradeService().closeTrade(tradeId: trade.tradeId);
              print("Closed trade: status=${closed.status}, closePrice=${closed.closePrice}, pnl=${closed.pnl}");
            } catch (e, stack) {
              print('ERROR: $e');
              print('STACK: $stack');
            }
          },
          child: const Text('Test Trade Service'),
        ),
      ),
    );
  }
}