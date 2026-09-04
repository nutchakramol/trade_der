/// OWNER: Person A
/// Person B's dashboard screen streams getBalance(uid) to show the
/// "check your bank status before you trade" balance card, and the
/// trade screens can call it to validate enough funds before enabling
/// the "Trade" button.
class BankService {
  /// TODO(Person A): implement via Firestore doc stream on users/{uid}.bankBalance
  Stream<double> watchBalance(String uid) {
    throw UnimplementedError('TODO: Person A');
  }

  /// TODO(Person A): implement one-off read
  Future<double> getBalance(String uid) async {
    throw UnimplementedError('TODO: Person A');
  }

  /// Used internally by TradeService - Person B should not need to call
  /// this directly, but it's exposed in case a screen needs a manual adjust.
  /// TODO(Person A): implement as a Firestore transaction (avoid race
  /// conditions if user opens two trades quickly).
  Future<void> adjustBalance(String uid, double delta) async {
    throw UnimplementedError('TODO: Person A');
  }
}
