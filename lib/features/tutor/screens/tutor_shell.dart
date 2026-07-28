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

    // Ordered by how often a working teacher needs each one. KYC used to hold a
    // permanent tab despite being a one-time task, and "Dashboard" duplicated
    // Home once the home screen took on the stats; both are reached from
    // Profile and the home banner instead.
    int getSelectedIndex() {
      if (location.startsWith('/tutor-jobs')) return 1;
      if (location.startsWith('/tutor-schedule')) return 2;
      if (location.startsWith('/tutor-wallet')) return 3;
      if (location.startsWith('/tutor-profile')) return 4;
      return 0; // /tutor-home
    }

    void onItemTapped(int index) {
      switch (index) {
        case 0:
          context.go('/tutor-home');
          break;
        case 1:
          context.go('/tutor-jobs');
          break;
        case 2:
          context.go('/tutor-schedule');
          break;
        case 3:
          context.go('/tutor-wallet');
          break;
        case 4:
          context.go('/tutor-profile');
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
              icon: Icon(Icons.work_outline_rounded),
              activeIcon: Icon(Icons.work_rounded),
              label: 'Jobs',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.event_note_outlined),
              activeIcon: Icon(Icons.event_note),
              label: 'Tuitions',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet_outlined),
              activeIcon: Icon(Icons.account_balance_wallet),
              label: 'Wallet',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
