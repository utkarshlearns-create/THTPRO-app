import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tht_app/core/repositories/messages_repository.dart';
import 'package:tht_app/core/theme/app_colors.dart';
import 'package:tht_app/core/theme/app_type.dart';
import 'package:tht_app/core/ui/async_view.dart';
import 'package:tht_app/core/ui/haptics.dart';
import 'package:tht_app/core/ui/note_box.dart';
import 'package:tht_app/core/ui/tone.dart';
import 'package:tht_app/core/utils/api_error.dart';
import 'package:tht_app/features/messages/providers/messages_providers.dart';

/// One reason a chat can be reported, and the key the server knows it by.
class ReportReason {
  const ReportReason(this.key, this.label, this.icon);

  final String key;
  final String label;
  final IconData icon;

  /// Mirrors `ReportUserView.REASONS` — an unknown key is filed as OTHER
  /// rather than refused, so the two lists drifting cannot lose a report.
  static const all = <ReportReason>[
    ReportReason('SPAM', 'Spam or advertising', Icons.campaign_outlined),
    ReportReason('ABUSE', 'Abusive or offensive messages',
        Icons.sentiment_very_dissatisfied_outlined),
    ReportReason(
        'FRAUD', 'Fraud or money demand', Icons.currency_rupee_rounded),
    ReportReason('FAKE', 'Fake profile or impersonation', Icons.badge_outlined),
    ReportReason('OTHER', 'Something else', Icons.more_horiz_rounded),
  ];
}

/// Reports the other party in a thread, and optionally blocks them in the
/// same tap.
///
/// Google Play's User Generated Content policy requires an in-app way to
/// report another user wherever people exchange content. Chat is that surface
/// here, so this sheet is reachable from the thread's own menu rather than
/// buried in Help.
class ReportSheet extends ConsumerStatefulWidget {
  const ReportSheet({
    super.key,
    required this.conversationId,
    required this.otherName,
  });

  final int conversationId;
  final String otherName;

  /// Returns true once a report has actually been filed, so the caller can
  /// close the thread when the reporter also chose to block.
  static Future<bool?> show(
    BuildContext context, {
    required int conversationId,
    required String otherName,
  }) =>
      showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => ReportSheet(
          conversationId: conversationId,
          otherName: otherName,
        ),
      );

  @override
  ConsumerState<ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends ConsumerState<ReportSheet> {
  final _details = TextEditingController();

  String _reason = ReportReason.all.first.key;
  bool _alsoBlock = true;
  bool _sending = false;
  bool _sent = false;
  bool _blocked = false;
  String? _error;

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  String get _who =>
      widget.otherName.trim().isEmpty ? 'this person' : widget.otherName.trim();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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
            Icons.verified_outlined,
            size: 40,
            color: Tone.success.foreground(Theme.of(context).brightness),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Report sent',
            style: TextStyle(
              fontSize: ThtType.title,
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.slate50 : AppColors.slate900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _blocked
                ? 'Our team will look at this chat. You will not get any more '
                    'messages from $_who.'
                : 'Our team will look at this chat and get back to you on your '
                    'registered number if anything is needed.',
            style: TextStyle(
              fontSize: ThtType.bodyStrong,
              height: 1.5,
              color: isDark ? AppColors.slate400 : AppColors.slate500,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Done'),
            ),
          ),
        ],
      );

  Widget _formBody(bool isDark) {
    final muted = isDark ? AppColors.slate400 : AppColors.slate500;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Report $_who',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: ThtType.title,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.slate50 : AppColors.slate900,
                ),
              ),
            ),
            IconButton(
              onPressed: _sending ? null : () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close_rounded),
              tooltip: 'Close',
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          'Tell us what is wrong. Our team reads every report.',
          style: TextStyle(fontSize: ThtType.body, height: 1.4, color: muted),
        ),
        const SizedBox(height: AppSpacing.base),
        // Radio rows rather than chips: the reasons are full sentences and a
        // chip row wraps them into something unreadable at phone width.
        RadioGroup<String>(
          groupValue: _reason,
          onChanged: (v) {
            Haptics.select();
            setState(() => _reason = v ?? _reason);
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final r in ReportReason.all)
                RadioListTile<String>(
                  value: r.key,
                  enabled: !_sending,
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Row(
                    children: [
                      Icon(r.icon, size: 18, color: muted),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          r.label,
                          style: TextStyle(
                            fontSize: ThtType.bodyStrong,
                            color:
                                isDark ? AppColors.slate100 : AppColors.slate800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: _details,
          maxLines: 4,
          enabled: !_sending,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Anything else we should know?',
            hintText: 'Optional',
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        CheckboxListTile(
          value: _alsoBlock,
          onChanged: _sending
              ? null
              : (v) {
                  Haptics.select();
                  setState(() => _alsoBlock = v ?? false);
                },
          dense: true,
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          title: Text(
            'Also block $_who',
            style: TextStyle(
              fontSize: ThtType.bodyStrong,
              color: isDark ? AppColors.slate100 : AppColors.slate800,
            ),
          ),
          subtitle: Text(
            'You stop getting their messages right away. A report on its own '
            'does not.',
            style:
                TextStyle(fontSize: ThtType.caption, height: 1.4, color: muted),
          ),
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
                : const Text('Send report'),
          ),
        ),
      ],
    );
  }

  Future<void> _send() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _sending = true;
      _error = null;
    });

    try {
      await ref.read(messagesRepositoryProvider).report(
            widget.conversationId,
            reason: _reason,
            details: _details.text,
            alsoBlock: _alsoBlock,
          );
      if (!mounted) return;
      if (_alsoBlock) {
        ref
          ..invalidate(conversationsProvider)
          ..invalidate(unreadMessagesProvider)
          ..invalidate(blockedAccountsProvider);
      }
      setState(() {
        _sending = false;
        _sent = true;
        _blocked = _alsoBlock;
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

/// Confirms a block, then places it. Returns true if the block went through.
///
/// A dialog rather than a sheet: blocking shuts a conversation down, and the
/// consequence belongs in front of the thumb before the tap lands.
Future<bool> confirmAndBlock(
  BuildContext context,
  WidgetRef ref, {
  required int conversationId,
  required String otherName,
}) async {
  final who = otherName.trim().isEmpty ? 'this person' : otherName.trim();
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('Block $who?'),
      content: const Text(
        'They will not be able to message you, and this chat will close for '
        'both of you. You can undo this from Messages at any time.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('Block'),
        ),
      ],
    ),
  );
  if (ok != true) return false;

  try {
    await ref.read(messagesRepositoryProvider).block(conversationId);
    ref
      ..invalidate(conversationsProvider)
      ..invalidate(unreadMessagesProvider)
      ..invalidate(blockedAccountsProvider);
    if (context.mounted) context.showMessage('$who is blocked');
    return true;
  } catch (e) {
    if (context.mounted) context.showFailure(e);
    return false;
  }
}
