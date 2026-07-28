import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tht_app/core/theme/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tht_app/core/auth/auth_provider.dart';

/// Navigation shell for Institution role.
class InstitutionShell extends ConsumerWidget {
  const InstitutionShell({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.path;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Institution Portal'),
      ),
      drawer: Drawer(
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.slate50,
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? AppColors.darkBorder : AppColors.slate200,
                  ),
                ),
              ),
              child: const Center(
                child: Text(
                  'Institution',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryOrange,
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  ListTile(
                    leading: const Icon(Icons.dashboard_outlined),
                    title: const Text('Dashboard'),
                    selected: location == '/inst-dashboard',
                    selectedColor: AppColors.primaryOrange,
                    onTap: () {
                      context.pop();
                      context.go('/inst-dashboard');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.badge_outlined),
                    title: const Text('Staff & Teachers'),
                    selected: location == '/inst-staff',
                    selectedColor: AppColors.primaryOrange,
                    onTap: () {
                      context.pop();
                      context.go('/inst-staff');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.school_outlined),
                    title: const Text('Students'),
                    selected: location == '/inst-students',
                    selectedColor: AppColors.primaryOrange,
                    onTap: () {
                      context.pop();
                      context.go('/inst-students');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.class_outlined),
                    title: const Text('Classes / Batches'),
                    selected: location == '/inst-classes',
                    selectedColor: AppColors.primaryOrange,
                    onTap: () {
                      context.pop();
                      context.go('/inst-classes');
                    },
                  ),
                ],
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: AppColors.error),
              title: const Text('Sign Out', style: TextStyle(color: AppColors.error)),
              onTap: () {
                context.pop();
                ref.read(authProvider.notifier).logout();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      body: child,
    );
  }
}
