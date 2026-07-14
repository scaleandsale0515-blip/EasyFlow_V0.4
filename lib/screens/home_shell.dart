import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import 'dashboard/dashboard_screen.dart';
import 'production/production_list_screen.dart';
import 'transport/transport_list_screen.dart';
import 'more_menu_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    // Constructed fresh on every build (not cached in a final/const field)
    // so that when the app-level theme toggles, Flutter properly rebuilds
    // these screens instead of skipping them via identical-widget shortcut.
    // Each screen keeps its own State (scroll position, form data, selected
    // tab, etc.) across rebuilds since Flutter matches them by runtimeType,
    // not by instance identity - so nothing is lost, it just stops being
    // frozen on theme change.
    final screens = [
      DashboardScreen(),
      ProductionListScreen(),
      TransportListScreen(),
      MoreMenuScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        backgroundColor: AppColors.surface,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.precision_manufacturing_outlined), selectedIcon: Icon(Icons.precision_manufacturing), label: 'Production'),
          NavigationDestination(icon: Icon(Icons.local_shipping_outlined), selectedIcon: Icon(Icons.local_shipping), label: 'Transport'),
          NavigationDestination(icon: Icon(Icons.menu), selectedIcon: Icon(Icons.menu_open), label: 'More'),
        ],
      ),
    );
  }
}
