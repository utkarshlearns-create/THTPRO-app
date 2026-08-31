import 'package:flutter/material.dart';
import 'package:tht_app/core/theme/app_colors.dart';
import 'package:tht_app/core/ui/tone.dart';

/// What a teacher is agreeing to before paying for a lead.
///
/// Deliberately not a one-line confirm. Three things here are easy to assume
/// wrongly and expensive to get wrong: the money buys a *contact*, not the
/// tuition; nobody is refunded if the family picks someone else; and from the
/// moment it is bought, the arrangement is between the teacher and the family
/// with THT out of it.
///
/// Returns true only if the box was ticked and Pay was pressed.
class LeadTermsSheet extends StatefulWidget {
  const LeadTermsSheet({super.key, required this.price});

  final int price;

  static Future<bool?> show(BuildContext context, {required int price}) =>
      showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => LeadTermsSheet(price: price),
      );

  @override
  State<LeadTermsSheet> createState() => _LeadTermsSheetState();
}

class _LeadTermsSheetState extends State<LeadTermsSheet> {
  bool _agreed = false;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final muted = isDark ? AppColors.slate400 : AppColors.slate500;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Buy this lead for ₹${widget.price}?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      height: 1.3,
                      color: isDark ? AppColors.slate50 : AppColors.slate900,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  icon: const Icon(Icons.close_rounded),
                  tooltip: 'Close',
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.base),

            const _Point(
              icon: Icons.chat_rounded,
              tone: Tone.success,
              title: 'You get their WhatsApp number',
              body: 'Straight away, and you arrange the tuition with the '
                  'family yourself.',
            ),
            const _Point(
              icon: Icons.savings_outlined,
              tone: Tone.success,
              title: 'No commission',
              body: 'Whatever fee you agree with them is yours in full. THT '
                  'takes nothing from it.',
            ),
            const _Point(
              icon: Icons.help_outline_rounded,
              tone: Tone.warning,
              title: 'It does not guarantee the tuition',
              body: 'You are buying the contact, not the job. The family may '
                  'still choose another teacher.',
            ),
            const _Point(
              icon: Icons.block_outlined,
              tone: Tone.critical,
              title: 'Non-refundable',
              body: 'This payment cannot be reversed, including if the family '
                  'does not go ahead with you.',
            ),

            const SizedBox(height: AppSpacing.sm),
            // The tick is the record of consent, so it is the thing that
            // enables Pay — never a pre-checked box.
            InkWell(
              onTap: () => setState(() => _agreed = !_agreed),
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: _agreed,
                      onChanged: (v) => setState(() => _agreed = v ?? false),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 11),
                        child: Text(
                          'I understand I will deal with the family directly, '
                          'that buying this lead does not guarantee the '
                          'tuition, and that this payment is non-refundable.',
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.5,
                            color: isDark
                                ? AppColors.slate200
                                : AppColors.slate700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.base),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed:
                    _agreed ? () => Navigator.of(context).pop(true) : null,
                child: Text('Pay ₹${widget.price}'),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Center(
              child: Text(
                'Secure payment via Razorpay',
                style: TextStyle(fontSize: 11.5, color: muted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Point extends StatelessWidget {
  const _Point({
    required this.icon,
    required this.tone,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final Tone tone;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final muted = isDark ? AppColors.slate400 : AppColors.slate500;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.base),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: tone.background(brightness),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, size: 16, color: tone.foreground(brightness)),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.slate100 : AppColors.slate900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: TextStyle(fontSize: 12.5, height: 1.45, color: muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
