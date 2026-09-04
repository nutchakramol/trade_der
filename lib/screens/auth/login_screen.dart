import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../services/auth_service.dart';
import '../../services/storage_service.dart';

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

              final picker = ImagePicker();
              final pickedFile = await picker.pickImage(source: ImageSource.camera);
              if (pickedFile == null) {
                print("No image picked");
                return;
              }
              final file = File(pickedFile.path);

              final penalty = await StorageService().uploadPenaltyPhoto(
                photo: file,
                uid: uid,
                tradeId: "test-trade-id-123",
                lossAmount: 50.0,
              );
              print("Uploaded! Photo URL: ${penalty.photoUrl}");
            } catch (e, stack) {
              print('ERROR: $e');
              print('STACK: $stack');
            }
          },
          child: const Text('Test Storage Upload'),
        ),
      ),
    );
  }
}