import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tht_app/core/theme/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tht_app/core/auth/auth_provider.dart';

/// Navigation shell for Team Leaders.
class TeamLeaderShell extends ConsumerWidget {
  const TeamLeaderShell({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.path;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Team Leader'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.push('/notifications'),
          ),
        ],
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
                  'THT Leadership',
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
                    title: const Text('Home'),
                    selected: location == '/tl-home',
                    selectedColor: AppColors.primaryOrange,
                    onTap: () {
                      context.pop();
                      context.go('/tl-home');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.groups_outlined),
                    title: const Text('My Team'),
                    selected: location == '/tl-members',
                    selectedColor: AppColors.primaryOrange,
                    onTap: () {
                      context.pop();
                      context.go('/tl-members');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.view_timeline_outlined),
                    title: const Text('Team Pipeline'),
                    selected: location == '/tl-pipeline',
                    selectedColor: AppColors.primaryOrange,
                    onTap: () {
                      context.pop();
                      context.go('/tl-pipeline');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: const Text('My Pipeline'),
                    selected: location == '/tl-my-pipeline',
                    selectedColor: AppColors.primaryOrange,
                    onTap: () {
                      context.pop();
                      context.go('/tl-my-pipeline');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.insights_outlined),
                    title: const Text('Performance'),
                    selected: location == '/tl-performance',
                    selectedColor: AppColors.primaryOrange,
                    onTap: () {
                      context.pop();
                      context.go('/tl-performance');
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.track_changes_outlined),
                    title: const Text('Targets'),
                    selected: location == '/tl-targets',
                    selectedColor: AppColors.primaryOrange,
                    onTap: () {
                      context.pop();
                      context.go('/tl-targets');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.warning_amber_outlined),
                    title: const Text('Warnings'),
                    selected: location == '/tl-warnings',
                    selectedColor: AppColors.primaryOrange,
                    onTap: () {
                      context.pop();
                      context.go('/tl-warnings');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.history_outlined),
                    title: const Text('Action Logs'),
                    selected: location == '/tl-logs',
                    selectedColor: AppColors.primaryOrange,
                    onTap: () {
                      context.pop();
                      context.go('/tl-logs');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.file_download_outlined),
                    title: const Text('Reports'),
                    selected: location == '/tl-reports',
                    selectedColor: AppColors.primaryOrange,
                    onTap: () {
                      context.pop();
                      context.go('/tl-reports');
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
