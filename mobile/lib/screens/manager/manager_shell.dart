import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme.dart';
import '../../widgets/fade_in.dart';
import 'catalog/catalog_screen.dart';
import 'clients/clients_screen.dart';
import 'dashboard/manager_dashboard_screen.dart';
import 'orders/manager_orders_screen.dart';

/// Manager mode's four top-level destinations, always one thumb-tap away —
/// previously these lived as small icon buttons buried in the dashboard's
/// AppBar, which is why "where do I find X" wasn't obvious.
class ManagerShell extends StatefulWidget {
  const ManagerShell({super.key});

  @override
  State<ManagerShell> createState() => _ManagerShellState();
}

class _ManagerShellState extends State<ManagerShell> {
  int _index = 0;

  static const _pages = [
    ManagerDashboardScreen(),
    ManagerOrdersScreen(),
    CatalogScreen(),
    ClientsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeIndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) {
          HapticFeedback.selectionClick();
          setState(() => _index = i);
        },
        backgroundColor: Colors.white,
        indicatorColor: AppColors.black,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights, color: AppColors.yellow),
            label: 'Дашборд',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long, color: AppColors.yellow),
            label: 'Заказы',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2, color: AppColors.yellow),
            label: 'Каталог',
          ),
          NavigationDestination(
            icon: Icon(Icons.store_outlined),
            selectedIcon: Icon(Icons.store, color: AppColors.yellow),
            label: 'Склады',
          ),
        ],
      ),
    );
  }
}
