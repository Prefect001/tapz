import 'package:flutter/material.dart';
import '../utils/shared_prefs.dart';
import '../utils/constants.dart';
import '../utils/app_database.dart';
import 'home_screen.dart';
import 'search_store_screen.dart';
import 'cart_screen.dart';
import 'account_screen.dart';
import 'login_screen.dart';
import 'profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _checkAuth();
    _clearCartIfNeeded();

    // If cart is active when we arrive, auto-navigate to cart tab
    if (SharedPrefs.isCartActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _navigateToCart());
    }
  }

  void _checkAuth() {
    if (!SharedPrefs.isLoggedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      });
    } else if (!SharedPrefs.isProfileDone) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (_) => const ProfileScreen(returnToPayment: false)));
      });
    }
  }

  void _clearCartIfNeeded() {
    if (!SharedPrefs.isCartActive) {
      AppDatabase().deleteAllCartItems();
    }
  }

  void _navigateToCart() {
    setState(() => _selectedIndex = 2);
  }

  List<Widget> get _screens => [
        const HomeScreen(),
        const SearchStoreScreen(),
        const CartScreen(),
        const AccountScreen(),
      ];

  String _getTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Home';
      case 1:
        return 'Search';
      case 2:
        return 'Tipping Activity';
      case 3:
        return 'Account';
      default:
        return 'Tapz';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_getTitle())),
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart), label: 'Tip'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person), label: 'Account'),
        ],
      ),
    );
  }
}