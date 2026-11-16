import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:tht_app/core/theme/app_colors.dart';
import 'package:tht_app/core/ui/intro_timing.dart';

/// The title card between tapping the icon and the app appearing.
///
/// The sequence assembles the real logo rather than imitating it. Every layer
/// on screen — the roof, `THE HOME TUITIONS`, `Learn & Earn` — is a slice of
/// `assets/images/logo.png`, so the launch screen is drawn in the logo's own
/// face and geometry. The previous version re-typed the name in Plus Jakarta
/// Sans, which is the app's UI face and not the logo's, and set it under a mark
/// that already read `THT` — the brand appeared twice, in two different
/// typefaces, neither of them the one on the signboard.
///
/// **The handover is the whole trick.** `flutter_native_splash` draws
/// `splash.png` centred at 256dp, and the artwork inside that file occupies
/// 0.6992 of its canvas — so the roof Android paints is exactly
/// [_markStartWidth] wide, centred on the screen. This widget's first frame
/// draws the same roof at the same width in the same place, on the same white,
/// so there is no seam to see: the animation looks like it begins from the
/// launch screen rather than replacing it.
///
/// One `AnimationController` drives everything and every beat is a *fraction*
/// of it, so the first-ever launch plays the full sequence and every launch
/// after it plays the same choreography faster — the film runs at a higher
/// tempo, it is not cut short. The controller's length and the floor
/// `AuthNotifier` holds the splash for are the same value ([IntroTiming.floor]).
///
/// The beats: the roof holds exactly as the launch screen left it, rises and
/// settles smaller, the wordmark fades up beneath it, a brand rule opens from
/// the centre, `Learn & Earn` arrives, and the lockup breathes once as the app
/// takes over.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  // ── Geometry ──
  //
  // Measured, not chosen. See the class comment: 256 * 0.6992 is the width
  // Android has already painted when this widget's first frame runs, and any
  // other value here would show as a jump.
  static const double _markStartWidth = 179;
  static const double _markSettle = 0.75;

  static const double _markAspect = 2.6074; // logo_mark.png
  static const double _wordAspect = 3.8669; // logo_wordmark.png
  static const double _tagAspect = 8.2195;  // logo_tagline.png

  static const double _wordWidth = 186;
  static const double _tagWidth = 118;
  static const double _ruleWidth = 148;

  static const double _gapMarkWord = 22;
  static const double _gapWordRule = 16;
  static const double _gapRuleTag = 14;

  static const double _markSlot = _markStartWidth / _markAspect;
  static const double _wordSlot = _wordWidth / _wordAspect;
  static const double _tagSlot = _tagWidth / _tagAspect;

  /// The lockup's height never changes — every slot is reserved at its full
  /// size from the first frame and the layers merely fade into it. A column
  /// that grew as each layer arrived would shift the roof under the viewer's
  /// eye, which is the one movement this sequence must not make.
  static const double _lockupHeight = _markSlot +
      _gapMarkWord +
      _wordSlot +
      _gapWordRule +
      1 +
      _gapRuleTag +
      _tagSlot;

  /// How far the whole lockup starts pushed down so that the roof — not the
  /// lockup — is what sits dead centre on the first frame.
  static const double _dropIn = _lockupHeight / 2 - _markSlot / 2;

  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: IntroTiming.floor,
  );

  @override
  void initState() {
    super.initState();
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  /// A window on the shared controller, in fractions of the whole sequence.
  Animation<double> _slice(
    double from,
    double to, {
    Curve curve = Curves.easeOutCubic,
  }) =>
      CurvedAnimation(
        parent: _c,
        curve: Interval(from, math.min(to, 1), curve: curve),
      );

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final suffix = isDark ? '_dark' : '';

    // 0.00-0.08 is deliberately empty: the roof holds exactly where the launch
    // screen left it before anything moves, which is what sells the handover.
    final settle = _slice(0.08, 0.44);
    final word = _slice(0.34, 0.60);
    final rule = _slice(0.54, 0.74);
    final tag = _slice(0.62, 0.84);
    final breathe = _slice(0.88, 1, curve: Curves.easeInOut);
    final hint = _slice(0.92, 1, curve: Curves.easeIn);

    return Scaffold(
      // The exact colour `flutter_native_splash` painted (#FFFFFF / #0F172A).
      // Flat, not graded: a gradient here would be the first thing to differ
      // from the frame Android has already put on screen.
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      body: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: Transform.translate(
                offset: Offset(0, _dropIn * (1 - settle.value)),
                child: Transform.scale(
                  // One slow breath out as the app takes over, so the lockup
                  // hands off rather than being cut.
                  scale: 1 + 0.025 * breathe.value,
                  child: SizedBox(
                    height: _lockupHeight,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _Slot(
                          height: _markSlot,
                          child: Transform.scale(
                            scale: 1 - (1 - _markSettle) * settle.value,
                            child: Image.asset(
                              'assets/images/logo_mark$suffix.png',
                              width: _markStartWidth,
                              fit: BoxFit.contain,
                              // Decoded once at the size it is drawn: the mark
                              // is the first thing on screen and a full 983px
                              // decode is wasted work on the critical path.
                              cacheWidth: (_markStartWidth * 3).round(),
                            ),
                          ),
                        ),
                        const SizedBox(height: _gapMarkWord),
                        _Slot(
                          height: _wordSlot,
                          child: _Rise(
                            t: word.value,
                            distance: 12,
                            child: Image.asset(
                              'assets/images/logo_wordmark$suffix.png',
                              width: _wordWidth,
                              fit: BoxFit.contain,
                              cacheWidth: (_wordWidth * 3).round(),
                            ),
                          ),
                        ),
                        const SizedBox(height: _gapWordRule),
                        _Rule(t: rule.value, width: _ruleWidth),
                        const SizedBox(height: _gapRuleTag),
                        _Slot(
                          height: _tagSlot,
                          child: _Rise(
                            t: tag.value,
                            distance: 8,
                            child: Image.asset(
                              'assets/images/logo_tagline$suffix.png',
                              width: _tagWidth,
                              fit: BoxFit.contain,
                              cacheWidth: (_tagWidth * 3).round(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Not part of the lockup. Held to the bottom and arriving last, so
            // it only ever reads as an explanation on a launch slow enough to
            // still be here after the sequence has finished.
            Positioned(
              left: 0,
              right: 0,
              bottom: 56,
              child: Opacity(
                opacity: hint.value * 0.8,
                child: Center(
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.6,
                      color: isDark ? AppColors.slate700 : AppColors.slate300,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A fixed-height box the layer is centred in, so nothing reflows as layers
/// arrive. See `_lockupHeight`.
class _Slot extends StatelessWidget {
  const _Slot({required this.height, required this.child});

  final double height;
  final Widget child;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: height,
        child: Center(child: child),
      );
}

/// Fade up: one movement, the whole layer together.
///
/// The name used to assemble a letter at a time. That reads as a typing effect
/// rather than a logo, and seventeen staggered glyphs is a long time to spend
/// on a launch screen — the wordmark is one object and arrives as one.
class _Rise extends StatelessWidget {
  const _Rise({
    required this.t,
    required this.distance,
    required this.child,
  });

  final double t;
  final double distance;
  final Widget child;

  @override
  Widget build(BuildContext context) => Opacity(
        opacity: t.clamp(0, 1),
        child: Transform.translate(
          offset: Offset(0, (1 - t) * distance),
          child: child,
        ),
      );
}

/// A hairline that opens from the centre, separating the name from the promise.
///
/// The one place the app's action colour appears on this screen. The website
/// does the same thing — a blue mark on white, with #E1702E carrying the
/// accents — so the launch screen and the site agree on what the brand looks
/// like.
class _Rule extends StatelessWidget {
  const _Rule({required this.t, required this.width});

  final double t;
  final double width;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 1,
        width: width * t,
        child: const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0x00E1702E),
                AppColors.primaryOrange,
                Color(0x00E1702E),
              ],
            ),
          ),
        ),
      );
}
