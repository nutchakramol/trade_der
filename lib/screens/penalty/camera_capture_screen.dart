import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/auth_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/crypto888_ui.dart';
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
  bool _uploaded = false;

  Future<void> _takePhotoAndUpload() async {
    setState(() {
      _loading = true;
      _status = '';
    });
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.camera,
      );
      if (pickedFile == null) {
        setState(() => _status = 'A camera photo is required to continue.');
        return;
      }
      final uid = AuthService().currentUser!.uid;
      await StorageService().uploadPenaltyPhoto(
        photo: File(pickedFile.path),
        uid: uid,
        tradeId: widget.tradeId,
        lossAmount: widget.lossAmount,
      );
      if (!mounted) return;
      setState(() {
        _uploaded = true;
        _status = 'Penalty photo uploaded successfully.';
      });
    } catch (e) {
      if (mounted) setState(() => _status = 'Upload failed. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: C8.bg,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const C8Header(title: 'Penalty Required'),
                const Spacer(),
                Center(
                  child: Container(
                    width: 92,
                    height: 92,
                    decoration: BoxDecoration(
                      color: C8.red.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                      border: Border.all(color: C8.red.withValues(alpha: 0.45)),
                    ),
                    child: const Icon(
                      Icons.camera_alt_outlined,
                      color: C8.red,
                      size: 42,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                const Center(
                  child: Text(
                    'Trade Lost',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: Text(
                    'You lost \$${widget.lossAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: C8.red,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Center(
                  child: Text(
                    'Take a penalty selfie to unlock the app and continue trading.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: C8.muted,
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                if (_status.isNotEmpty)
                  C8Status(text: _status, success: _uploaded),
                const SizedBox(height: 20),
                if (!_uploaded)
                  C8PrimaryButton(
                    label: 'Take Penalty Photo',
                    onPressed: _takePhotoAndUpload,
                    loading: _loading,
                    icon: Icons.camera_alt_outlined,
                  )
                else
                  C8PrimaryButton(
                    label: 'Back to Dashboard',
                    onPressed: () => Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DashboardScreen(),
                      ),
                      (route) => false,
                    ),
                    icon: Icons.dashboard_outlined,
                  ),
                const Spacer(),
                const Center(
                  child: Text(
                    'You cannot go back until the penalty is completed.',
                    style: TextStyle(color: C8.muted, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
