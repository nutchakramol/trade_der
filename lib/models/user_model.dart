class UserModel {
  final String uid;
  final String email;
  final double bankBalance;
  final DateTime createdAt;
  final String? pendingPenaltyTradeId;

  UserModel({
    required this.uid,
    required this.email,
    required this.bankBalance,
    required this.createdAt,
    this.pendingPenaltyTradeId,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      email: map['email'] as String,
      bankBalance: (map['bankBalance'] as num).toDouble(),
      createdAt: DateTime.parse(map['createdAt'] as String),
      pendingPenaltyTradeId: map['pendingPenaltyTradeId'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'bankBalance': bankBalance,
      'createdAt': createdAt.toIso8601String(),
      'pendingPenaltyTradeId': pendingPenaltyTradeId,
    };
  }
}