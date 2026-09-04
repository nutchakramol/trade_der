import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/auth_service.dart';
import '../../services/storage_service.dart';
import '../home/dashboard_screen.dart';

class CameraCaptureScreen extends StatefulWidget {
  final String tradeId;
  final double lossAmount;
  const CameraCaptureScreen({
    super.key,
    required this.tradeId,
    required this.lossAmount,
  });

  @override
  State<CameraCaptureScreen> createState() => _CameraCaptureScreenState();
}

class _CameraCaptureScreenState extends State<CameraCaptureScreen> {
  String _status = '';
  bool _loading = false;

  Future<void> _takePhotoAndUpload() async {
    setState(() { _loading = true; _status = ''; });
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.camera);
      if (pickedFile == null) {
        setState(() => _status = 'No photo taken.');
        return;
      }
      final file = File(pickedFile.path);
      final uid = AuthService().currentUser!.uid;

      final penalty = await StorageService().uploadPenaltyPhoto(
        photo: file,
        uid: uid,
        tradeId: widget.tradeId,
        lossAmount: widget.lossAmount,
      );
      setState(() => _status = 'Uploaded: ${penalty.photoUrl}');
    } catch (e) {
      setState(() => _status = 'ERROR: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // can't dodge the penalty by going back
      child: Scaffold(
        appBar: AppBar(title: const Text('ค่าปรับ — You Lost!')),
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('You lost \$${widget.lossAmount.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 20, color: Colors.red)),
              const SizedBox(height: 24),
              if (_loading) const CircularProgressIndicator(),
              ElevatedButton(
                onPressed: _loading ? null : _takePhotoAndUpload,
                child: const Text('Take Penalty Photo'),
              ),
              const SizedBox(height: 16),
              Text(_status, textAlign: TextAlign.center),
              if (_status.startsWith('Uploaded'))
                TextButton(
                  onPressed: () => Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const DashboardScreen()),
                    (route) => false,
                  ),
                  child: const Text('Back to Dashboard'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}