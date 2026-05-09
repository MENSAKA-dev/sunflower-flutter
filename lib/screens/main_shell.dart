import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'dashboard_screen.dart';
import 'products_screen.dart';
import 'sales_screen.dart';
import 'customers_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _idx = 0;

  static const _destinations = [
    NavigationRailDestination(
      icon: Icon(Icons.dashboard_outlined),
      selectedIcon: Icon(Icons.dashboard),
      label: Text('Dashboard'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.inventory_2_outlined),
      selectedIcon: Icon(Icons.inventory_2),
      label: Text('Productos'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.point_of_sale_outlined),
      selectedIcon: Icon(Icons.point_of_sale),
      label: Text('Ventas'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.people_outline),
      selectedIcon: Icon(Icons.people),
      label: Text('Clientes'),
    ),
  ];

  static const _bottomItems = [
    BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), label: 'Dashboard'),
    BottomNavigationBarItem(icon: Icon(Icons.inventory_2_outlined), label: 'Productos'),
    BottomNavigationBarItem(icon: Icon(Icons.point_of_sale_outlined), label: 'Ventas'),
    BottomNavigationBarItem(icon: Icon(Icons.people_outline), label: 'Clientes'),
  ];

  final _screens = const [
    DashboardScreen(),
    ProductsScreen(),
    SalesScreen(),
    CustomersScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width >= 800;

    if (wide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _idx,
              onDestinationSelected: (i) => setState(() => _idx = i),
              labelType: NavigationRailLabelType.all,
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(children: [
                  const Icon(Icons.local_florist, color: AppTheme.primary, size: 32),
                  const SizedBox(height: 4),
                  Text('SUNFLOWER',
                      style: TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          letterSpacing: 1.2)),
                ]),
              ),
              destinations: _destinations,
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(child: _screens[_idx]),
          ],
        ),
      );
    }

    return Scaffold(
      body: _screens[_idx],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _idx,
        onTap: (i) => setState(() => _idx = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.primary,
        unselectedItemColor: Colors.grey,
        items: _bottomItems,
      ),
    );
  }
}
