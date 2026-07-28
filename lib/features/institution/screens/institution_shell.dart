import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tht_app/core/theme/app_colors.dart';

/// Bottom navigation for institute accounts.
///
/// Was a drawer with Dashboard / Staff / Students / Classes. Students and
/// Classes had no API behind them outside THT Prep, and "Staff" was really the
/// platform-wide teacher directory rather than staff the institute employs.
/// The tabs now match what an institute can actually do here: see their
/// vacancies, post one, find teachers, and keep their profile straight.
class InstitutionShell extends StatelessWidget {
  const InstitutionShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    int selectedIndex() {
      if (location.startsWith('/inst-jobs') ||
          location.startsWith('/my-jobs')) {
        return 1;
      }
      if (location.startsWith('/inst-teachers')) return 2;
      if (location.startsWith('/inst-notifications')) return 3;
      if (location.startsWith('/inst-profile')) return 4;
      return 0; // /inst-dashboard
    }

    void onTap(int index) {
      switch (index) {
        case 0:
          context.go('/inst-dashboard');
        case 1:
          context.go('/inst-jobs');
        case 2:
          context.go('/inst-teachers');
        case 3:
          context.go('/inst-notifications');
        case 4:
          context.go('/inst-profile');
      }
    }

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
          currentIndex: selectedIndex(),
          onTap: onTap,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.work_outline),
              activeIcon: Icon(Icons.work),
              label: 'Vacancies',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_search_outlined),
              activeIcon: Icon(Icons.person_search),
              label: 'Teachers',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.notifications_outlined),
              activeIcon: Icon(Icons.notifications),
              label: 'Alerts',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.apartment_outlined),
              activeIcon: Icon(Icons.apartment),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
