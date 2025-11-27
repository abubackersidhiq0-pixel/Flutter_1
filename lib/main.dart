import 'package:flutter/material.dart';
import 'package:flutter_1/trade.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'binance_api.dart';
import 'favorites_service.dart';
import 'candlesticks.dart';
import 'dart:convert';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: QuotesScreen(),
  ));
}

class QuotesScreen extends StatefulWidget {
  const QuotesScreen({super.key});

  @override
  
  State<QuotesScreen> createState() => QuotesScreenState();
}

class QuotesScreenState extends State<QuotesScreen> {
  int selectedIndex = 0;
  List<dynamic> tickers = [];
  List<dynamic> filtered = [];
  Map<String, WebSocketChannel> streams = {};
  Map<String, Color> priceColor = {};
  String searchText = "";

  @override
  void initState() {
    super.initState();
    loadTickers();
  }

  @override
  void dispose() {
    for (var ws in streams.values) {
      ws.sink.close();
    }
    super.dispose();
  }

  Future<void> loadTickers() async {
    tickers = await BinanceApi.fetchAllTickers();
    filtered = tickers;

    for (var item in tickers) {
      final symbol = item["symbol"];
      subscribeLive(symbol);
    }

    setState(() {});
  }

  // LIVE WEBSOCKET UPDATES
  void subscribeLive(String symbol) {
    final ws = BinanceApi.connectLive(symbol);
    streams[symbol] = ws;

    ws.stream.listen((data) {
      final json = jsonDecode(data);

      setState(() {
        final index =
            tickers.indexWhere((e) => e["symbol"] == json["s"]);

        if (index != -1) {
          final oldBid = double.tryParse(tickers[index]["bidPrice"]) ?? 0;
          final newBid = double.tryParse(json["b"]) ?? 0;

          priceColor[json["s"]] =
              newBid > oldBid ? Colors.green : Colors.red;

          tickers[index]["bidPrice"] = json["b"];
          tickers[index]["askPrice"] = json["a"];
        }
      });
    });
  }

  // SEARCH FILTER
  void updateSearch(String value) {
    searchText = value.toUpperCase();
    setState(() {
      filtered = tickers
          .where((e) => e["symbol"].toString().contains(searchText))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: BottomNavigationBar(
  backgroundColor: Colors.black,
  selectedItemColor: Colors.blue,
  unselectedItemColor: Colors.black,
  currentIndex: selectedIndex, // track selected tab

  onTap: (index) {
    setState(() => selectedIndex = index);

    // Navigate to different screens based on tab
    if (index == 0) {
      // Already on QuotesScreen, do nothing or scroll to top
    }
    if (index == 1) {
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => Candlestick()));
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
      
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Quotes', style: TextStyle(color: Colors.black)),
        leading: const Icon(Icons.menu, color: Colors.black),
        actions: [
          Icon(Icons.add, color: Colors.black),
          SizedBox(width: 15),
          Icon(Icons.edit, color: Colors.black),
          SizedBox(width: 15),
        ],
        
      ),
      

      body: Column(
        children: [
          // SEARCH BAR
          Padding(
            padding: const EdgeInsets.all(10),
            child: TextField(
              onChanged: updateSearch,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Search symbol...",
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: Colors.white10,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),

          // LIVE SYMBOL LIST
          Expanded(
            child: ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (_, i) {
                final item = filtered[i];

                return QuoteTile(
                  item: item,
                  color: priceColor[item["symbol"]] ?? Colors.white,
                  onTap: () => openOptions(item),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // OPTIONS MENU
  void openOptions(dynamic item) {
    showModalBottomSheet(
      backgroundColor: Colors.grey,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
      ),
      context: context,
      builder: (_) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.candlestick_chart, color: Colors.black),
              title: const Text("Open Chart",
                  style: TextStyle(color: Colors.black)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => Candlestick()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.trending_up, color: Colors.black),
              title: const Text("Trade",
                  style: TextStyle(color: Colors.black)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => TradeScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.star, color: Colors.black),
              title: const Text("Add to Favorites",
                  style: TextStyle(color: Colors.black)),
              onTap: () {
                FavoritesService.toggleFavorite(item["symbol"]);
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  // SHOW FAVORITES LIST
  void showFavorites() async {
    final favs = await FavoritesService.getFavorites();
    filtered = tickers
        .where((e) => favs.contains(e["symbol"]))
        .toList();

    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text("Showing favorites"),
    ));
  }
}

//
// QUOTE TILE WIDGET
//
class QuoteTile extends StatelessWidget {
  final dynamic item;
  final Color color;
  final Function() onTap;

  const QuoteTile(
      {super.key, required this.item, required this.color, required this.onTap});

  @override
   Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white24, width: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item["pair"], style: TextStyle(color: Colors.white, fontSize: 17)),
          SizedBox(height: 3),
          Text(
            "Spread: ${item["spread"]}",
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    item["bid"],
                    style: TextStyle(
                      color: item["color"],
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                ],
              ),
              Row(
                children: [
                  Text(
                    item["ask"],
                    style: TextStyle(
                      color: item["color"],
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                ],
              ),
            ],
          ),
          SizedBox(height: 5),
          Text(
            "Low: ${item["low"]}     High: ${item["high"]}",
            style: TextStyle(color: Colors.grey, fontSize: 12),
          )
        ],
      ),
    );
  }
}