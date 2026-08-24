import 'package:flutter/material.dart';
import 'package:tht_app/core/theme/app_colors.dart';
import 'package:tht_app/core/ui/tone.dart';

/// A tinted panel carrying one short message — an error under a form, a
/// confirmation after a request, a caveat beside an action.
///
/// Colour comes from [Tone] rather than a literal, so the same widget reads
/// correctly in dark mode and under the parent's blue theme.
class NoteBox extends StatelessWidget {
  const NoteBox({
    super.key,
    required this.message,
    this.tone = Tone.critical,
    this.icon,
    this.title,
  });

  final String message;
  final Tone tone;

  /// Defaults to an icon that matches [tone].
  final IconData? icon;

  /// Optional bolder line above [message].
  final String? title;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final fg = tone.foreground(brightness);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: tone.background(brightness),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: tone.border(brightness)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon ?? _defaultIcon, size: 17, color: fg),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null) ...[
                  Text(
                    title!,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                      color: fg,
                    ),
                  ),
                  const SizedBox(height: 3),
                ],
                Text(
                  message,
                  style: TextStyle(fontSize: 12.5, height: 1.45, color: fg),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData get _defaultIcon {
    switch (tone) {
      case Tone.success:
        return Icons.check_circle_outline_rounded;
      case Tone.warning:
        return Icons.warning_amber_rounded;
      case Tone.critical:
        return Icons.error_outline_rounded;
      case Tone.info:
      case Tone.accent:
      case Tone.neutral:
        return Icons.info_outline_rounded;
    }
  }
}
