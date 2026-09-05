import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/trade_model.dart';
import 'price_service.dart';
import 'bank_service.dart';

class TradeService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final PriceService _priceService = PriceService();
  final BankService _bankService = BankService();

  Future<TradeModel> openSpotTrade({
    required String uid,
    required String coinId,
    required TradeDirection direction,
    required double amount,
  }) async {
    final coins = await _priceService.getTopCoins(perPage: 250);
    final coin = coins.firstWhere(
      (c) => c.id == coinId,
      orElse: () => throw Exception('Coin not found: $coinId'),
    );

    await _bankService.deductIfSufficient(uid, amount);

    final docRef = _db.collection('trades').doc();
    final trade = TradeModel(
      tradeId: docRef.id,
      uid: uid,
      coinId: coinId,
      type: TradeType.spot,
      direction: direction,
      entryPrice: coin.currentPrice,
      amount: amount,
      openedAt: DateTime.now(),
      status: TradeStatus.open,
    );

    await docRef.set(trade.toMap());
    return trade;
  }
  
  Future<TradeModel> closeTrade({required String tradeId}) async {
    final doc = await _db.collection('trades').doc(tradeId).get();
    if (!doc.exists) throw Exception('Trade not found');

    final trade = TradeModel.fromMap(doc.data()!, tradeId);
    if (trade.status != TradeStatus.open) {
      throw Exception('Trade already closed');
    }

    final coins = await _priceService.getTopCoins(perPage: 250);
    final coin = coins.firstWhere(
      (c) => c.id == trade.coinId,
      orElse: () => throw Exception('Coin not found: ${trade.coinId}'),
    );
    final closePrice = coin.currentPrice;

    final priceDiff = closePrice - trade.entryPrice;
    final percentChange = priceDiff / trade.entryPrice;
    final directionMultiplier = trade.direction == TradeDirection.long ? 1 : -1;
    final pnl = trade.amount * percentChange * directionMultiplier;

    final isWin = pnl >= 0;
    final newStatus = isWin ? TradeStatus.closedWin : TradeStatus.closedLoss;

    if (isWin) {
      await _bankService.adjustBalance(trade.uid, trade.amount + pnl);
    } else {
      // Lock the user into the penalty flow until they upload a photo.
      await _db.collection('users').doc(trade.uid).update({
        'pendingPenaltyTradeId': trade.tradeId,
      });
    }

    final updatedTrade = TradeModel(
      tradeId: trade.tradeId,
      uid: trade.uid,
      coinId: trade.coinId,
      type: trade.type,
      direction: trade.direction,
      entryPrice: trade.entryPrice,
      amount: trade.amount,
      leverage: trade.leverage,
      openedAt: trade.openedAt,
      expiresAt: trade.expiresAt,
      status: newStatus,
      closePrice: closePrice,
      pnl: pnl,
    );

    await _db.collection('trades').doc(tradeId).update(updatedTrade.toMap());
    return updatedTrade;
  }

  Future<TradeModel> openFuturesTrade({
    required String uid,
    required String coinId,
    required TradeDirection direction,
    required double amount,
    required int leverage,
    required Duration duration,
  }) async {
    final coins = await _priceService.getTopCoins(perPage: 250);
    final coin = coins.firstWhere(
      (c) => c.id == coinId,
      orElse: () => throw Exception('Coin not found: $coinId'),
    );

    await _bankService.deductIfSufficient(uid, amount);

    final docRef = _db.collection('trades').doc();
    final now = DateTime.now();
    final trade = TradeModel(
      tradeId: docRef.id,
      uid: uid,
      coinId: coinId,
      type: TradeType.futures,
      direction: direction,
      entryPrice: coin.currentPrice,
      amount: amount,
      leverage: leverage,
      openedAt: now,
      expiresAt: now.add(duration),
      status: TradeStatus.open,
    );

    await docRef.set(trade.toMap());
    return trade;
  }
  Future<TradeModel> resolveFuturesIfExpired({required String tradeId}) async {
    final doc = await _db.collection('trades').doc(tradeId).get();
    if (!doc.exists) throw Exception('Trade not found');

    final trade = TradeModel.fromMap(doc.data()!, tradeId);

    if (trade.status != TradeStatus.open) {
      return trade;
    }
    if (trade.expiresAt == null || DateTime.now().isBefore(trade.expiresAt!)) {
      return trade;
    }

    final coins = await _priceService.getTopCoins(perPage: 250);
    final coin = coins.firstWhere(
      (c) => c.id == trade.coinId,
      orElse: () => throw Exception('Coin not found: ${trade.coinId}'),
    );
    final closePrice = coin.currentPrice;

    final priceDiff = closePrice - trade.entryPrice;
    final percentChange = priceDiff / trade.entryPrice;
    final directionMultiplier = trade.direction == TradeDirection.long ? 1 : -1;
    final leverageMultiplier = trade.leverage ?? 1;
    final pnl =
        trade.amount * percentChange * directionMultiplier * leverageMultiplier;

    final isWin = pnl >= 0;
    final newStatus = isWin ? TradeStatus.closedWin : TradeStatus.closedLoss;

    if (isWin) {
      await _bankService.adjustBalance(trade.uid, trade.amount + pnl);
    } else {
      await _db.collection('users').doc(trade.uid).update({
        'pendingPenaltyTradeId': trade.tradeId,
      });
    }

    final updatedTrade = TradeModel(
      tradeId: trade.tradeId,
      uid: trade.uid,
      coinId: trade.coinId,
      type: trade.type,
      direction: trade.direction,
      entryPrice: trade.entryPrice,
      amount: trade.amount,
      leverage: trade.leverage,
      openedAt: trade.openedAt,
      expiresAt: trade.expiresAt,
      status: newStatus,
      closePrice: closePrice,
      pnl: pnl,
    );

    await _db.collection('trades').doc(tradeId).update(updatedTrade.toMap());
    return updatedTrade;
  }

  Stream<List<TradeModel>> watchUserTrades(String uid) {
    return _db
        .collection('trades')
        .where('uid', isEqualTo: uid)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => TradeModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }
}
