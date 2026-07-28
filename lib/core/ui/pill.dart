import 'package:flutter/material.dart';
import 'package:tht_app/core/theme/app_colors.dart';
import 'package:tht_app/core/ui/tone.dart';
import 'package:tht_app/core/utils/formatters.dart';

/// A small status chip. State should be readable without parsing a number, so
/// anything with a lifecycle — an application, a payment, an attendance mark —
/// wears one of these.
class Pill extends StatelessWidget {
  const Pill(
    this.label, {
    super.key,
    this.tone = Tone.neutral,
    this.icon,
    this.dense = false,
  });

  /// Builds a pill straight from a backend status like `NOT_SELECTED`,
  /// picking both the wording and the colour.
  factory Pill.status(String? status, {Key? key, IconData? icon, bool dense = false}) =>
      Pill(
        Fmt.status(status),
        key: key,
        tone: toneForStatus(status),
        icon: icon,
        dense: dense,
      );

  final String label;
  final Tone tone;
  final IconData? icon;

  /// Tighter padding, for use inside a dense list row.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final fg = tone.foreground(brightness);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? AppSpacing.sm : AppSpacing.md,
        vertical: dense ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: tone.background(brightness),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: tone.border(brightness)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: dense ? 12 : 14, color: fg),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: dense ? 11 : 12,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
