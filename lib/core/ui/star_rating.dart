import 'package:flutter/material.dart';
import 'package:tht_app/core/theme/app_colors.dart';

/// A 1–5 star input.
///
/// Zero means "not answered yet" rather than "one star" — the demo review the
/// server requires has no default, and pre-filling one would put words in the
/// parent's mouth.
class StarRating extends StatelessWidget {
  const StarRating({
    super.key,
    required this.value,
    required this.onChanged,
    this.size = 30,
    this.enabled = true,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final double size;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final empty = isDark ? AppColors.slate700 : AppColors.slate300;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var star = 1; star <= 5; star++)
          Semantics(
            button: true,
            selected: value >= star,
            label: '$star star${star == 1 ? '' : 's'}',
            child: InkResponse(
              onTap: enabled ? () => onChanged(star) : null,
              radius: size * 0.7,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
                child: Icon(
                  value >= star ? Icons.star_rounded : Icons.star_outline_rounded,
                  size: size,
                  color: value >= star ? AppColors.amber : empty,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
