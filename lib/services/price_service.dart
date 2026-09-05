import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/crypto_model.dart';

class PriceService {
  static const String baseUrl = 'https://api.coingecko.com/api/v3';

  Future<List<CryptoModel>> getTopCoins({int perPage = 20}) async {
    final uri = Uri.parse(
      '$baseUrl/coins/markets?vs_currency=usd&order=market_cap_desc&per_page=$perPage&page=1',
    );
    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Failed to load coins: ${response.statusCode}');
    }
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((e) => CryptoModel.fromJson(e)).toList();
  }

  Stream<double> watchPrice(String coinId) {
    final controller = StreamController<double>();

    Future<void> fetchOnce() async {
      final uri = Uri.parse(
        '$baseUrl/simple/price?ids=$coinId&vs_currencies=usd',
      );
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final price = (data[coinId]['usd'] as num).toDouble();
        controller.add(price);
      }
    }

    fetchOnce();
    final timer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => fetchOnce(),
    );
    controller.onCancel = () => timer.cancel();
    return controller.stream;
  }
}
