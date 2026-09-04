import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/penalty_model.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<PenaltyModel> uploadPenaltyPhoto({
    required File photo,
    required String uid,
    required String tradeId,
    required double lossAmount,
  }) async {
    // Upload the file
    final ref = _storage.ref().child('penalty_photos/$uid/$tradeId.jpg');
    await ref.putFile(photo);
    final photoUrl = await ref.getDownloadURL();

    // Write the penalty doc
    final docRef = _db.collection('penalties').doc();
    final penalty = PenaltyModel(
      penaltyId: docRef.id,
      uid: uid,
      tradeId: tradeId,
      photoUrl: photoUrl,
      lossAmount: lossAmount,
      createdAt: DateTime.now(),
    );
    await docRef.set(penalty.toMap());

    // Clear the lock so the user can use the app again
    await _db.collection('users').doc(uid).update({
      'pendingPenaltyTradeId': null,
    });

    return penalty;
  }

  Stream<List<PenaltyModel>> watchAllPenalties() {
    return _db
        .collection('penalties')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PenaltyModel.fromMap(doc.data(), doc.id))
            .toList());
  }
}