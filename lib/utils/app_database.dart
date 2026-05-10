import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/product_item.dart';
import '../models/order.dart';

class AppDatabase {
  static AppDatabase? _instance;
  Database? _database;

  AppDatabase._internal();

  factory AppDatabase() {
    _instance ??= AppDatabase._internal();
    return _instance!;
  }

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'NoQueuePay.db');

    return openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE new_cart (
            ID INTEGER PRIMARY KEY AUTOINCREMENT,
            product_id TEXT,
            product_name TEXT,
            product_price REAL,
            product_quantity INTEGER
          )
        ''');
        await db.execute('''
          CREATE TABLE order_history (
            ID INTEGER PRIMARY KEY AUTOINCREMENT,
            orderId TEXT,
            store_id TEXT,
            store_name TEXT,
            userId TEXT,
            userName TEXT,
            total_quantity INTEGER,
            total_price REAL,
            transaction_number TEXT,
            date TEXT,
            paymentMethod TEXT,
            items TEXT
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // Destructive migration like Java version
        await db.execute('DROP TABLE IF EXISTS new_cart');
        await db.execute('DROP TABLE IF EXISTS order_history');
        await db.execute('''
          CREATE TABLE new_cart (
            ID INTEGER PRIMARY KEY AUTOINCREMENT,
            product_id TEXT,
            product_name TEXT,
            product_price REAL,
            product_quantity INTEGER
          )
        ''');
        await db.execute('''
          CREATE TABLE order_history (
            ID INTEGER PRIMARY KEY AUTOINCREMENT,
            orderId TEXT,
            store_id TEXT,
            store_name TEXT,
            userId TEXT,
            userName TEXT,
            total_quantity INTEGER,
            total_price REAL,
            transaction_number TEXT,
            date TEXT,
            paymentMethod TEXT,
            items TEXT
          )
        ''');
      },
    );
  }

  // ── Cart ──────────────────────────────────────────────

  Future<void> insertProduct(ProductItem item) async {
    final db = await database;
    await db.insert(
      'new_cart',
      {
        'product_id': item.productId,
        'product_name': item.productName,
        'product_price': item.productPrice,
        'product_quantity': item.productQuantity,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteProduct(int id) async {
    final db = await database;
    await db.delete('new_cart', where: 'ID = ?', whereArgs: [id]);
  }

  Future<void> incrementQuantity(int id) async {
    final db = await database;
    await db.rawUpdate(
        'UPDATE new_cart SET product_quantity = product_quantity + 1 WHERE ID = ?',
        [id]);
  }

  Future<void> decrementQuantity(int id) async {
    final db = await database;
    await db.rawUpdate(
        'UPDATE new_cart SET product_quantity = product_quantity - 1 WHERE ID = ?',
        [id]);
  }

  Future<List<ProductItem>> getCartItems() async {
    final db = await database;
    final maps = await db.query('new_cart');
    return maps
        .map((m) => ProductItem(
              id: m['ID'] as int?,
              productId: m['product_id'] as String,
              productName: m['product_name'] as String,
              productPrice: m['product_price'] as double,
              productQuantity: m['product_quantity'] as int,
            ))
        .toList();
  }

  Future<void> deleteAllCartItems() async {
    final db = await database;
    await db.delete('new_cart');
  }

  // ── Orders ────────────────────────────────────────────

  Future<void> insertOrder(Order order) async {
    final db = await database;
    final itemsStr = order.items
        .map((i) =>
            '${i.id ?? 0},${i.productId},${i.productName},${i.productPrice},${i.productQuantity}')
        .join('|');

    await db.insert(
      'order_history',
      {
        'orderId': order.orderId,
        'store_id': order.storeId,
        'store_name': order.storeName,
        'userId': order.userId,
        'userName': order.userName,
        'total_quantity': order.totalQuantity,
        'total_price': order.totalPrice,
        'transaction_number': order.transactionNumber,
        'date': order.date.toIso8601String(),
        'paymentMethod': order.paymentMethod,
        'items': itemsStr,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Order>> getAllOrders() async {
    final db = await database;
    final maps = await db.query('order_history', orderBy: 'ID DESC');

    return maps.map((m) {
      List<ProductItem> items = [];
      final itemsStr = m['items'] as String? ?? '';
      if (itemsStr.isNotEmpty) {
        items = itemsStr.split('|').map((s) {
          final p = s.split(',');
          if (p.length >= 5) {
            return ProductItem(
              id: int.tryParse(p[0]),
              productId: p[1],
              productName: p[2],
              productPrice: double.tryParse(p[3]) ?? 0,
              productQuantity: int.tryParse(p[4]) ?? 1,
            );
          }
          return ProductItem(productId: '', productName: '', productPrice: 0);
        }).toList();
      }

      return Order(
        id: m['ID'] as int?,
        orderId: m['orderId'] as String,
        storeId: m['store_id'] as String,
        storeName: m['store_name'] as String? ?? '',
        userId: m['userId'] as String? ?? '',
        userName: m['userName'] as String? ?? '',
        totalQuantity: m['total_quantity'] as int,
        totalPrice: m['total_price'] as double,
        transactionNumber: m['transaction_number'] as String?,
        date: DateTime.tryParse(m['date'] as String? ?? '') ?? DateTime.now(),
        paymentMethod: m['paymentMethod'] as String?,
        items: items,
      );
    }).toList();
  }
}