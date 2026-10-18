import 'package:flutter/material.dart';
import '../../core/theme/nomad_kit.dart';
import 'dashboard_page.dart';
import 'recipe_catalog_page.dart';
import 'ingredients_catalog_page.dart';
import 'account_settings_page.dart';

class MainNavShell extends StatefulWidget {
  const MainNavShell({super.key, this.initialTab = 0});
  final int initialTab;

  @override
  State<MainNavShell> createState() => MainNavShellState();
}

class MainNavShellState extends State<MainNavShell> {
  late int _currentIndex;

  final List<Widget> _pages = const [
    DashboardPage(),
    RecipeCatalogPage(),
    IngredientsCatalogPage(),
    AccountSettingsPage(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab;
  }

  void switchTab(int index) {
    if (mounted) {
      setState(() => _currentIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NomadKit.canvas,
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: _pages,
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: NomadKit.border)),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
          backgroundColor: Colors.white,
          indicatorColor: NomadKit.sandLight,
          elevation: 0,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined, color: NomadKit.secondary),
              selectedIcon: Icon(Icons.dashboard_rounded, color: NomadKit.sandDark),
              label: 'Tổng quan',
            ),
            NavigationDestination(
              icon: Icon(Icons.menu_book_outlined, color: NomadKit.secondary),
              selectedIcon: Icon(Icons.menu_book_rounded, color: NomadKit.sandDark),
              label: 'Công thức',
            ),
            NavigationDestination(
              icon: Icon(Icons.inventory_2_outlined, color: NomadKit.secondary),
              selectedIcon: Icon(Icons.inventory_2_rounded, color: NomadKit.sandDark),
              label: 'Nguyên liệu',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded, color: NomadKit.secondary),
              selectedIcon: Icon(Icons.person_rounded, color: NomadKit.sandDark),
              label: 'Tài khoản',
            ),
          ],
        ),
      ),
    );
  }
}
