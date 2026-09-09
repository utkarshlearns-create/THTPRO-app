import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tht_app/core/theme/app_colors.dart';
import 'package:tht_app/core/ui/section_header.dart';
import 'package:tht_app/core/ui/tone.dart';

/// The shortcuts block on a home screen — rows of four dimensional chips.
///
/// Shared by the teacher and the parent because the two are the same component
/// with different destinations, and a copy would have drifted the first time
/// either was touched.
///
/// Four across at 360dp gives about 78dp a tile, which is why the label is
/// allowed two lines and each row is an [IntrinsicHeight] rather than a
/// `GridView` with an aspect ratio — a ratio fixes the height before the text
/// is measured, and a second line then overflows at larger text scales.
class ShortcutGrid extends StatelessWidget {
  const ShortcutGrid({super.key, required this.rows, this.title = 'Shortcuts'});

  /// Rows of at most four. More than four in a row is not stopped, but the
  /// labels stop fitting.
  final List<List<Shortcut>> rows;

  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title,
          icon: Icons.bolt_rounded,
          iconTone: Tone.warning,
        ),
        const SizedBox(height: AppSpacing.md),
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.base),
          _TileRow(items: rows[i]),
        ],
      ],
    );
  }
}

/// One shortcut's fixed data, so a screen's rows read as a list rather than as
/// nested markup.
class Shortcut {
  const Shortcut(this.icon, this.label, this.route, this.tint);

  final IconData icon;
  final String label;
  final String route;
  final ShortcutTint tint;
}

/// A chip's colour.
///
/// Deliberately not [Tone]. Tone's `foreground` is tuned for *text on a light
/// surface*, so in light mode it is dark and desaturated — warning there is
/// amber-700, a brown, which poured into a chip and shaded by the gradient
/// went muddy. These are the mid-tones of the same families, each verified to
/// clear 3:1 against a white icon, which is the bar for a meaningful graphic.
/// They are the same in both themes: a saturated chip reads as an island of
/// colour on white and on slate-950 alike.
enum ShortcutTint {
  orange(Color(0xFFE1702E)),
  blue(Color(0xFF2563EB)),
  green(Color(0xFF059669)),
  amber(Color(0xFFD97706)),
  red(Color(0xFFDC2626)),
  violet(Color(0xFF6D28D9)),
  slate(Color(0xFF475569));

  const ShortcutTint(this.colour);

  final Color colour;
}

class _TileRow extends StatelessWidget {
  const _TileRow({required this.items});

  final List<Shortcut> items;

  @override
  Widget build(BuildContext context) => IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) const SizedBox(width: AppSpacing.sm),
              Expanded(child: _Tile(item: items[i])),
            ],
          ],
        ),
      );
}

class _Tile extends StatelessWidget {
  const _Tile({required this.item});

  final Shortcut item;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final tint = item.tint.colour;

    return InkWell(
      onTap: () => context.push(item.route),
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Column(
          children: [
            // The depth is painted rather than imported: a top-lit gradient, a
            // coloured drop shadow and a hairline highlight. A 3D icon set
            // would carry baked-in lighting that fights the dark theme, and
            // the free ones carry no usable licence.
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color.alphaBlend(
                        Colors.white.withValues(alpha: 0.22), tint),
                    tint,
                    Color.alphaBlend(
                        Colors.black.withValues(alpha: 0.16), tint),
                  ],
                  stops: const [0, 0.55, 1],
                ),
                boxShadow: [
                  BoxShadow(
                    color: tint.withValues(alpha: isDark ? 0.34 : 0.30),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.22),
                  width: 0.8,
                ),
              ),
              child: Icon(item.icon, size: 21, color: Colors.white),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              item.label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
                height: 1.25,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.slate200 : AppColors.slate700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
