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
    // Check balance first
    final balance = await _bankService.getBalance(uid);
    if (balance < amount) {
      throw Exception('Insufficient balance');
    }

    // Get current price as entry price
    final coins = await _priceService.getTopCoins(perPage: 250);
    final coin = coins.firstWhere(
      (c) => c.id == coinId,
      orElse: () => throw Exception('Coin not found: $coinId'),
    );

    // Deduct the staked amount immediately
    await _bankService.adjustBalance(uid, -amount);

    // Create the trade doc
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

    // Get current price
    final coins = await _priceService.getTopCoins(perPage: 250);
    final coin = coins.firstWhere(
      (c) => c.id == trade.coinId,
      orElse: () => throw Exception('Coin not found: ${trade.coinId}'),
    );
    final closePrice = coin.currentPrice;

    // Calculate pnl based on direction
    final priceDiff = closePrice - trade.entryPrice;
    final percentChange = priceDiff / trade.entryPrice;
    final directionMultiplier = trade.direction == TradeDirection.long ? 1 : -1;
    final pnl = trade.amount * percentChange * directionMultiplier;

    final isWin = pnl >= 0;
    final newStatus = isWin ? TradeStatus.closedWin : TradeStatus.closedLoss;

    // If win, return staked amount + profit. If loss, amount was already
    // deducted at open and nothing is returned.
    if (isWin) {
      await _bankService.adjustBalance(trade.uid, trade.amount + pnl);
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
        .map((snapshot) => snapshot.docs
            .map((doc) => TradeModel.fromMap(doc.data(), doc.id))
            .toList());
  }
}