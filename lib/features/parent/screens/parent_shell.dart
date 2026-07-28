import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tht_app/core/theme/app_colors.dart';

/// The bottom navigation shell for Parent accounts.
/// Wraps child screens injected by GoRouter.
class ParentShell extends StatelessWidget {
  const ParentShell({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;

    // Finding a teacher is the parent's main job, so Explore gets a tab. The old
    // "Dashboard" tab duplicated Home once Home took on the stats.
    int getSelectedIndex() {
      if (location.startsWith('/find-teachers')) return 1;
      if (location.startsWith('/my-jobs')) return 2;
      if (location.startsWith('/wallet')) return 3;
      if (location.startsWith('/notifications')) return 4;
      return 0; // /parent-home
    }

    void onItemTapped(int index) {
      switch (index) {
        case 0:
          context.go('/parent-home');
          break;
        case 1:
          context.go('/find-teachers');
          break;
        case 2:
          context.go('/my-jobs');
          break;
        case 3:
          context.go('/wallet');
          break;
        case 4:
          context.go('/notifications');
          break;
      }
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.slate200,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: getSelectedIndex(),
          onTap: onItemTapped,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_search_outlined),
              activeIcon: Icon(Icons.person_search),
              label: 'Teachers',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.work_outline),
              activeIcon: Icon(Icons.work),
              label: 'Requirements',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet_outlined),
              activeIcon: Icon(Icons.account_balance_wallet),
              label: 'Wallet',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.notifications_outlined),
              activeIcon: Icon(Icons.notifications),
              label: 'Alerts',
            ),
          ],
        ),
      ),
    );
  }
}
