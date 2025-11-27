

class OrderModel {
  final String symbol;
  final String side;
  final String price;
  final String amount;
  final String type;
  final DateTime time;

  OrderModel({
    required this.symbol,
    required this.side,
    required this.price,
    required this.amount,
    required this.type,
    required this.time,
  });
}

List<OrderModel> globalOrders = []; // GLOBAL ORDER LIST
