import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/bank_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _pinController = TextEditingController();
  final _confirmController = TextEditingController();
  String _status = '';
  bool _loading = false;

  String? get _uid => AuthService().currentUser?.uid;

  Future<void> _savePin() async {
    if (_uid == null) return;
    final pin = _pinController.text.trim();
    final confirm = _confirmController.text.trim();

    if (pin.length < 4 || pin.length > 6 || int.tryParse(pin) == null) {
      setState(() => _status = 'PIN must be 4-6 digits.');
      return;
    }
    if (pin != confirm) {
      setState(() => _status = 'PINs do not match.');
      return;
    }

    setState(() { _loading = true; _status = ''; });
    try {
      await BankService().setTopUpPin(_uid!, pin);
      setState(() => _status = 'PIN saved successfully.');
      _pinController.clear();
      _confirmController.clear();
    } catch (e) {
      setState(() => _status = 'ERROR: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Set Top-Up PIN', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('This PIN will be required every time you top up your balance.',
                style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            TextField(
              controller: _pinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 6,
              decoration: const InputDecoration(labelText: 'New PIN (4-6 digits)'),
            ),
            TextField(
              controller: _confirmController,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 6,
              decoration: const InputDecoration(labelText: 'Confirm PIN'),
            ),
            const SizedBox(height: 16),
            _loading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(onPressed: _savePin, child: const Text('Save PIN')),
            const SizedBox(height: 16),
            if (_status.isNotEmpty) Text(_status, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}