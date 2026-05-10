import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../models/store.dart';
import '../services/store_service.dart';
import '../utils/shared_prefs.dart';
import '../utils/constants.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final StoreService _storeService = StoreService();
  GoogleMapController? _mapController;
  Position? _currentPosition;
  List<Store> _stores = [];
  bool _isLoading = true;

  // Mirror of HomeFragment slider images
  final List<String> _sliderImages = [
    'https://res.cloudinary.com/do08niouc/image/upload/v1741028579/guard_rbv4zl.jpg',
    'https://res.cloudinary.com/do08niouc/image/upload/v1737128145/jprip4watdmwz0lyabyj.jpg',
    'https://res.cloudinary.com/do08niouc/image/upload/v1762197122/pexels-arts-1453781_bslpjo.jpg',
    'https://res.cloudinary.com/do08niouc/image/upload/v1762199728/pexels-wendywei-1190297_lxzo0s.jpg',
  ];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _getCurrentLocation();
    await _loadStores();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _loadLastLocation();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _loadLastLocation();
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        _loadLastLocation();
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() => _currentPosition = pos);
      _saveLastLocation(pos.latitude, pos.longitude);

      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(
          LatLng(pos.latitude, pos.longitude), 14));
    } catch (_) {
      _loadLastLocation();
    }
  }

  void _loadLastLocation() {
    final lat = double.tryParse(
        SharedPrefs.getString(Constants.lastLatitude, '-26.2041'));
    final lng = double.tryParse(
        SharedPrefs.getString(Constants.lastLongitude, '28.0473'));
    // Store defaults so map still has a starting position
    if (lat != null && lng != null && mounted) setState(() {});
  }

  void _saveLastLocation(double lat, double lng) {
    SharedPrefs.setString(Constants.lastLatitude, lat.toString());
    SharedPrefs.setString(Constants.lastLongitude, lng.toString());
  }

  Future<void> _loadStores() async {
    final zipcode = SharedPrefs.userZipcode.isNotEmpty
        ? SharedPrefs.userZipcode
        : '263139';
    final stores = await _storeService.getStoresByZipcode(zipcode);
    if (mounted) {
      setState(() {
        _stores = stores;
        _isLoading = false;
      });
    }
  }

  Set<Marker> _buildMarkers() {
    final markers = <Marker>{};

    if (_currentPosition != null) {
      markers.add(Marker(
        markerId: const MarkerId('current_location'),
        position:
            LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure),
        infoWindow: const InfoWindow(title: 'Current Location'),
      ));
    }

    for (final store in _stores) {
      markers.add(Marker(
        markerId: MarkerId(store.storeId),
        position: store.latLng,
        infoWindow: InfoWindow(title: store.storeName),
      ));
    }

    return markers;
  }

  @override
  Widget build(BuildContext context) {
    final initialTarget = _currentPosition != null
        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
        : const LatLng(-26.2041, 28.0473); // Default SA location

    return Column(
      children: [
        // Image Slider — mirrors HomeFragment
        Padding(
          padding: const EdgeInsets.all(16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: CarouselSlider(
              options: CarouselOptions(
                height: 200,
                autoPlay: true,
                autoPlayInterval: const Duration(seconds: 3),
                enlargeCenterPage: true,
                viewportFraction: 1.0,
              ),
              items: _sliderImages.map((url) {
                return Image.network(
                  url,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.image_not_supported)),
                );
              }).toList(),
            ),
          ),
        ),

        // Map info banner — mirrors fragment_home.xml
        Container(
          width: double.infinity,
          color: Colors.white.withOpacity(0.8),
          padding: const EdgeInsets.all(8),
          child: const Text(
            'Map shows service wrokers in your area.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.black87),
          ),
        ),

        // Google Map
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : GoogleMap(
                  onMapCreated: (c) => setState(() => _mapController = c),
                  initialCameraPosition: CameraPosition(
                    target: initialTarget,
                    zoom: 14,
                  ),
                  markers: _buildMarkers(),
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                ),
        ),
      ],
    );
  }
}