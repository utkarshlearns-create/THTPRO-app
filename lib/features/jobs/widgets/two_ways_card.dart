import 'package:flutter/material.dart';
import 'package:tht_app/core/models/job.dart';
import 'package:tht_app/core/theme/app_colors.dart';
import 'package:tht_app/core/ui/tht_card.dart';
import 'package:tht_app/core/ui/tone.dart';

/// The choice a teacher is actually making on a buyable lead.
///
/// Both routes sit on the job screen already, but each one only argues its own
/// case — a teacher reading them in sequence has to hold two cards in their
/// head to work out the trade-off. This states it side by side, once, before
/// either card asks for a decision.
///
/// Only rendered when the lead is genuinely buyable. On every other job there
/// is one route, and a comparison with a single column is just noise.
///
/// Every line here is a difference the app can stand behind: what it costs
/// today, who makes the first call, and who lines up the demo. The one money
/// claim is the placement charge on the managed route, which is what the
/// backend actually does — THT collects half the first month's fee up front
/// and the family pays the teacher the other half directly at month-end.
class TwoWaysCard extends StatelessWidget {
  const TwoWaysCard({super.key, required this.job});

  final Job job;

  @override
  Widget build(BuildContext context) {
    if (!job.isBuyable) return const SizedBox.shrink();

    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final muted = isDark ? AppColors.slate400 : AppColors.slate500;

    return THTCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Two ways to get this tuition',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.slate50 : AppColors.slate900,
            ),
          ),
          const SizedBox(height: AppSpacing.base),

          // IntrinsicHeight so the divider spans the taller column and both
          // columns end level. A fixed height would clip at large text scales.
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _Column(
                    title: 'Buy the lead',
                    cost: '₹${job.leadPrice} once',
                    tone: Tone.accent,
                    // Short enough to survive a 360dp phone at 1.3x text
                    // scale in two columns. Prose belongs in the cards below.
                    //
                    // "Full fee stays yours" is the whole argument for paying,
                    // and it only means anything next to the other column
                    // saying what the free route costs later.
                    points: const [
                      'Number right away',
                      'Full fee stays yours',
                      'Few spots',
                    ],
                  ),
                ),
                VerticalDivider(
                  width: AppSpacing.lg,
                  thickness: 1,
                  color: isDark ? AppColors.darkBorder : AppColors.slate200,
                ),
                const Expanded(
                  child: _Column(
                    title: 'Apply free',
                    cost: 'No payment',
                    tone: Tone.info,
                    points: [
                      'We put you forward',
                      'We set up the demo',
                      'THT keeps half of month 1',
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.base),
          Divider(
            height: 1,
            color: isDark ? AppColors.darkBorder : AppColors.slate200,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded, size: 15, color: muted),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'The placement charge applies only when our team finalises '
                  'the placement. Buy the lead and close it yourself and '
                  'nothing is deducted. Either way, from month two the whole '
                  'fee is yours.',
                  style: TextStyle(fontSize: 12, height: 1.5, color: muted),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Column extends StatelessWidget {
  const _Column({
    required this.title,
    required this.cost,
    required this.tone,
    required this.points,
  });

  final String title;
  final String cost;
  final Tone tone;
  final List<String> points;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final muted = isDark ? AppColors.slate400 : AppColors.slate500;
    final fg = tone.foreground(brightness);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            height: 1.3,
            color: isDark ? AppColors.slate50 : AppColors.slate900,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          cost,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            height: 1.3,
            color: fg,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        for (final p in points)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: muted,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    p,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.45,
                      color: isDark ? AppColors.slate300 : AppColors.slate600,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
