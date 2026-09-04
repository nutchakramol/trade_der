import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class BankService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<double> watchBalance(String uid) {
    return _db.collection('users').doc(uid).snapshots().map(
        (doc) => (doc.data()?['bankBalance'] as num?)?.toDouble() ?? 0.0);
  }

  Future<double> getBalance(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return (doc.data()?['bankBalance'] as num?)?.toDouble() ?? 0.0;
  }

  Future<void> adjustBalance(String uid, double delta) async {
    final ref = _db.collection('users').doc(uid);
    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      final current = (snapshot.data()?['bankBalance'] as num?)?.toDouble() ?? 0.0;
      transaction.update(ref, {'bankBalance': current + delta});
    });
  }

  String _hashPin(String pin) {
    return sha256.convert(utf8.encode(pin)).toString();
  }

  Future<bool> hasTopUpPin(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.data()?['topUpPinHash'] != null;
  }

  Future<void> setTopUpPin(String uid, String pin) async {
    await _db.collection('users').doc(uid).update({
      'topUpPinHash': _hashPin(pin),
    });
  }

  Future<bool> verifyTopUpPin(String uid, String pin) async {
    final doc = await _db.collection('users').doc(uid).get();
    final storedHash = doc.data()?['topUpPinHash'] as String?;
    if (storedHash == null) return false;
    return storedHash == _hashPin(pin);
  }
}