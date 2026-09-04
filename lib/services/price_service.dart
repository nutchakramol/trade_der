import '../models/crypto_model.dart';

/// OWNER: Person A
/// Free, no API key: https://www.coingecko.com/en/api/documentation
/// Base URL: https://api.coingecko.com/api/v3
///
/// Person B calls getTopCoins() to populate the dashboard list, and
/// watchPrice(coinId) to show a live-updating price on the trade screen.
class PriceService {
  static const String baseUrl = 'https://api.coingecko.com/api/v3';

  /// GET /coins/markets?vs_currency=usd&order=market_cap_desc&per_page=20&page=1
  /// TODO(Person A): implement, return parsed List<CryptoModel>.
  /// NOTE: CoinGecko free tier rate limit is ~10-30 calls/min - Person A
  /// should cache results and poll on a timer (e.g. every 15-30s), not
  /// call on every widget rebuild.
  Future<List<CryptoModel>> getTopCoins({int perPage = 20}) async {
    throw UnimplementedError('TODO: Person A');
  }

  /// GET /simple/price?ids={coinId}&vs_currencies=usd
  /// Returns a Stream so the UI can rebuild automatically. Use a
  /// Timer.periodic internally (e.g. poll every 10-15s) and pipe into
  /// a StreamController - CoinGecko has no free websocket, so this is
  /// simulated "live" via polling, which is fine for a 3-day prototype.
  /// TODO(Person A): implement
  Stream<double> watchPrice(String coinId) {
    throw UnimplementedError('TODO: Person A');
  }
}
