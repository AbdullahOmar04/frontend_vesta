import 'package:flutter/material.dart';
import 'package:frontend_vesta/Screens/Spending&Transaction/Transactions/transactions.dart';
import 'package:frontend_vesta/Screens/pages/home.dart';
import 'package:frontend_vesta/Screens/pages/profile.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [HomePage(), Transactions(), ProfilePage()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: Theme.of(context).colorScheme.surface,
          indicatorColor: Colors.transparent,
          labelTextStyle: WidgetStateProperty.all(
            TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        child: NavigationBar(
          height: 70,
          elevation: 0,
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          destinations: [
            NavigationDestination(
              icon: Icon(
                Icons.home_outlined,
                size: 30,
                color: _selectedIndex == 0
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey[500],
              ),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(
                Icons.receipt_long_outlined,
                size: 30,
                color: _selectedIndex == 1
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey[500],
              ),
              label: 'Transactions',
            ),
            NavigationDestination(
              icon: Icon(
                Icons.person_outline,
                size: 30,
                color: _selectedIndex == 2
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey[500],
              ),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
