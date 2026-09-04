import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/bank_service.dart';
import 'settings_screen.dart';

class BankScreen extends StatefulWidget {
  const BankScreen({super.key});

  @override
  State<BankScreen> createState() => _BankScreenState();
}

class _BankScreenState extends State<BankScreen> {
  String _status = '';
  bool _loading = false;

  String? get _uid => AuthService().currentUser?.uid;

  Future<void> _topUp(double amount) async {
    if (_uid == null) { setState(() => _status = 'Not signed in.'); return; }

    final hasPin = await BankService().hasTopUpPin(_uid!);
    if (!hasPin) {
      setState(() => _status = 'Please set a PIN in Settings first.');
      return;
    }

    final pin = await _askForPin();
    if (pin == null) return; // user cancelled

    setState(() { _loading = true; _status = ''; });
    try {
      final valid = await BankService().verifyTopUpPin(_uid!, pin);
      if (!valid) {
        setState(() => _status = 'Incorrect PIN.');
        return;
      }
      await BankService().adjustBalance(_uid!, amount);
      setState(() => _status = 'Added \$${amount.toStringAsFixed(2)}');
    } catch (e) {
      setState(() => _status = 'ERROR: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<String?> _askForPin() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter PIN'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          obscureText: true,
          maxLength: 6,
          decoration: const InputDecoration(labelText: 'PIN'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = _uid;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bank Account'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (uid == null)
              const Text('Not signed in.', style: TextStyle(color: Colors.red))
            else
              StreamBuilder<double>(
                stream: BankService().watchBalance(uid),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Text('ERROR: ${snapshot.error}', style: const TextStyle(color: Colors.red));
                  }
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  return Column(
                    children: [
                      const Text('Current Balance', style: TextStyle(fontSize: 16, color: Colors.grey)),
                      const SizedBox(height: 8),
                      Text(
                        '\$${snapshot.data!.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
                      ),
                    ],
                  );
                },
              ),
            const SizedBox(height: 32),
            const Text('Top Up', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _loading ? null : () => _topUp(100.0),
                    child: const Text('+\$100'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _loading ? null : () => _topUp(500.0),
                    child: const Text('+\$500'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _loading ? null : () => _topUp(1000.0),
                    child: const Text('+\$1000'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_loading) const Center(child: CircularProgressIndicator()),
            if (_status.isNotEmpty) Text(_status, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}