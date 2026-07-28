import 'package:flutter/material.dart';
import 'package:tht_app/core/theme/app_colors.dart';

/// The surface every block of content sits on.
///
/// One card, used everywhere, so a lead on the teacher dashboard and a
/// transaction in the wallet share the same edge, radius and elevation.
class THTCard extends StatelessWidget {
  const THTCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.base),
    this.onTap,
    this.borderColor,
    this.background,
    this.radius = AppRadius.lg,
    this.elevated = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  /// When set, the whole card becomes tappable with a proper ripple.
  final VoidCallback? onTap;

  /// Overrides the hairline — used to tint a card by status.
  final Color? borderColor;

  final Color? background;
  final double radius;

  /// Lifts the card off the page. Reserve it for one hero card per screen.
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shape = BorderRadius.circular(radius);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: background ?? (isDark ? AppColors.darkCard : Colors.white),
        borderRadius: shape,
        border: Border.all(
          color: borderColor ?? (isDark ? AppColors.darkBorder : AppColors.slate200),
        ),
        boxShadow: elevated
            ? [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.35)
                      : AppColors.slate900.withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        type: MaterialType.transparency,
        borderRadius: shape,
        child: InkWell(
          onTap: onTap,
          borderRadius: shape,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
