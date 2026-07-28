import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tht_app/core/theme/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bottom navigation shell for the THT Prep learning module.
class PrepShell extends ConsumerWidget {
  const PrepShell({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.path;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    int getSelectedIndex() {
      if (location.startsWith('/prep-subjects')) return 1;
      if (location.startsWith('/prep-progress')) return 2;
      return 0; // /prep-dashboard
    }

    void onItemTapped(int index) {
      switch (index) {
        case 0:
          context.go('/prep-dashboard');
          break;
        case 1:
          context.go('/prep-subjects');
          break;
        case 2:
          context.go('/prep-progress');
          break;
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
          currentIndex: getSelectedIndex(),
          onTap: onItemTapped,
          selectedItemColor: AppColors.primaryOrange,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.book_outlined),
              activeIcon: Icon(Icons.book),
              label: 'Subjects',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.analytics_outlined),
              activeIcon: Icon(Icons.analytics),
              label: 'Progress',
            ),
          ],
        ),
      ),
    );
  }
}
