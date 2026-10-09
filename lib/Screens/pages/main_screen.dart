import 'package:flutter/material.dart';
import 'package:frontend_vesta/Helpers/icons.dart';
import 'package:frontend_vesta/Helpers/ui.dart';
import 'package:frontend_vesta/Screens/pages/accounts.dart';
import 'package:frontend_vesta/Screens/pages/dashboard.dart';
import 'package:frontend_vesta/Screens/pages/home.dart';
import 'package:frontend_vesta/Screens/pages/profile.dart';
import 'package:frontend_vesta/deep_link_service.dart';
import 'package:frontend_vesta/main.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  static const int _walletIndex = 2;

  int _selectedIndex = 0;

  // Home / Dashboard / Wallet / Profile, as in the prototype. Transactions
  // opens from the Dashboard's Recent section and from Spendings.
  static const List<VestaNavItem> _tabs = [
    VestaNavItem(
      label: 'Home',
      icon: PhosphorIconsRegular.house,
      selectedIcon: PhosphorIconsFill.house,
    ),
    VestaNavItem(
      label: 'Dashboard',
      icon: PhosphorIconsRegular.chartLineUp,
      selectedIcon: PhosphorIconsFill.chartLineUp,
    ),
    VestaNavItem(
      label: 'Wallet',
      icon: PhosphorIconsRegular.wallet,
      selectedIcon: PhosphorIconsFill.wallet,
    ),
    VestaNavItem(
      label: 'Profile',
      icon: PhosphorIconsRegular.userCircle,
      selectedIcon: PhosphorIconsFill.userCircle,
    ),
  ];

  @override
  void initState() {
    super.initState();
    deepLinkService.init(context, navigatorKey: navigatorKey);
    deepLinkService.checkPendingLink(context);
  }

  void _select(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _page(int index) {
    switch (index) {
      case 1:
        return DashboardPage(onOpenWallet: () => _select(_walletIndex));
      case _walletIndex:
        return const AccountsPage(showBack: false);
      case 3:
        return const ProfilePage();
      default:
        return HomePage(onOpenWallet: () => _select(_walletIndex));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _page(_selectedIndex),
      bottomNavigationBar: VestaBottomBar(
        items: _tabs,
        selectedIndex: _selectedIndex,
        onSelected: _select,
      ),
    );
  }
}
