import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:candlesticks/candlesticks.dart';
import 'package:flutter_1/trade.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_1/main.dart';
import 'package:flutter_1/binance_api.dart';

class Candlestick extends StatefulWidget {
  const Candlestick({super.key});

  @override
  State<Candlestick> createState() => _CandlestickState();
}

class _CandlestickState extends State<Candlestick> {
  int selectedIndex = 1;

  List<Candle> candles = [];
  bool isLoading = true;


  String selectedinterval  = "1m";
  final List<String> intervals = ["1m", "5m", "15m", "1h", "4h", "1d"];

  WebSocketChannel? channel;

  @override
  void initState() {
    super.initState();
    loadBinanceCandles();
  }

  // ---------------- REST API ----------------
  Future<void> loadBinanceCandles() async {
    setState(() => isLoading = true);

    try {
      final api = BinanceApi();
      final result = await BinanceApi.fetchCandles("BTCUSDT", selectedinterval);

      setState(() {
        candles = result
        .map((c) => Candle(
                date: DateTime.fromMillisecondsSinceEpoch(c["time"]),
                open: double.parse(c["open"]),
                high: double.parse(c["high"]),
                low: double.parse(c["low"]),
                close: double.parse(c["close"]),
                volume: double.parse(c["volume"]),
              ))
          .toList();
        isLoading = false;
      });

      startWebSocket(); // IMPORTANT: Start live updates
    } catch (e) {
      print("Error loading candles: $e");
    }
  }

  // ---------------- WEBSOCKET LIVE UPDATES ----------------
  void startWebSocket() {
    channel?.sink.close(); // close previous WS if interval changed

    final streamUrl =
        "wss://stream.binance.com:9443/ws/!ticker@arr";

    channel = WebSocketChannel.connect(Uri.parse(streamUrl));

    channel!.stream.listen((event) {
      final data = jsonDecode(event);
      final kline = data["k"];

      final liveCandle = Candle(
        date: DateTime.fromMillisecondsSinceEpoch(kline["t"]),
        open: double.parse(kline["o"]),
        high: double.parse(kline["h"]),
        low: double.parse(kline["l"]),
        close: double.parse(kline["c"]),
        volume: double.parse(kline["v"]),
      );

      setState(() {
        // Replace last candle with live candle
        if (candles.isNotEmpty) {
          candles[candles.length - 1] = liveCandle;
        }
      });
    });
  }

  @override
  void dispose() {
    channel?.sink.close();
    super.dispose();
  }

  // ---------------- INTERVAL BUTTONS ----------------
  Widget buildIntervals() {
    return SizedBox(
      height: 45,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: intervals.length,
        itemBuilder: (context, index) {
          String label = intervals[index];
          bool selected = (label == selectedinterval);

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal:8),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  selectedinterval = label;
                });
                loadBinanceCandles(); // Reload REST + WS for new interval
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                decoration: BoxDecoration(
                  color: selected ? Colors.blue : Colors.grey[900],
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    color: selected ? Colors.blue : Colors.grey,
                  ),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    color: selected ? Colors.white : Colors.grey,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: const Icon(Icons.menu, color: Colors.white),
        title: const Text("Candlestick", style: TextStyle(color: Colors.white)),
         actions: const [
          Icon(Icons.center_focus_strong, color: Colors.white),
          SizedBox(width: 15),
          Icon(Icons.add, color: Colors.white),
          SizedBox(width: 15),
          Icon(Icons.pending, color: Colors.white),
          SizedBox(width: 15),
        ],
      ),

      body: Column(
        children: [
          const SizedBox(height: 8),
          buildIntervals(),
          const SizedBox(height: 10),

          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.white))
                : Candlesticks(candles: candles),
          ),
        ],
      ),

      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.black,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.black,
        currentIndex: selectedIndex,

        onTap: (index) {
          setState(() => selectedIndex = index);

          if (index == 0) {
            Navigator.push(
                context, MaterialPageRoute(builder: (_) => QuotesScreen()));
          }

          if (index == 2) {
            Navigator.push(
                context, MaterialPageRoute(builder: (_) => TradeScreen()));
          }
        },

           items: const [
    BottomNavigationBarItem(icon: Icon(Icons.show_chart), label: "Quotes"),
    BottomNavigationBarItem(icon: Icon(Icons.candlestick_chart), label: "Chart"),
    BottomNavigationBarItem(icon: Icon(Icons.trending_up), label: "Trade"),
    BottomNavigationBarItem(icon: Icon(Icons.inventory), label: "Portfolio"),
    BottomNavigationBarItem(icon: Icon(Icons.chat), label: "Chat"),
  ],
      ),
    );
  }
}
