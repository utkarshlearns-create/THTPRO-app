import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tht_app/core/auth/auth_provider.dart';
import 'package:tht_app/core/constants/contact.dart';
import 'package:tht_app/core/theme/app_colors.dart';
import 'package:tht_app/core/theme/app_type.dart';
import 'package:tht_app/core/ui/tone.dart';
import 'package:url_launcher/url_launcher.dart';

/// How someone gets credits now that the app does not sell them.
///
/// Credits are arranged by our team: a counsellor works out what the account
/// needs, settles it, and the credits appear in the wallet here. The app's job
/// is to put that person one tap away and to say plainly what happens next, so
/// an empty wallet is never a dead end.
///
/// This is the only place in the app that answers "how do I get credits", and
/// every screen that used to push a checkout opens it instead.
class CreditsHelpSheet extends ConsumerWidget {
  const CreditsHelpSheet({super.key});

  static Future<void> show(BuildContext context) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => const CreditsHelpSheet(),
      );

  /// What the team is being asked for, written from the sender's side.
  ///
  /// Opening WhatsApp on an empty chat puts the work of explaining on the
  /// person who already needs help; this arrives as a sentence a counsellor
  /// can act on.
  static String _opener(bool isParent) => isParent
      ? 'Hi, I would like credits on my The Home Tuitions account so I can '
          'unlock a teacher’s number.'
      : 'Hi, I would like credits on my The Home Tuitions teacher account.';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final muted = isDark ? AppColors.slate400 : AppColors.slate500;
    final isParent = ref.watch(authProvider).role == UserRole.parent;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.support_agent_rounded,
                  size: 22,
                  color: Tone.accent.foreground(brightness),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Our team adds your credits',
                    style: TextStyle(
                      fontSize: ThtType.title,
                      fontWeight: FontWeight.w800,
                      height: 1.3,
                      color: isDark ? AppColors.slate50 : AppColors.slate900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              isParent
                  ? 'Tell us which teacher you want to reach and we will set '
                      'your account up. Credits appear in this wallet as soon '
                      'as it is done.'
                  : 'Tell us the areas and subjects you teach and we will set '
                      'your account up. Credits appear in this wallet as soon '
                      'as it is done.',
              style: TextStyle(
                fontSize: ThtType.bodyStrong,
                height: 1.55,
                color: isDark ? AppColors.slate200 : AppColors.slate700,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _open(
                  context,
                  ThtContact.whatsappAbout(_opener(isParent)),
                  'WhatsApp',
                ),
                icon: const Icon(Icons.chat_rounded, size: 18),
                label: const Text('Message us on WhatsApp'),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () =>
                    _open(context, ThtContact.call, 'phone'),
                icon: const Icon(Icons.call_rounded, size: 18),
                label: const Text('Call ${ThtContact.phoneLabel}'),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              // Said out loud because the alternative is someone sitting on an
              // empty wallet thinking the app is closed to them.
              isParent
                  ? 'Posting what you need is free, and teachers come to you — '
                      'credits are only a shortcut.'
                  : 'Applying to tuitions is always free. Credits are only '
                      'needed to be assigned one.',
              style: TextStyle(
                fontSize: ThtType.body,
                height: 1.5,
                color: muted,
              ),
            ),
            const SizedBox(height: AppSpacing.base),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _open(BuildContext context, Uri uri, String what) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) {
      messenger?.showSnackBar(
        SnackBar(content: Text("Couldn't open your $what.")),
      );
    }
  }
}
