import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tht_app/core/auth/auth_provider.dart';
import 'package:tht_app/core/network/api_config.dart';
import 'package:tht_app/core/theme/app_colors.dart';
import 'package:tht_app/core/ui/async_view.dart';
import 'package:tht_app/core/ui/tht_card.dart';
import 'package:url_launcher/url_launcher.dart';

/// Shown when someone signs in with a role the app doesn't serve.
///
/// Their credentials are fine — counsellor, team leader and superadmin work
/// lives on the website, so the honest thing is to say so and hand them a link,
/// not to drop them on a blank dashboard.
class ContinueOnWebScreen extends ConsumerWidget {
  const ContinueOnWebScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(authProvider).role;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: THTCard(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0x26E1702E)
                            : AppColors.primaryOrangeLight,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: const Icon(
                        Icons.desktop_windows_outlined,
                        color: AppColors.primaryOrange,
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      '${role?.label ?? 'This'} tools live on the web',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                        color: isDark ? AppColors.slate50 : AppColors.slate900,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'The app covers parents, teachers and institutes. '
                      'Pipelines, approvals and reporting need a bigger screen, '
                      'so they stay on thehometuitions.com — sign in there with '
                      'these same details.',
                      style: TextStyle(
                        fontSize: 14.5,
                        height: 1.6,
                        color: isDark ? AppColors.slate300 : AppColors.slate600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => _openSite(context),
                        icon: const Icon(Icons.open_in_new_rounded, size: 18),
                        label: const Text('Open the website'),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () => ref.read(authProvider.notifier).logout(),
                        child: const Text('Sign in with a different account'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openSite(BuildContext context) async {
    final opened = await launchUrl(
      Uri.parse(ApiConfig.siteUrl),
      mode: LaunchMode.externalApplication,
    );
    if (!opened && context.mounted) {
      context.showMessage("Couldn't open the browser. Visit ${ApiConfig.siteUrl}");
    }
  }
}
