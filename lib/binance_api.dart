import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

class BinanceApi {
  /// Fetch all tickers (REST API)
  static Future<List<dynamic>> fetchAllTickers() async {
    final url = Uri.parse('https://api.binance.com/api/v3/ticker/24hr');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch tickers');
    }
  }

  /// Connect to live updates (WebSocket)
  static WebSocketChannel connectLive(String symbol) {
    return WebSocketChannel.connect(
      Uri.parse('wss://stream.binance.com:9443/ws/!@ticker@arr'),
    );
  }

  /// Fetch candlestick data (REST API)
  static Future<List<Map<String, dynamic>>> fetchCandles(
      String symbol, String interval,
      {int limit = 500}) async {
    final url = Uri.parse(
        'https://api.binance.com/api/v3/klines?symbol=$symbol&interval=$interval&limit=$limit');
    final response = await http.get(url);
    if (response.statusCode != 200) throw Exception('Failed to load candles');

    final List<dynamic> data = jsonDecode(response.body);

    return data
        .map((e) => {
              "time": e[0],
              "open": e[1],
              "high": e[2],
              "low": e[3],
              "close": e[4],
              "volume": e[5],
            })
        .toList();
  }
}
