import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tht_app/core/auth/auth_provider.dart';
import 'package:tht_app/core/network/token_storage.dart';
import 'package:tht_app/features/shared/widgets/tht_button.dart';

/// Parent's home tab (default landing after login).
class ParentHomeScreen extends ConsumerStatefulWidget {
  const ParentHomeScreen({super.key});

  @override
  ConsumerState<ParentHomeScreen> createState() => _ParentHomeScreenState();
}

class _ParentHomeScreenState extends ConsumerState<ParentHomeScreen> {
  String _name = 'Parent';

  @override
  void initState() {
    super.initState();
    _loadName();
  }

  Future<void> _loadName() async {
    final name = await TokenStorage.getName() ??
        await TokenStorage.getUsername() ??
        'Parent';
    setState(() => _name = name);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('The Home Tuitions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authProvider.notifier).logout();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back,\n$_name',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 32),

              // Actions
              ThtButton(
                label: 'Post a New Job',
                icon: Icons.add_circle_outline,
                onPressed: () {
                  // TODO: Navigate to job wizard
                },
                isExpanded: true,
              ),
              const SizedBox(height: 16),
              ThtButton(
                label: 'Find Tutors',
                icon: Icons.search,
                variant: ThtButtonVariant.outlined,
                onPressed: () => context.push('/explore'),
                isExpanded: true,
              ),
              
              // Recent jobs summary would go here
            ],
          ),
        ),
      ),
    );
  }
}
