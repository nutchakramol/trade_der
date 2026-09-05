import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'screens/home/welcome_screen.dart';
import 'widgets/crypto888_ui.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Crypto888',
      debugShowCheckedModeBanner: false,

      // Crypto888 White / Yellow theme + SUSE Mono
      theme: crypto888Theme(),

      home: const WelcomeScreen(),
    );
  }
}
