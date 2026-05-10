import 'package:flutter/material.dart';
import '../models/order.dart';

class OrderHistoryList extends StatelessWidget {
  final List<Order> orders;
  final Function(Order) onOrderTap;

  const OrderHistoryList({
    Key? key,
    required this.orders,
    required this.onOrderTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return _OrderItemTile(
          order: order,
          onTap: () => onOrderTap(order),
        );
      },
    );
  }
}

class _OrderItemTile extends StatelessWidget {
  final Order order;
  final Function() onTap;

  const _OrderItemTile({
    Key? key,
    required this.order,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: ListTile(
        leading: Icon(Icons.receipt, size: 40, color: Colors.blue),
        title: Text(
          order.storeName,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Text(
              'Order ID: ${order.orderId}',
              style: TextStyle(fontSize: 12),
            ),
            SizedBox(height: 2),
            Text(
              order.getFormattedDate(),
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'R${order.totalPrice.toStringAsFixed(2)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.green,
              ),
            ),
            SizedBox(height: 2),
            Text(
              '${order.totalQuantity} items',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}