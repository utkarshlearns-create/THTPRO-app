import 'package:flutter/material.dart';
import 'package:tht_app/core/theme/app_colors.dart';
import 'package:tht_app/core/ui/tht_card.dart';
import 'package:tht_app/core/ui/tone.dart';

/// A single headline number with its label — the unit a dashboard is built from.
///
/// Numbers are set in tabular figures so a row of tiles keeps its digits in
/// column even as the values change on refresh.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.tone = Tone.neutral,
    this.caption,
    this.onTap,
  });

  final String label;
  final String value;
  final IconData? icon;
  final Tone tone;

  /// A quieter line under the value, e.g. "3 awaiting demo".
  final String? caption;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final accent = tone.foreground(brightness);

    return THTCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.base),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: tone.background(brightness),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(icon, size: 16, color: accent),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              height: 1.1,
              letterSpacing: -0.5,
              fontFeatures: const [FontFeature.tabularFigures()],
              color: isDark ? AppColors.slate50 : AppColors.slate900,
            ),
          ),
          const SizedBox(height: 4),
          // Flexible so a two-line label in a tight grid cell ellipsises
          // instead of overflowing the tile — three tiles across a phone leaves
          // little vertical room once the label wraps.
          Flexible(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                height: 1.3,
                color: isDark ? AppColors.slate400 : AppColors.slate500,
              ),
            ),
          ),
          if (caption != null) ...[
            const SizedBox(height: 6),
            Text(
              caption!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: accent,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
