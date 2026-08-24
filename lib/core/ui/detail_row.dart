import 'package:flutter/material.dart';
import 'package:tht_app/core/theme/app_colors.dart';
import 'package:tht_app/core/ui/pill.dart';

/// One label-and-value line inside a `THTCard(padding: EdgeInsets.zero)`.
///
/// Every profile in the app — teacher, institute and now parent — renders the
/// same stack of these separated by `Divider(height: 1)`. It lives here rather
/// than being copied a third time.
class DetailRow extends StatelessWidget {
  const DetailRow({
    super.key,
    required this.label,
    required this.value,
    this.onTap,
    this.trailingIcon,
  });

  final String label;

  /// Already formatted. Callers substitute their own "Not set" text so the
  /// wording can suit the field.
  final String value;

  /// Makes the row actionable — a website that opens, an address that maps.
  final VoidCallback? onTap;

  /// Shown after the value when the row does something, so the affordance is
  /// visible rather than discovered by tapping.
  final IconData? trailingIcon;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.slate400 : AppColors.slate500;

    final row = Padding(
      padding: const EdgeInsets.all(AppSpacing.base),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: muted),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                height: 1.4,
                color: onTap == null
                    ? null
                    : Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          if (trailingIcon != null) ...[
            const SizedBox(width: 6),
            Icon(trailingIcon, size: 15, color: muted),
          ],
        ],
      ),
    );

    return onTap == null ? row : InkWell(onTap: onTap, child: row);
  }
}

/// A labelled row of chips, with an italic hint when there is nothing to show.
class DetailChips extends StatelessWidget {
  const DetailChips({
    super.key,
    required this.label,
    required this.values,
    required this.emptyHint,
  });

  final String label;
  final List<String> values;

  /// What to say when the list is empty — an absence with an explanation reads
  /// better than a blank space.
  final String emptyHint;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.base),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.slate400 : AppColors.slate500,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (values.isEmpty)
            Text(
              emptyHint,
              style: TextStyle(
                fontSize: 12.5,
                fontStyle: FontStyle.italic,
                color: isDark ? AppColors.slate500 : AppColors.slate400,
              ),
            )
          else
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [for (final v in values) Pill(v, dense: true)],
            ),
        ],
      ),
    );
  }
}
