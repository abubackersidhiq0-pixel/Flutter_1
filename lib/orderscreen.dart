import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter_1/trade.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: OrderScreen(symbol: "BTCUSDT"), // ✅ Added default symbol
  ));
}

class OrderScreen extends StatefulWidget {
  final String symbol;
  const OrderScreen({super.key, required this.symbol});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  late WebSocketChannel channel;
  String currentPrice = "";

  late String selectedSymbol;

  final TextEditingController priceController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  String orderType = "Limit";

  @override
  void initState() {
    super.initState();
    selectedSymbol = widget.symbol;
    subscribePrice(selectedSymbol);
  }

  void subscribePrice(String symbol) {
    channel = WebSocketChannel.connect(
      Uri.parse('wss://stream.binance.com:9443/ws/${symbol.toLowerCase()}@trade'),
    );

    channel.stream.listen((data) {
      final jsonData = jsonDecode(data);
      final price = jsonData['p'];

      setState(() {
        currentPrice = price;
      });
    });
  }

  @override
  void dispose() {
    channel.sink.close();
    super.dispose();
  }

  void createOrder(String side) {
    final price = priceController.text.isEmpty ? currentPrice : priceController.text;
    final amount = amountController.text;

    globalOrders.add({
      "symbol": selectedSymbol,
      "type": side,
      "price": price,
      "amount": amount,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Order: $side $amount $selectedSymbol")),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          'Order - $selectedSymbol',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Price: ${currentPrice.isEmpty ? "Loading..." : currentPrice}',
              style: const TextStyle(color: Colors.white, fontSize: 20),
            ),
            const SizedBox(height: 16),

            DropdownButton<String>(
              dropdownColor: Colors.black,
              value: orderType,
              items: const [
                DropdownMenuItem(
                    value: "Limit",
                    child: Text("Limit", style: TextStyle(color: Colors.white))),
                DropdownMenuItem(
                    value: "Market",
                    child: Text("Market", style: TextStyle(color: Colors.white))),
              ],
              onChanged: (value) {
                setState(() {
                  orderType = value!;
                });
              },
            ),
            const SizedBox(height: 16),

            if (orderType == "Limit")
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: "Price",
                  labelStyle: TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(),
                ),
              ),

            if (orderType == "Limit") const SizedBox(height: 16),

            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: "Amount",
                labelStyle: TextStyle(color: Colors.white70),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  onPressed: () => createOrder("BUY"),
                  child: const Text("BUY"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () => createOrder("SELL"),
                  child: const Text("SELL"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
