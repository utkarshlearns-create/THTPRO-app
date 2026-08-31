import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tht_app/core/theme/app_colors.dart';
import 'package:tht_app/core/ui/tht_card.dart';
import 'package:tht_app/core/ui/tone.dart';

/// What to say when a teacher has been marked not eligible to apply.
///
/// A curation state, not a ban — the teacher keeps the whole app, and this is
/// recoverable by talking to their coordinator. So it is amber throughout,
/// never red, and never worded as a suspension.
///
/// Two surfaces share this text so the inline strip and the full card can never
/// drift apart: the strip warns before a tap, the card explains after one.
class IneligibleNotice {
  const IneligibleNotice._();

  /// The admin's reason, or the fallback when none was recorded.
  ///
  /// The server sends `""` rather than null when no reason exists, so an empty
  /// string has to fall through as well.
  static String reasonOr(String? reason) {
    final trimmed = (reason ?? '').trim();
    return trimmed.isEmpty
        ? 'Please contact your THT coordinator to restore access.'
        : trimmed;
  }

  /// The amber strip shown beside a disabled Apply button.
  static Widget strip(BuildContext context, {String? reason}) {
    final brightness = Theme.of(context).brightness;
    final fg = Tone.warning.foreground(brightness);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Tone.warning.background(brightness),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: Tone.warning.border(brightness)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 17, color: fg),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'You are not eligible to apply right now',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                    color: fg,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  reasonOr(reason),
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.45,
                    color: fg.withValues(alpha: 0.95),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// The full explanation, shown when a teacher actually tries to apply.
  ///
  /// Deliberately a sheet rather than a toast: this is not a transient failure
  /// they should retry, it is a state they need to understand and act on, and
  /// a snackbar that vanishes in four seconds cannot carry that.
  static Future<void> show(BuildContext context, {String? reason}) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => _IneligibleSheet(reason: reason),
      );
}

class _IneligibleSheet extends StatelessWidget {
  const _IneligibleSheet({this.reason});

  final String? reason;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final muted = isDark ? AppColors.slate400 : AppColors.slate500;
    final fg = Tone.warning.foreground(brightness);
    final hasReason = (reason ?? '').trim().isNotEmpty;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: Tone.warning.background(brightness),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.pause_circle_outline_rounded,
                      size: 26, color: fg),
                ),
                const SizedBox(width: AppSpacing.base),
                Expanded(
                  child: Text(
                    "You're not eligible to apply",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      height: 1.3,
                      color: isDark ? AppColors.slate50 : AppColors.slate900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            Text(
              'Your account has been marked as not eligible to apply for '
              'jobs. This applies to every job on THT, not just this one.',
              style: TextStyle(
                fontSize: 14,
                height: 1.55,
                color: isDark ? AppColors.slate200 : AppColors.slate700,
              ),
            ),

            if (hasReason) ...[
              const SizedBox(height: AppSpacing.base),
              THTCard(
                background: Tone.warning.background(brightness),
                borderColor: Tone.warning.border(brightness),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reason given',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                        color: fg.withValues(alpha: 0.85),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      reason!.trim(),
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        fontWeight: FontWeight.w600,
                        color: fg,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.base),
            Text(
              'Everything else still works — you can browse jobs, keep your '
              'profile up to date and use your wallet as normal. Speak to '
              'your THT coordinator to get applying restored.',
              style: TextStyle(fontSize: 13.5, height: 1.55, color: muted),
            ),

            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.push('/support');
                },
                icon: const Icon(Icons.support_agent_rounded, size: 18),
                label: const Text('Contact your coordinator'),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
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
}
