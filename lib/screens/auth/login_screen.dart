import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/bank_service.dart';

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

              final balance = await BankService().getBalance(uid);
              print("Current balance: \$${balance.toStringAsFixed(2)}");

              await BankService().adjustBalance(uid, -500.0);
              print("Deducted \$500");

              final newBalance = await BankService().getBalance(uid);
              print("New balance: \$${newBalance.toStringAsFixed(2)}");
            } catch (e, stack) {
              print('ERROR: $e');
              print('STACK: $stack');
            }
          },
          child: const Text('Test Bank Service'),
        ),
      ),
    );
  }
}