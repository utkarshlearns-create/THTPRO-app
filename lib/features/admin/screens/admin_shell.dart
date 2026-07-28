import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tht_app/core/theme/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tht_app/core/auth/auth_provider.dart';

/// Navigation shell for Admin (Counsellor / Tutor Admin).
/// Uses a side drawer for navigation as these roles have many tools.
class AdminShell extends ConsumerWidget {
  const AdminShell({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.path;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Determine effective mode based on auth state (Counsellor vs Tutor Admin)
    final authState = ref.watch(authProvider);
    final effectiveMode = authState.effectiveAdminMode;
    final isTutorAdmin = effectiveMode == UserRole.tutorAdmin;

    return Scaffold(
      appBar: AppBar(
        title: Text(isTutorAdmin ? 'Tutor Admin' : 'Counsellor'),
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
                  'THT Workspace',
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
                    selected: location == '/admin-dashboard',
                    selectedColor: AppColors.primaryOrange,
                    onTap: () {
                      context.pop(); // close drawer
                      context.go('/admin-dashboard');
                    },
                  ),
                  if (!isTutorAdmin) ...[
                    ListTile(
                      leading: const Icon(Icons.people_outline),
                      title: const Text('My Clients'),
                      selected: location == '/admin-pipeline',
                      selectedColor: AppColors.primaryOrange,
                      onTap: () {
                        context.pop();
                        context.go('/admin-pipeline');
                      },
                    ),
                  ],
                  if (isTutorAdmin) ...[
                    ListTile(
                      leading: const Icon(Icons.verified_user_outlined),
                      title: const Text('KYC Verifications'),
                      selected: location == '/admin-kyc',
                      selectedColor: AppColors.primaryOrange,
                      onTap: () {
                        context.pop();
                        context.go('/admin-kyc');
                      },
                    ),
                  ],
                  ListTile(
                    leading: const Icon(Icons.business_outlined),
                    title: const Text('Institutions'),
                    selected: location == '/admin-institute',
                    selectedColor: AppColors.primaryOrange,
                    onTap: () {
                      context.pop();
                      context.go('/admin-institute');
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
