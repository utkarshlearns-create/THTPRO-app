import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tht_app/core/auth/auth_provider.dart';
import 'package:tht_app/core/constants/contact.dart';
import 'package:tht_app/core/models/app_user.dart';
import 'package:tht_app/core/theme/app_colors.dart';
import 'package:tht_app/core/theme/app_type.dart';
import 'package:tht_app/core/ui/tone.dart';
import 'package:url_launcher/url_launcher.dart';

/// How someone gets credits now that the app does not sell them.
///
/// Credits are arranged by our team: someone works out what the account needs,
/// settles it, and adds the credits by hand, after which they appear in the
/// wallet here. The app's job is to put that person one tap away and to say
/// plainly what happens next, so an empty wallet is never a dead end.
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
  /// person who already needs help; this arrives as a sentence the desk can
  /// act on.
  ///
  /// It also names the account. Credits are added by hand, and a bare "I want
  /// credits" from an unknown number costs three questions before the work can
  /// even start — so the account id and the registered number travel with the
  /// ask. Nothing here is private to the sender: it is their own name, their
  /// own id and the number they are messaging from.
  static String _opener(bool isParent, AppUser? me) {
    final ask = isParent
        ? 'Hi, I would like credits on my The Home Tuitions account so I can '
            'unlock a teacher’s number.'
        : 'Hi, I would like credits on my The Home Tuitions teacher account.';
    if (me == null) return ask;

    final name = me.firstName.trim();
    final phone = (me.phone ?? '').trim();
    final lines = <String>[
      if (name.isNotEmpty) 'Name: $name',
      'Account ID: ${me.id}',
      if (phone.isNotEmpty) 'Registered number: $phone',
    ];
    return '$ask\n\n${lines.join('\n')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final muted = isDark ? AppColors.slate400 : AppColors.slate500;
    final isParent = ref.watch(authProvider).role == UserRole.parent;

    // Read, never awaited: if the profile has not loaded yet the sheet still
    // opens and the message simply goes without the account line. Holding a
    // spinner over a help sheet would be the wrong trade.
    final me = ref.watch(currentUserProvider).valueOrNull;

    // A teacher's credits are their own account's business, which is the tutor
    // desk's work rather than the public line's.
    final number = isParent ? ThtContact.phone : ThtContact.tutorAdminPhone;
    final numberLabel =
        isParent ? ThtContact.phoneLabel : ThtContact.tutorAdminPhoneLabel;

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
                  : 'Message our tutor desk and they will set your account up. '
                      'Credits appear in this wallet as soon as it is done.',
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
                  ThtContact.whatsappTo(number, _opener(isParent, me)),
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
                onPressed: () => _open(
                  context,
                  ThtContact.callTo(number),
                  'phone',
                ),
                icon: const Icon(Icons.call_rounded, size: 18),
                label: Text('Call $numberLabel'),
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
