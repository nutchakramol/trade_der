import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/auth_service.dart';
import '../../services/bank_service.dart';
import '../../widgets/crypto888_ui.dart';

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
  bool _hidePin = true;
  bool _hideConfirm = true;
  String? get _uid => AuthService().currentUser?.uid;

  Future<void> _savePin() async {
    if (_uid == null) {
      setState(() => _status = 'Not signed in.');
      return;
    }
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
    setState(() {
      _loading = true;
      _status = '';
    });
    try {
      await BankService().setTopUpPin(_uid!, pin);
      setState(() => _status = 'PIN saved successfully.');
      _pinController.clear();
      _confirmController.clear();
    } catch (e) {
      setState(() => _status = 'Unable to save PIN. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _pinController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final success = _status.toLowerCase().contains('success');
    return Scaffold(
      backgroundColor: C8.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              C8Header(title: 'Settings', onBack: () => Navigator.pop(context)),
              const SizedBox(height: 24),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: C8.lime.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: C8.lime.withValues(alpha: 0.35)),
                ),
                child: const Icon(Icons.lock_outline_rounded, color: C8.lime),
              ),
              const SizedBox(height: 20),
              const Text(
                'Set Top-Up PIN',
                style: TextStyle(
                  color: Color.fromARGB(255, 0, 0, 0),
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'This PIN will be required every time you top up balance.',
                style: TextStyle(color: C8.muted, fontSize: 15, height: 1.4),
              ),
              const SizedBox(height: 32),
              _label('ENTER PIN'),
              TextField(
                controller: _pinController,
                obscureText: _hidePin,
                keyboardType: TextInputType.number,
                maxLength: 6,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                cursorColor: C8.lime,
                style: const TextStyle(color: Colors.white, letterSpacing: 4),
                decoration: c8Input(
                  hint: '••••',
                  icon: Icons.pin_outlined,
                  limeIcon: true,
                  suffix: IconButton(
                    onPressed: () => setState(() => _hidePin = !_hidePin),
                    icon: Icon(
                      _hidePin
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: C8.muted,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _label('CONFIRM PIN'),
              TextField(
                controller: _confirmController,
                obscureText: _hideConfirm,
                keyboardType: TextInputType.number,
                maxLength: 6,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                cursorColor: C8.lime,
                style: const TextStyle(color: Colors.white, letterSpacing: 4),
                decoration: c8Input(
                  hint: '••••',
                  icon: Icons.lock_outline_rounded,
                  suffix: IconButton(
                    onPressed: () =>
                        setState(() => _hideConfirm = !_hideConfirm),
                    icon: Icon(
                      _hideConfirm
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: C8.muted,
                    ),
                  ),
                ),
              ),
              if (_status.isNotEmpty) ...[
                const SizedBox(height: 20),
                C8Status(text: _status, success: success),
              ],
              const SizedBox(height: 28),
              C8PrimaryButton(
                label: 'Save PIN',
                onPressed: _savePin,
                loading: _loading,
              ),
              const SizedBox(height: 32),
              const Divider(color: C8.border),
              const SizedBox(height: 24),
              const Text(
                'SECURITY',
                style: TextStyle(
                  color: C8.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              _info(
                Icons.shield_outlined,
                'Protected Top-Ups',
                'Your PIN is checked before virtual funds are added.',
              ),
              const SizedBox(height: 12),
              _info(
                Icons.password_rounded,
                '4–6 Digit PIN',
                'Use a PIN that is memorable but difficult to guess.',
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: const TextStyle(
        color: C8.muted,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
  Widget _info(IconData icon, String title, String body) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: C8.card,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: C8.border),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: C8.lime, size: 21),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color.fromARGB(255, 0, 0, 0),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                body,
                style: const TextStyle(
                  color: C8.muted,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
