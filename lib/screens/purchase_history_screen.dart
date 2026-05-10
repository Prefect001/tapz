import 'package:flutter/material.dart';
import '../models/order.dart';
import '../utils/app_database.dart';
import '../widgets/order_history_list.dart';

class PurchaseHistoryScreen extends StatefulWidget {
  const PurchaseHistoryScreen({Key? key}) : super(key: key);

  @override
  _PurchaseHistoryScreenState createState() => _PurchaseHistoryScreenState();
}

class _PurchaseHistoryScreenState extends State<PurchaseHistoryScreen> {
  List<Order> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    final db = AppDatabase();
    _orders = await db.getAllOrders();
    setState(() {
      _isLoading = false;
    });
  }

  void _showOrderDetails(Order order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Order Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Order ID', order.orderId),
              _buildDetailRow('Store', order.storeName),
              _buildDetailRow('Date', order.getFormattedDate()),
              _buildDetailRow('Total', 'R${order.totalPrice.toStringAsFixed(2)}'),
              if (order.transactionNumber != null)
                _buildDetailRow('Transaction', order.transactionNumber!),
              SizedBox(height: 16),
              Text('Items:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...order.items.map((item) => Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  '• ${item.productName} x${item.productQuantity} - R${(item.productPrice * item.productQuantity).toStringAsFixed(2)}',
                ),
              )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ', style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Purchase History')),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _orders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No orders yet', style: TextStyle(fontSize: 18)),
                      SizedBox(height: 8),
                      Text('Your purchase history will appear here', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : OrderHistoryList(
                  orders: _orders,
                  onOrderTap: _showOrderDetails,
                ),
    );
  }
}