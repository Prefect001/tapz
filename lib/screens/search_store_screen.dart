import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/store.dart';
import '../services/store_service.dart';
import '../utils/shared_prefs.dart';

class SearchStoreScreen extends StatefulWidget {
  const SearchStoreScreen({Key? key}) : super(key: key);

  @override
  State<SearchStoreScreen> createState() => _SearchStoreScreenState();
}

class _SearchStoreScreenState extends State<SearchStoreScreen> {
  final StoreService _storeService = StoreService();
  final TextEditingController _searchCtrl = TextEditingController();

  List<Store> _allStores = [];
  List<Store> _filteredStores = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStores();
    _searchCtrl.addListener(_filterStores);
  }

  Future<void> _loadStores() async {
    final stores = await _storeService.getAllStores();
    if (mounted) {
      setState(() {
        _allStores = stores;
        _filteredStores = stores;
        _isLoading = false;
      });
    }
  }

  void _filterStores() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _filteredStores = _allStores;
      } else {
        _filteredStores = _allStores
            .where((s) =>
                s.storeName.toLowerCase().contains(q) ||
                s.address.toLowerCase().contains(q))
            .toList();
      }
    });
  }

  Future<void> _openDirections(Store store) async {
    final uri = Uri.parse(
        'google.navigation:q=${store.latitude},${store.longitude}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      final fallback = Uri.parse(
          'https://www.google.com/maps/dir/?api=1&destination=${store.latitude},${store.longitude}');
      await launchUrl(fallback, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search box — mirrors fragment_search_store.xml
        Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Search car guard',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8)),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
        ),

        if (_isLoading)
          const Expanded(
              child: Center(child: CircularProgressIndicator()))
        else if (_filteredStores.isEmpty)
          const Expanded(
            child: Center(
              child: Text('No car guards available',
                  style: TextStyle(fontSize: 16)),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              itemCount: _filteredStores.length,
              itemBuilder: (_, i) {
                final store = _filteredStores[i];
                return Card(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      children: [
                        // Store image
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: store.imageUrl.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: store.imageUrl,
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) =>
                                      const Icon(Icons.store, size: 40),
                                  errorWidget: (_, __, ___) =>
                                      const Icon(Icons.store, size: 40),
                                )
                              : Container(
                                  width: 80,
                                  height: 80,
                                  color: Colors.grey[200],
                                  child: const Icon(Icons.store,
                                      size: 40),
                                ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(store.storeName,
                                  style: const TextStyle(
                                      fontSize: 18,
                                      color: Colors.black,
                                      fontWeight:
                                          FontWeight.w500)),
                              if (store.address.isNotEmpty)
                                Text(store.address,
                                    style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.black54),
                                    maxLines: 2,
                                    overflow:
                                        TextOverflow.ellipsis),
                              if (store.storeExtraInfo.isNotEmpty)
                                Text(store.storeExtraInfo,
                                    style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.teal[700],
                                        fontStyle:
                                            FontStyle.italic),
                                    maxLines: 2),
                            ],
                          ),
                        ),
                        // Location icon — mirrors store_location in list_item_store.xml
                        if (store.latitude != 0 || store.longitude != 0)
                          IconButton(
                            icon: const Icon(Icons.directions,
                                color: Colors.blue, size: 36),
                            onPressed: () => _openDirections(store),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }
}