/// SHARED CONTRACT - agree on this together on Day 1.
/// Firestore collection: "trades/{tradeId}"
enum TradeType { spot, futures }
enum TradeDirection { long, short } // long = buy/bet price goes up, short = bet down
enum TradeStatus { open, closedWin, closedLoss }

class TradeModel {
  final String tradeId;
  final String uid;
  final String coinId; // e.g. "bitcoin", "ethereum" (CoinGecko id)
  final TradeType type;
  final TradeDirection direction;
  final double entryPrice;
  final double amount; // amount of fake money staked
  final int? leverage; // only for futures, e.g. 2, 5, 10
  final DateTime openedAt;
  final DateTime? expiresAt; // only for futures - when it auto-resolves
  final TradeStatus status;
  final double? closePrice;
  final double? pnl; // profit/loss amount, null until closed

  TradeModel({
    required this.tradeId,
    required this.uid,
    required this.coinId,
    required this.type,
    required this.direction,
    required this.entryPrice,
    required this.amount,
    this.leverage,
    required this.openedAt,
    this.expiresAt,
    required this.status,
    this.closePrice,
    this.pnl,
  });

  factory TradeModel.fromMap(Map<String, dynamic> map, String tradeId) {
    return TradeModel(
      tradeId: tradeId,
      uid: map['uid'],
      coinId: map['coinId'],
      type: TradeType.values.byName(map['type']),
      direction: TradeDirection.values.byName(map['direction']),
      entryPrice: (map['entryPrice'] as num).toDouble(),
      amount: (map['amount'] as num).toDouble(),
      leverage: map['leverage'] as int?,
      openedAt: DateTime.parse(map['openedAt']),
      expiresAt: map['expiresAt'] != null ? DateTime.parse(map['expiresAt']) : null,
      status: TradeStatus.values.byName(map['status']),
      closePrice: (map['closePrice'] as num?)?.toDouble(),
      pnl: (map['pnl'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'coinId': coinId,
      'type': type.name,
      'direction': direction.name,
      'entryPrice': entryPrice,
      'amount': amount,
      'leverage': leverage,
      'openedAt': openedAt.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'status': status.name,
      'closePrice': closePrice,
      'pnl': pnl,
    };
  }
}
