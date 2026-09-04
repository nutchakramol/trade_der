/// SHARED CONTRACT. Maps CoinGecko /coins/markets response.
class CryptoModel {
  final String id; // "bitcoin"
  final String symbol; // "btc"
  final String name; // "Bitcoin"
  final String image; // icon url
  final double currentPrice;
  final double priceChangePercentage24h;

  CryptoModel({
    required this.id,
    required this.symbol,
    required this.name,
    required this.image,
    required this.currentPrice,
    required this.priceChangePercentage24h,
  });

  factory CryptoModel.fromJson(Map<String, dynamic> json) {
    return CryptoModel(
      id: json['id'],
      symbol: json['symbol'],
      name: json['name'],
      image: json['image'],
      currentPrice: (json['current_price'] as num).toDouble(),
      priceChangePercentage24h:
          (json['price_change_percentage_24h'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
