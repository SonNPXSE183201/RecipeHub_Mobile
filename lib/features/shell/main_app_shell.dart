import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/theme/nomad_kit.dart';
import '../../core/viewmodels/auth_viewmodel.dart';
import '../lookup/counter_recipe_lookup_page.dart';
import '../learning/my_learning_page.dart';
import '../feedback/my_feedback_list_page.dart';
import '../account/account_profile_page.dart';
import '../admin_training/admin_store_training_page.dart';

class MainAppShell extends StatefulWidget {
  const MainAppShell({super.key, this.initialTabIndex = 0});

  final int initialTabIndex;

  @override
  State<MainAppShell> createState() => MainAppShellState();
}

class MainAppShellState extends State<MainAppShell> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTabIndex;
  }

  void switchTab(int index) {
    if (mounted && index != _currentIndex) {
      ScaffoldMessenger.of(context).clearSnackBars();
      setState(() => _currentIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final isRoleAdmin = auth.isAdmin;

    final List<Widget> pages = isRoleAdmin
        ? const [
            CounterRecipeLookupPage(),
            AdminStoreTrainingPage(),
            MyFeedbackListPage(),
            AccountProfilePage(),
          ]
        : const [
            CounterRecipeLookupPage(),
            MyLearningPage(),
            MyFeedbackListPage(),
            AccountProfilePage(),
          ];

    return Scaffold(
      backgroundColor: NomadKit.canvas,
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: _RedesignBottomNavigation(
        currentIndex: _currentIndex,
        isAdmin: isRoleAdmin,
        onSelected: switchTab,
      ),
    );
  }
}

class _RedesignBottomNavigation extends StatelessWidget {
  const _RedesignBottomNavigation({
    required this.currentIndex,
    required this.isAdmin,
    required this.onSelected,
  });

  final int currentIndex;
  final bool isAdmin;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final items = <(String, String)>[
      ('Tra cứu', 'assets/redesign/nav_lookup.svg'),
      (isAdmin ? 'Đào tạo' : 'Việc học', 'assets/redesign/nav_learning.svg'),
      ('Phản hồi', 'assets/redesign/nav_feedback.svg'),
      ('Tài khoản', 'assets/redesign/nav_account.svg'),
    ];
    return Container(
      decoration: const BoxDecoration(
        color: NomadKit.surface,
        border: Border(top: BorderSide(color: NomadKit.border)),
      ),
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.1,
        child: NavigationBar(
          height: 80,
          elevation: 0,
          backgroundColor: NomadKit.surface,
          indicatorColor: NomadKit.sandLight,
          indicatorShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
          selectedIndex: currentIndex,
          onDestinationSelected: onSelected,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            for (final item in items)
              NavigationDestination(
                icon: SvgPicture.asset(
                  item.$2,
                  width: 24,
                  height: 24,
                  colorFilter: const ColorFilter.mode(
                    NomadKit.secondary,
                    BlendMode.srcIn,
                  ),
                ),
                selectedIcon: SvgPicture.asset(
                  item.$2,
                  width: 24,
                  height: 24,
                  colorFilter: const ColorFilter.mode(
                    NomadKit.sandDark,
                    BlendMode.srcIn,
                  ),
                ),
                label: item.$1,
              ),
          ],
        ),
      ),
    );
  }
}
