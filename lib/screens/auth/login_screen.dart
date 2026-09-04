import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Crypto Trade Sim',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                AuthService()
                    .signIn(email: "test@test.com", password: "test1234")
                    .then((cred) => print("Sign in worked! UID: ${cred.user?.uid}"))
                    .catchError((e) => print("Error: $e"));
              },
              child: const Text('Test Sign In'),
            ),
          ],
        ),
      ),
    );
  }
}