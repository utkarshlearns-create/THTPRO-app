import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tht_app/core/auth/auth_provider.dart';
import 'package:tht_app/core/network/api_config.dart';
import 'package:tht_app/core/repositories/users_repository.dart';
import 'package:tht_app/core/theme/app_colors.dart';
import 'package:tht_app/core/ui/note_box.dart';
import 'package:tht_app/core/ui/section_header.dart';
import 'package:tht_app/core/ui/tht_card.dart';
import 'package:tht_app/core/ui/tone.dart';
import 'package:tht_app/core/utils/api_error.dart';
import 'package:url_launcher/url_launcher.dart';

/// Getting help — for parents, teachers and institutes alike.
///
/// The ways out of this screen are ordered by how fast they answer: ask the
/// assistant, message us on WhatsApp, or send a written enquiry.
///
/// Deliberately **not** a ticket tracker. `jobs/support/tickets/` is
/// `IsAdminOrSuperAdmin`, so no user can create or read a ticket; the only
/// route open to them is `users/contact/`, which raises an enquiry a counsellor
/// picks up. Showing a "your tickets" list would be showing something the user
/// can never actually see.
class SupportScreen extends ConsumerWidget {
  const SupportScreen({super.key});

  /// Our WhatsApp support number, as used on the website's footer.
  static const _supportPhone = '916387488141';
  static const _supportEmail = 'support@thehometuitions.in';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.slate400 : AppColors.slate500;

    return Scaffold(
      appBar: AppBar(title: const Text('Help and support')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.base,
          AppSpacing.lg,
          AppSpacing.xxxl,
        ),
        children: [
          const SectionHeader(
            'Get an answer now',
            icon: Icons.bolt_rounded,
            iconTone: Tone.warning,
          ),
          const SizedBox(height: AppSpacing.md),
          _Option(
            icon: Icons.auto_awesome_rounded,
            title: 'Ask THT Helper',
            subtitle: 'Instant answers about credits, verification and more',
            tone: Tone.accent,
            onTap: () => context.push('/genie'),
          ),
          const SizedBox(height: AppSpacing.sm),
          _Option(
            icon: Icons.chat_rounded,
            title: 'WhatsApp our team',
            subtitle: 'Usually the fastest way to reach a person',
            tone: Tone.success,
            onTap: () => launchUrl(
              Uri.parse('https://wa.me/$_supportPhone'),
              mode: LaunchMode.externalApplication,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _Option(
            icon: Icons.call_rounded,
            title: 'Call us',
            subtitle: '+91 63874 88141',
            tone: Tone.info,
            onTap: () => launchUrl(
              Uri.parse('tel:+$_supportPhone'),
              mode: LaunchMode.externalApplication,
            ),
          ),

          const SizedBox(height: AppSpacing.xl),
          const SectionHeader(
            'Send us a message',
            icon: Icons.mail_outline_rounded,
            iconTone: Tone.info,
          ),
          const SizedBox(height: AppSpacing.md),
          _Option(
            icon: Icons.edit_note_rounded,
            title: 'Write to us',
            subtitle: 'We reply on your registered number',
            tone: Tone.neutral,
            onTap: () => _EnquirySheet.show(context),
          ),
          const SizedBox(height: AppSpacing.sm),
          _Option(
            icon: Icons.alternate_email_rounded,
            title: 'Email',
            subtitle: _supportEmail,
            tone: Tone.neutral,
            onTap: () => launchUrl(
              Uri.parse('mailto:$_supportEmail'),
              mode: LaunchMode.externalApplication,
            ),
          ),

          const SizedBox(height: AppSpacing.xl),
          const NoteBox(
            tone: Tone.info,
            message: 'Messages reach our counsellors directly. We do not have '
                'a ticket tracker yet, so replies come to your phone rather '
                'than back into the app.',
          ),

          const SizedBox(height: AppSpacing.xl),
          Text(
            'Policies',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: muted,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.base,
            runSpacing: AppSpacing.sm,
            children: [
              for (final entry in const {
                'Terms': '/terms',
                'Privacy': '/privacy-policy',
                'Refunds': '/refund-policy',
              }.entries)
                TextButton(
                  onPressed: () => launchUrl(
                    Uri.parse('${ApiConfig.siteUrl}${entry.value}'),
                    mode: LaunchMode.externalApplication,
                  ),
                  child: Text(entry.key),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.tone,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Tone tone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final muted = isDark ? AppColors.slate400 : AppColors.slate500;

    return THTCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: tone.background(brightness),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, size: 20, color: tone.foreground(brightness)),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.slate50 : AppColors.slate900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12.5, height: 1.4, color: muted),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: muted),
        ],
      ),
    );
  }
}

// ── Write to us ──────────────────────────────────────────────────────────────

class _EnquirySheet extends ConsumerStatefulWidget {
  const _EnquirySheet();

  static Future<void> show(BuildContext context) => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => const _EnquirySheet(),
      );

  @override
  ConsumerState<_EnquirySheet> createState() => _EnquirySheetState();
}

class _EnquirySheetState extends ConsumerState<_EnquirySheet> {
  final _form = GlobalKey<FormState>();
  final _subject = TextEditingController();
  final _message = TextEditingController();

  bool _sending = false;
  bool _sent = false;
  String? _error;

  @override
  void dispose() {
    _subject.dispose();
    _message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: _sent ? _confirmation(isDark) : _formBody(isDark),
        ),
      ),
    );
  }

  Widget _confirmation(bool isDark) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.mark_email_read_outlined,
            size: 40,
            color: Tone.success.foreground(Theme.of(context).brightness),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Message sent',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.slate50 : AppColors.slate900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'One of our counsellors will get back to you on your registered '
            'number.',
            style: TextStyle(
              fontSize: 13.5,
              height: 1.5,
              color: isDark ? AppColors.slate400 : AppColors.slate500,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Done'),
            ),
          ),
        ],
      );

  Widget _formBody(bool isDark) => Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Write to us',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.slate50 : AppColors.slate900,
                    ),
                  ),
                ),
                IconButton(
                  onPressed:
                      _sending ? null : () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                  tooltip: 'Close',
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _subject,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'What is it about?',
                hintText: 'Payment not received',
              ),
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? 'Give it a short title' : null,
            ),
            const SizedBox(height: AppSpacing.base),
            TextFormField(
              controller: _message,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Tell us what happened',
                alignLabelWithHint: true,
              ),
              validator: (v) => (v ?? '').trim().length < 10
                  ? 'A little more detail helps us help you'
                  : null,
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.md),
              NoteBox(message: _error!),
            ],
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _sending ? null : _send,
                child: _sending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Send'),
              ),
            ),
          ],
        ),
      );

  Future<void> _send() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _sending = true;
      _error = null;
    });

    try {
      // Name and contact come off the account rather than being asked for —
      // the user is signed in and retyping them is friction.
      final user = ref.read(currentUserProvider).valueOrNull;
      final role = ref.read(authProvider).role;

      await ref.read(usersRepositoryProvider).raiseEnquiry(
            name: user?.displayName ?? 'App user',
            subject: _subject.text.trim(),
            message: _message.text.trim(),
            phone: user?.phone,
            email: user?.email,
            role: role?.name,
          );
      if (!mounted) return;
      setState(() {
        _sending = false;
        _sent = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = ApiFailure.from(e).message;
      });
    }
  }
}
