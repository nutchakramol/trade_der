/// SHARED CONTRACT - agree on this together on Day 1 before splitting up.
/// Firestore collection: "users/{uid}"
class UserModel {
  final String uid;
  final String email;
  final double bankBalance; // fake bank balance, starts at e.g. 10000.0
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.bankBalance,
    required this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      email: map['email'] as String,
      bankBalance: (map['bankBalance'] as num).toDouble(),
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'bankBalance': bankBalance,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
