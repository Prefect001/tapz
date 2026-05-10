import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/store.dart';

class StoresList extends StatefulWidget {
  final List<Store> stores;
  final Function(Store) onStoreTap;

  const StoresList({
    Key? key,
    required this.stores,
    required this.onStoreTap,
  }) : super(key: key);

  @override
  _StoresListState createState() => _StoresListState();
}

class _StoresListState extends State<StoresList> {
  final TextEditingController _searchController = TextEditingController();
  List<Store> _filteredStores = [];

  @override
  void initState() {
    super.initState();
    _filteredStores = widget.stores;
    _searchController.addListener(_filterStores);
  }

  void _filterStores() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredStores = widget.stores;
      } else {
        _filteredStores = widget.stores.where((store) {
          return store.storeName.toLowerCase().contains(query) ||
              store.address.toLowerCase().contains(query) ||
              (store.storeExtraInfo?.toLowerCase().contains(query) ?? false);
        }).toList();
      }
    });
  }

  Future<void> _navigateToStore(Store store) async {
    final url = 'https://www.google.com/maps/dir/?api=1&destination=${store.latitude},${store.longitude}';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch Google Maps')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(12),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search stores...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
        ),
        Expanded(
          child: _filteredStores.isEmpty
              ? Center(
                  child: Text(
                    'No stores found',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  itemCount: _filteredStores.length,
                  itemBuilder: (context, index) {
                    final store = _filteredStores[index];
                    return _StoreItemTile(
                      store: store,
                      onTap: () => widget.onStoreTap(store),
                      onNavigate: () => _navigateToStore(store),
                    );
                  },
                ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class _StoreItemTile extends StatelessWidget {
  final Store store;
  final Function() onTap;
  final Function() onNavigate;

  const _StoreItemTile({
    Key? key,
    required this.store,
    required this.onTap,
    required this.onNavigate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: ListTile(
        leading: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey[200],
          ),
          child: store.imageUrl.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: store.imageUrl,
                  placeholder: (context, url) => Icon(Icons.store, size: 30),
                  errorWidget: (context, url, error) => Icon(Icons.store, size: 30),
                  fit: BoxFit.cover,
                )
              : Icon(Icons.store, size: 30, color: Colors.blue),
        ),
        title: Text(
          store.storeName,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Text(
              store.address,
              style: TextStyle(fontSize: 14),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (store.storeExtraInfo != null && store.storeExtraInfo!.isNotEmpty) ...[
              SizedBox(height: 2),
              Text(
                store.storeExtraInfo!,
                style: TextStyle(fontSize: 12, color: Colors.grey),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
        trailing: IconButton(
          icon: Icon(Icons.directions, color: Colors.blue),
          onPressed: onNavigate,
          tooltip: 'Get Directions',
        ),
        onTap: onTap,
        contentPadding: EdgeInsets.all(12),
      ),
    );
  }
}