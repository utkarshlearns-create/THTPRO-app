import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tht_app/core/theme/app_colors.dart';

/// The bottom navigation shell for Tutor accounts.
/// Wraps child screens injected by GoRouter.
class TutorShell extends StatelessWidget {
  const TutorShell({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;

    int getSelectedIndex() {
      if (location.startsWith('/tutor-dashboard')) return 1;
      if (location.startsWith('/tutor-kyc')) return 2;
      if (location.startsWith('/tutor-wallet')) return 3;
      if (location.startsWith('/tutor-notifications')) return 4;
      return 0; // /tutor-home
    }

    void onItemTapped(int index) {
      switch (index) {
        case 0:
          context.go('/tutor-home');
          break;
        case 1:
          context.go('/tutor-dashboard');
          break;
        case 2:
          context.go('/tutor-kyc');
          break;
        case 3:
          context.go('/tutor-wallet');
          break;
        case 4:
          context.go('/tutor-notifications');
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
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.verified_user_outlined),
              activeIcon: Icon(Icons.verified_user),
              label: 'KYC',
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
