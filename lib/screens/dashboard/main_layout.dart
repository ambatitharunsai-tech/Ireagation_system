import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/farm_provider.dart';
import '../../providers/finance_provider.dart';
import '../../providers/iot_provider.dart';
import 'dashboard_screen.dart';
import '../iot/iot_dashboard_screen.dart';
import '../crops/crop_list_screen.dart';
import '../finance/finance_screen.dart';
import '../more/more_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAllData();
    });
  }

  Future<void> _loadAllData() async {
    final userId = Provider.of<AuthProvider>(
      context,
      listen: false,
    ).currentUser?.id;
    if (userId != null) {
      // Fire and forget - don't block the UI
      Provider.of<FarmProvider>(context, listen: false).loadData(userId);
      Provider.of<FinanceProvider>(context, listen: false).loadData(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final iot = Provider.of<IoTProvider>(context);

    final pages = [
      const DashboardScreen(),
      const IoTDashboardScreen(),
      const CropListScreen(),
      const FinanceScreen(),
      const MoreScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: iot.unreadAlertCount > 0,
              label: Text('${iot.unreadAlertCount}'),
              child: const Icon(Icons.sensors_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: iot.unreadAlertCount > 0,
              label: Text('${iot.unreadAlertCount}'),
              child: const Icon(Icons.sensors),
            ),
            label: 'IoT',
          ),
          const NavigationDestination(
            icon: Icon(Icons.grass_outlined),
            selectedIcon: Icon(Icons.grass),
            label: 'Crops',
          ),
          const NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'Finance',
          ),
          const NavigationDestination(
            icon: Icon(Icons.menu_outlined),
            selectedIcon: Icon(Icons.menu),
            label: 'More',
          ),
        ],
      ),
    );
  }
}
