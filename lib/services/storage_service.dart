import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import '../models/penalty_model.dart';

class StorageService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<PenaltyModel> uploadPenaltyPhoto({
    required File photo,
    required String uid,
    required String tradeId,
    required double lossAmount,
  }) async {
    final dir = await getApplicationDocumentsDirectory();
    final localPath = '${dir.path}/penalty_$tradeId.jpg';
    final savedFile = await photo.copy(localPath);

    final docRef = _db.collection('penalties').doc();
    final penalty = PenaltyModel(
      penaltyId: docRef.id,
      uid: uid,
      tradeId: tradeId,
      photoUrl: savedFile.path,
      lossAmount: lossAmount,
      createdAt: DateTime.now(),
    );
    await docRef.set(penalty.toMap());

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
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => PenaltyModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }
}
