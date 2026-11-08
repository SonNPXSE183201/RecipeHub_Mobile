import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/nomad_kit.dart';
import '../../core/models/app_models.dart';
import '../../core/services/mock_data_service.dart';
import '../../core/navigation/app_keys.dart';
import '../../core/viewmodels/notification_viewmodel.dart';
import '../../core/widgets/recipe_hub_logo.dart';
import '../lookup/counter_recipe_lookup_page.dart';
import '../learning/my_learning_page.dart';
import '../learning/notifications_page.dart';
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
    if (mounted) {
      setState(() => _currentIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRoleAdmin = MockDataService.instance.currentRole == UserRole.admin;
    final unreadNotifs = context.watch<NotificationViewModel>().unreadCount;

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
      appBar: AppBar(
        backgroundColor: NomadKit.canvas,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            const RecipeHubLogo(size: 32, iconSize: 18, radius: 10),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'RecipeHub',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: NomadKit.ink,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isRoleAdmin ? NomadKit.sandLight : NomadKit.forestLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isRoleAdmin ? 'ADMIN' : 'VIEWER',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: isRoleAdmin ? NomadKit.sandDark : NomadKit.forest,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  isRoleAdmin ? 'Quản lý đào tạo & Tiêu chuẩn' : 'Tra cứu quầy bar · Landmark 81',
                  style: const TextStyle(fontSize: 11, color: NomadKit.secondary),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                key: AppKeys.notificationBell,
                tooltip: 'Thông báo & Thay đổi',
                icon: Image.asset(
                  unreadNotifs > 0 ? 'assets/icons/nav_bell_active.png' : 'assets/icons/nav_bell.png',
                  width: 26,
                  height: 26,
                  filterQuality: FilterQuality.medium,
                  errorBuilder: (ctx, err, stack) => const Icon(Icons.notifications_none_rounded, size: 22),
                ),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NotificationsPage()),
                  );
                  // Shell có thể đã bị gỡ (đăng xuất/bị khóa khi đang ở trang Thông báo).
                  if (mounted) setState(() {});
                },
              ),
              if (unreadNotifs > 0)
                Positioned(
                  top: 10,
                  right: 12,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: NomadKit.error,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: NomadKit.border)),
        ),
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            backgroundColor: Colors.white,
            indicatorColor: Colors.transparent,
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: NomadKit.ink,
                );
              }
              return const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: NomadKit.secondary,
              );
            }),
          ),
          child: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
            backgroundColor: Colors.white,
            indicatorColor: Colors.transparent,
            overlayColor: WidgetStateProperty.all(Colors.transparent),
            elevation: 0,
            destinations: [
              NavigationDestination(
                icon: Image.asset('assets/icons/nav_home.png', width: 26, height: 26, filterQuality: FilterQuality.medium, errorBuilder: (ctx, err, stack) => const Icon(Icons.search_rounded, size: 24)),
                selectedIcon: Image.asset('assets/icons/nav_home_active.png', width: 28, height: 28, filterQuality: FilterQuality.medium, errorBuilder: (ctx, err, stack) => const Icon(Icons.search_rounded, size: 24)),
                label: 'Tra cứu',
              ),
              NavigationDestination(
                icon: Image.asset(
                  isRoleAdmin ? 'assets/icons/nav_training.png' : 'assets/icons/nav_learning.png',
                  width: 26,
                  height: 26,
                  filterQuality: FilterQuality.medium,
                  errorBuilder: (ctx, err, stack) => Icon(isRoleAdmin ? Icons.storefront_rounded : Icons.school_outlined, size: 24),
                ),
                selectedIcon: Image.asset(
                  isRoleAdmin ? 'assets/icons/nav_training_active.png' : 'assets/icons/nav_learning_active.png',
                  width: 28,
                  height: 28,
                  filterQuality: FilterQuality.medium,
                  errorBuilder: (ctx, err, stack) => Icon(isRoleAdmin ? Icons.storefront_rounded : Icons.school_rounded, size: 24),
                ),
                label: isRoleAdmin ? 'Đào tạo' : 'Việc học',
              ),
              NavigationDestination(
                icon: Image.asset('assets/icons/nav_feedback.png', width: 26, height: 26, filterQuality: FilterQuality.medium, errorBuilder: (ctx, err, stack) => const Icon(Icons.forum_outlined, size: 24)),
                selectedIcon: Image.asset('assets/icons/nav_feedback_active.png', width: 28, height: 28, filterQuality: FilterQuality.medium, errorBuilder: (ctx, err, stack) => const Icon(Icons.forum_rounded, size: 24)),
                label: 'Phản hồi',
              ),
              NavigationDestination(
                icon: Image.asset('assets/icons/nav_account.png', width: 26, height: 26, filterQuality: FilterQuality.medium, errorBuilder: (ctx, err, stack) => const Icon(Icons.person_outline_rounded, size: 24)),
                selectedIcon: Image.asset('assets/icons/nav_account_active.png', width: 28, height: 28, filterQuality: FilterQuality.medium, errorBuilder: (ctx, err, stack) => const Icon(Icons.person_rounded, size: 24)),
                label: 'Tài khoản',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
