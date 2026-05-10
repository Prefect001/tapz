class ProductItem {
  int? id;
  String productId;
  String productName;
  double productPrice;
  int productQuantity;
  String? imageUrl;

  ProductItem({
    this.id,
    required this.productId,
    required this.productName,
    required this.productPrice,
    this.productQuantity = 1,
    this.imageUrl,
  });

  factory ProductItem.fromMap(Map<String, dynamic> map) {
    final productId = map['productId']?.toString() ?? '';
    final productName = map['productName']?.toString() ?? '';

    double productPrice = 0.0;
    if (map['productPrice'] != null) {
      productPrice = (map['productPrice'] is double)
          ? map['productPrice']
          : double.tryParse(map['productPrice'].toString()) ?? 0.0;
    } else if (map['price'] != null) {
      productPrice = (map['price'] is double)
          ? map['price']
          : double.tryParse(map['price'].toString()) ?? 0.0;
    }

    int productQuantity = 1;
    if (map['productQuantity'] != null) {
      productQuantity = (map['productQuantity'] is int)
          ? map['productQuantity']
          : int.tryParse(map['productQuantity'].toString()) ?? 1;
    } else if (map['quantity'] != null) {
      productQuantity = (map['quantity'] is int)
          ? map['quantity']
          : int.tryParse(map['quantity'].toString()) ?? 1;
    }

    final id = map['id'] is int ? map['id'] : int.tryParse(map['id']?.toString() ?? '');

    return ProductItem(
      id: id,
      productId: productId,
      productName: productName,
      productPrice: productPrice,
      productQuantity: productQuantity,
      imageUrl: map['imageUrl']?.toString(),
    );
  }

  factory ProductItem.fromString(String rawData) {
    final parts = rawData.split('#');
    if (parts.length >= 3) {
      return ProductItem(
        productId: parts[0],
        productName: parts[1],
        productPrice: double.tryParse(parts[2]) ?? 0.0,
      );
    }
    throw const FormatException('Invalid product string format');
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'productId': productId,
      'productName': productName,
      'productPrice': productPrice,
      'productQuantity': productQuantity,
      if (imageUrl != null) 'imageUrl': imageUrl,
    };
  }

  Map<String, dynamic> toFirestoreMap() => toMap();

  void incrementQuantity() => productQuantity++;
  void decrementQuantity() {
    if (productQuantity > 1) productQuantity--;
  }
}