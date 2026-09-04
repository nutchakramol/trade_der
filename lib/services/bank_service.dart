import 'package:cloud_firestore/cloud_firestore.dart';

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
}