import 'package:flutter/material.dart';
import 'package:frontend_vesta/Screens/pages/home.dart';
import 'package:frontend_vesta/Screens/pages/wallet.dart';
import 'package:frontend_vesta/Screens/pages/profile.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [HomePage(), WalletPage(), ProfilePage()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.grey[100],
        indicatorColor: Colors.transparent,
        selectedIndex: _selectedIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined, size: 30),
            selectedIcon: Icon(Icons.home, color: Colors.black, size: 30),
            label: '',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined, size: 30),
            selectedIcon: Icon(
              Icons.account_balance_wallet_rounded,
              color: Colors.black,
              size: 30,
            ),
            label: '',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline, size: 30),
            selectedIcon: Icon(Icons.person, color: Colors.black, size: 30),
            label: '',
          ),
        ],
      ),
    );
  }
}
