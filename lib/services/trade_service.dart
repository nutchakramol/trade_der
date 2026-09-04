import '../models/trade_model.dart';

/// OWNER: Person A - this is the core "game engine" of the app.
/// Person B's trade screens call these and react to the returned/streamed
/// TradeModel to decide when to trigger the penalty camera flow (on loss).
class TradeService {
  /// Deducts `amount` from the user's bank balance (via BankService) and
  /// writes a new TradeModel with status = TradeStatus.open to Firestore.
  /// TODO(Person A): implement, throw if bank balance < amount
  Future<TradeModel> openSpotTrade({
    required String uid,
    required String coinId,
    required TradeDirection direction,
    required double amount,
  }) async {
    throw UnimplementedError('TODO: Person A');
  }

  /// Same as openSpotTrade but with leverage + a duration (e.g. 30s/60s/5min
  /// for demo purposes - keep short so it's playable live) that determines
  /// expiresAt. TODO(Person A): implement
  Future<TradeModel> openFuturesTrade({
    required String uid,
    required String coinId,
    required TradeDirection direction,
    required double amount,
    required int leverage,
    required Duration duration,
  }) async {
    throw UnimplementedError('TODO: Person A');
  }

  /// Manually close a spot trade at current market price. Computes pnl,
  /// updates bank balance (win: bankBalance += amount + pnl,
  /// loss: pnl already deducted at open, no refund), sets status.
  /// Returns the closed TradeModel so the UI knows win/loss immediately.
  /// TODO(Person A): implement
  Future<TradeModel> closeTrade({required String tradeId}) async {
    throw UnimplementedError('TODO: Person A');
  }

  /// For futures: called by a background check (e.g. on app foreground /
  /// periodic timer) to auto-resolve any trade past its expiresAt.
  /// TODO(Person A): implement
  Future<TradeModel> resolveFuturesIfExpired({required String tradeId}) async {
    throw UnimplementedError('TODO: Person A');
  }

  /// Live stream of a user's trades (for dashboard "open positions" list).
  /// TODO(Person A): implement via Firestore snapshots()
  Stream<List<TradeModel>> watchUserTrades(String uid) {
    throw UnimplementedError('TODO: Person A');
  }
}
