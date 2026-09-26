import 'package:flutter/material.dart';
import 'package:tht_app/core/theme/app_colors.dart';

/// Keeps the app readable on a screen it was not drawn for.
///
/// Every layout in this app is a phone layout: one column, full-bleed cards, a
/// bottom bar. On a tablet or a phone turned sideways that column simply
/// stretched, so a 700px-wide card held one line of 14px text and the bottom bar
/// spread its five destinations to the far corners.
///
/// Rather than rewrite forty screens as two-pane layouts, the phone layout is
/// given the width it was designed for and centred, with the surrounding space
/// painted and hairlined so it reads as a deliberate frame rather than a window
/// that failed to fill. This is the behaviour of most consumer apps on a tablet,
/// and it is honest: a wide screen does not, by itself, mean there is more to
/// show.
///
/// Placed in `MaterialApp.builder`, so it wraps the Navigator and therefore
/// every route, dialog and bottom sheet — a per-screen wrapper would have missed
/// the ones reached from the router's root.
class ResponsiveShell extends StatelessWidget {
  const ResponsiveShell({required this.child, super.key});

  final Widget child;

  /// The width the phone layouts were designed against, with a little room.
  /// Wider than this and line lengths start to hurt rather than help.
  static const double maxContentWidth = 560;

  /// Below this the screen *is* the content. Chosen above the widest phone in
  /// portrait and below the narrowest tablet, which also catches a phone in
  /// landscape — the case where the stretch was worst.
  static const double _threshold = 680;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width <= _threshold) return child;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ColoredBox(
      color: isDark ? AppColors.slate950 : AppColors.slate100,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: maxContentWidth),
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.symmetric(
                vertical: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.slate200,
                ),
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
