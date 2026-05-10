import 'package:flutter/material.dart';
import '../models/product_item.dart';

class CartItemsList extends StatelessWidget {
  final List<ProductItem> items;
  final Function(ProductItem, int) onIncrement;
  final Function(ProductItem, int) onDecrement;
  final Function(ProductItem, int) onDelete;

  const CartItemsList({
    Key? key,
    required this.items,
    required this.onIncrement,
    required this.onDecrement,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _CartItemTile(
          item: item,
          index: index,
          onIncrement: onIncrement,
          onDecrement: onDecrement,
          onDelete: onDelete,
        );
      },
    );
  }
}

class _CartItemTile extends StatelessWidget {
  final ProductItem item;
  final int index;
  final Function(ProductItem, int) onIncrement;
  final Function(ProductItem, int) onDecrement;
  final Function(ProductItem, int) onDelete;

  const _CartItemTile({
    Key? key,
    required this.item,
    required this.index,
    required this.onIncrement,
    required this.onDecrement,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ListTile(
        leading: Icon(Icons.shopping_basket, size: 40),
        title: Text(
          item.productName,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('R${item.productPrice.toStringAsFixed(2)} each'),
            SizedBox(height: 4),
            _buildQuantityControls(),
          ],
        ),
        trailing: IconButton(
          icon: Icon(Icons.delete, color: Colors.red),
          onPressed: () => onDelete(item, index),
        ),
      ),
    );
  }

  Widget _buildQuantityControls() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(Icons.remove, size: 20),
          onPressed: () => onDecrement(item, index),
          padding: EdgeInsets.zero,
          constraints: BoxConstraints(),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            item.productQuantity.toString(),
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        IconButton(
          icon: Icon(Icons.add, size: 20),
          onPressed: () => onIncrement(item, index),
          padding: EdgeInsets.zero,
          constraints: BoxConstraints(),
        ),
      ],
    );
  }
}