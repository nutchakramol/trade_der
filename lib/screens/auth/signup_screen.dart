import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Sign Up',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                AuthService()
                    .signUp(email: "test@test.com", password: "test1234")
                    .then((_) => print("Signup worked!"))
                    .catchError((e) => print("Error: $e"));
              },
              child: const Text('Test Signup'),
            ),
          ],
        ),
      ),
    );
  }
}