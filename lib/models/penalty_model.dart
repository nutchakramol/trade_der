/// SHARED CONTRACT - agree on this together on Day 1.
/// Firestore collection: "penalties/{penaltyId}"
/// Photo file itself lives in Firebase Storage at "penalty_photos/{uid}/{tradeId}.jpg"
class PenaltyModel {
  final String penaltyId;
  final String uid;
  final String tradeId;
  final String photoUrl; // download URL from Firebase Storage
  final double lossAmount;
  final DateTime createdAt;

  PenaltyModel({
    required this.penaltyId,
    required this.uid,
    required this.tradeId,
    required this.photoUrl,
    required this.lossAmount,
    required this.createdAt,
  });

  factory PenaltyModel.fromMap(Map<String, dynamic> map, String penaltyId) {
    return PenaltyModel(
      penaltyId: penaltyId,
      uid: map['uid'],
      tradeId: map['tradeId'],
      photoUrl: map['photoUrl'],
      lossAmount: (map['lossAmount'] as num).toDouble(),
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'tradeId': tradeId,
      'photoUrl': photoUrl,
      'lossAmount': lossAmount,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
