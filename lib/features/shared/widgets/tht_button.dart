import 'package:flutter/material.dart';
import 'package:tht_app/core/theme/app_colors.dart';

enum ThtButtonVariant { filled, outlined, text }

/// Primary action button with loading state, icon support, and variants.
class ThtButton extends StatelessWidget {
  const ThtButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = ThtButtonVariant.filled,
    this.isLoading = false,
    this.isExpanded = false,
    this.icon,
    this.color,
  });

  final String label;
  final VoidCallback? onPressed;
  final ThtButtonVariant variant;
  final bool isLoading;
  final bool isExpanded;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisSize: isExpanded ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: variant == ThtButtonVariant.filled
                  ? Colors.white
                  : AppColors.primaryOrange,
            ),
          ),
          const SizedBox(width: 10),
        ] else if (icon != null) ...[
          Icon(icon, size: 20),
          const SizedBox(width: 8),
        ],
        Text(label),
      ],
    );

    final effectiveOnPressed = isLoading ? null : onPressed;

    switch (variant) {
      case ThtButtonVariant.filled:
        return SizedBox(
          width: isExpanded ? double.infinity : null,
          child: ElevatedButton(
            onPressed: effectiveOnPressed,
            style: color != null
                ? ElevatedButton.styleFrom(backgroundColor: color)
                : null,
            child: child,
          ),
        );
      case ThtButtonVariant.outlined:
        return SizedBox(
          width: isExpanded ? double.infinity : null,
          child: OutlinedButton(
            onPressed: effectiveOnPressed,
            child: child,
          ),
        );
      case ThtButtonVariant.text:
        return TextButton(
          onPressed: effectiveOnPressed,
          child: child,
        );
    }
  }
}
