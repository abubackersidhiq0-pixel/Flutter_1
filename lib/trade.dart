import 'package:flutter/material.dart';
import 'package:flutter_1/candlesticks.dart';
import 'package:flutter_1/main.dart';
import 'package:flutter_1/orderscreen.dart';

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: OrderScreen(symbol: "BTCUSDT"),
  ));
}

List<Map<String, dynamic>> globalOrders = [];  // GLOBAL ORDER LIST

class TradeScreen extends StatefulWidget {
  const TradeScreen({super.key});

  @override
  State<TradeScreen> createState() => _TradeScreenState();
}

class _TradeScreenState extends State<TradeScreen> {
  String selectedSymbol = "GBP/USD";  // default symbol

  final List<String> symbols = [
    "GBP/USD",
    "EUR/USD",
    "USD/JPY",
    "BTC/USDT",
    "ETH/USDT",
  ];

  void deleteOrder(int index) {
    setState(() {
      globalOrders.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          '$selectedSymbol - Trade',
          style: const TextStyle(color: Colors.white),
        ),

        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () {},
        ),

        actions: [
          /// ▼▼▼ SYMBOL DROPDOWN WHEN CLICKING SWAP ▼▼▼
          PopupMenuButton<String>(
            icon: const Icon(Icons.swap_vert, color: Colors.white),
            onSelected: (value) {
              setState(() => selectedSymbol = value);
            },
            color: Colors.black,
            itemBuilder: (context) {
              return symbols
                  .map((s) => PopupMenuItem(
                        value: s,
                        child: Text(s, style: const TextStyle(color: Colors.white)),
                      ))
                  .toList();
            },
          ),

          /// ADD ORDER SCREEN
          IconButton(
  icon: const Icon(Icons.add, color: Colors.white),
  onPressed: () async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => OrderScreen(symbol: selectedSymbol), // pass symbol here
      ),
    );
    setState(() {}); // refresh orders after adding
  },
),
        ],
      ),

      /// ▼▼▼ MAIN BODY ▼▼▼
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Balance:', ''),
            _buildInfoRow('Equity:', ''),
            _buildInfoRow('Free margin:', ''),

            const SizedBox(height: 20),

            const Text("Open Orders",
                style: TextStyle(color: Colors.white, fontSize: 18)),
            const SizedBox(height: 10),

            Expanded(
              child: globalOrders.isEmpty
                  ? const Center(
                      child: Text(
                        "No Orders",
                        style: TextStyle(color: Colors.white70, fontSize: 18),
                      ),
                    )
                  : ListView.builder(
                      itemCount: globalOrders.length,
                      itemBuilder: (context, index) {
                        final order = globalOrders[index];
                        return Card(
                          color: Colors.grey[900],
                          child: ListTile(
                            title: Text(
                              "${order['type']} - ${order['symbol']}",
                              style: const TextStyle(color: Colors.white),
                            ),
                            subtitle: Text(
                              "Price: ${order['price']}",
                              style: const TextStyle(color: Colors.white70),
                            ),
                            trailing: IconButton(
                              icon:
                                  const Icon(Icons.delete, color: Colors.redAccent),
                              onPressed: () => deleteOrder(index),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),

      /// ▼▼▼ BOTTOM NAV BAR ▼▼▼
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.black,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.white60,
        currentIndex: 2,
        onTap: (index) {
          if (index == 0) {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const QuotesScreen()));
          }
          if (index == 1) {
            Navigator.push(
                context, MaterialPageRoute(builder: (_) => Candlestick()));
          }
        },
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.show_chart), label: "Quotes"),
          BottomNavigationBarItem(
              icon: Icon(Icons.candlestick_chart), label: "Chart"),
          BottomNavigationBarItem(
              icon: Icon(Icons.trending_up), label: "Trade"),
          BottomNavigationBarItem(
              icon: Icon(Icons.inventory), label: "Portfolio"),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: "Chat"),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: const TextStyle(color: Colors.white, fontSize: 16)),
          Text(value,
              style: const TextStyle(color: Colors.white, fontSize: 16)),
        ],
      ),
    );
  }
}
