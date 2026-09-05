import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/auth_service.dart';
import '../../services/bank_service.dart';
import '../../widgets/crypto888_ui.dart';
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
    if (_uid == null) {
      setState(() => _status = 'Not signed in.');
      return;
    }
    final hasPin = await BankService().hasTopUpPin(_uid!);
    if (!hasPin) {
      setState(() => _status = 'Please set a PIN in Settings first.');
      return;
    }
    final pin = await _askForPin();
    if (pin == null) return;
    setState(() {
      _loading = true;
      _status = '';
    });
    try {
      final valid = await BankService().verifyTopUpPin(_uid!, pin);
      if (!valid) {
        setState(() => _status = 'Incorrect PIN.');
        return;
      }
      await BankService().adjustBalance(_uid!, amount);
      setState(
        () => _status = 'Added \$${amount.toStringAsFixed(2)} successfully.',
      );
    } catch (e) {
      setState(() => _status = 'Top-up failed. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<String?> _askForPin() async {
    final controller = TextEditingController();
    bool hide = true;
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: C8.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            'Confirm Top-Up',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            obscureText: hide,
            maxLength: 6,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(color: Colors.white, letterSpacing: 4),
            decoration: c8Input(
              hint: 'Enter PIN',
              icon: Icons.lock_outline_rounded,
              suffix: IconButton(
                onPressed: () => setDialogState(() => hide = !hide),
                icon: Icon(
                  hide
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: C8.muted,
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel', style: TextStyle(color: C8.muted)),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, controller.text.trim()),
              style: ElevatedButton.styleFrom(
                backgroundColor: C8.lime,
                foregroundColor: C8.bg,
              ),
              child: const Text('Confirm'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final uid = _uid;
    final success = _status.startsWith('Added');
    return Scaffold(
      backgroundColor: C8.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              C8Header(
                title: 'Bank Account',
                onBack: () => Navigator.pop(context),
                action: InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: C8.lime.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: C8.lime, width: .5),
                    ),
                    child: const Icon(
                      Icons.settings_outlined,
                      color: Colors.white,
                      size: 21,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              if (uid == null)
                const C8Status(text: 'Not signed in.')
              else
                StreamBuilder<double>(
                  stream: BankService().watchBalance(uid),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const C8Status(text: 'Unable to load balance.');
                    }
                    final balance = snapshot.data ?? 0;
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: C8.card,
                        border: Border.all(color: C8.border),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'AVAILABLE BALANCE',
                            style: TextStyle(
                              color: C8.muted,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '\$${balance.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 40,
                                  height: 1,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Padding(
                                padding: EdgeInsets.only(bottom: 4),
                                child: Text(
                                  'USD',
                                  style: TextStyle(
                                    color: C8.green,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              const SizedBox(height: 32),
              const Text(
                'Top Up',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Choose an amount to add to your virtual trading balance.',
                style: TextStyle(color: C8.muted, fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: _amount('+\$100', 100)),
                  const SizedBox(width: 12),
                  Expanded(child: _amount('+\$500', 500)),
                  const SizedBox(width: 12),
                  Expanded(child: _amount('+\$1000', 1000)),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: _loading ? null : () => _showCustomAmount(),
                  icon: const Icon(Icons.add_circle_outline, size: 18),
                  label: const Text(
                    'Enter Custom Amount',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: C8.lime,
                    backgroundColor: C8.card,
                    side: const BorderSide(color: C8.lime),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              if (_status.isNotEmpty) ...[
                const SizedBox(height: 20),
                C8Status(text: _status, success: success),
              ],
              if (_loading) ...[
                const SizedBox(height: 24),
                const Center(child: CircularProgressIndicator(color: C8.lime)),
              ],
              const SizedBox(height: 32),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: C8.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: C8.border),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.shield_outlined, color: C8.lime),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PIN Protected',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'Every top-up requires your personal PIN before your balance is updated.',
                            style: TextStyle(
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
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _amount(String label, double amount) => SizedBox(
    height: 50,
    child: OutlinedButton(
      onPressed: _loading ? null : () => _topUp(amount),
      style: OutlinedButton.styleFrom(
        foregroundColor: C8.lime,
        backgroundColor: C8.lime.withValues(alpha: 0.10),
        side: const BorderSide(color: C8.lime),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
    ),
  );

  Future<void> _showCustomAmount() async {
    final controller = TextEditingController();
    final amount = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      backgroundColor: C8.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          MediaQuery.of(sheetContext).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter Top-Up Amount',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              style: const TextStyle(color: Colors.white, fontSize: 20),
              decoration: c8Input(
                hint: '0.00',
                icon: Icons.attach_money_rounded,
                limeIcon: true,
              ),
            ),
            const SizedBox(height: 20),
            C8PrimaryButton(
              label: 'Continue',
              onPressed: () {
                final v = double.tryParse(controller.text);
                if (v != null && v > 0) Navigator.pop(sheetContext, v);
              },
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    if (amount != null) _topUp(amount);
  }
}
