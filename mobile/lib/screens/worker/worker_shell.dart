import 'package:flutter/material.dart';

import '../../core/theme.dart';
import 'assembly/order_list_screen.dart';
import 'summary/production_summary_screen.dart';

class WorkerShell extends StatefulWidget {
  const WorkerShell({super.key});

  @override
  State<WorkerShell> createState() => _WorkerShellState();
}

class _WorkerShellState extends State<WorkerShell> {
  int _index = 0;

  static const _pages = [
    ProductionSummaryScreen(),
    OrderListScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        backgroundColor: Colors.white,
        indicatorColor: BrandColors.black,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.scale_outlined),
            selectedIcon: Icon(Icons.scale, color: Colors.white),
            label: 'Сводка',
          ),
          NavigationDestination(
            icon: Icon(Icons.checklist_outlined),
            selectedIcon: Icon(Icons.checklist, color: Colors.white),
            label: 'Заказы',
          ),
        ],
      ),
    );
  }
}
