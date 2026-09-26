import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:tht_app/core/theme/app_colors.dart';
import 'package:tht_app/core/theme/app_theme.dart';
import 'package:tht_app/core/ui/intro_timing.dart';

/// The title card between tapping the icon and the app appearing.
///
/// One `AnimationController` drives the whole sequence and every beat is stated
/// as a *fraction* of it rather than in milliseconds. That is what lets the
/// first-ever launch run the 2.6s cinematic and every launch after it run the
/// same choreography in 1.25s — the film is played faster, not cut short. The
/// controller's length and the floor `AuthNotifier` holds the splash for are the
/// same value (`IntroTiming.floor`), so the sequence can never be torn down
/// mid-animation the way the old one was.
///
/// The beats, in order: the canvas deepens out of the native splash colour, the
/// mark swings square to the camera through a real perspective transform, its
/// bloom and reflection settle under it, the wordmark writes itself a letter at
/// a time, a brand rule opens from the centre, and `Learn & Earn` rises.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
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
    Curve curve = Curves.easeOut,
  }) =>
      CurvedAnimation(
        parent: _c,
        curve: Interval(from, math.min(to, 1), curve: curve),
      );

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final canvas = _slice(0, 0.18);
    final land = _slice(0.05, 0.46, curve: Curves.easeOutCubic);
    final pop = _slice(0.36, 0.58, curve: Curves.easeOutBack);
    final rule = _slice(0.60, 0.78, curve: Curves.easeOutCubic);
    final tag = _slice(0.68, 0.90, curve: Curves.easeOutCubic);
    final hint = _slice(0.86, 1);

    return Scaffold(
      // The frame the native splash hands over on. Painting the same colour
      // first and *then* deepening it means the handover is invisible — the
      // brand canvas grows out of the launch screen instead of replacing it.
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      body: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => Stack(
          fit: StackFit.expand,
          children: [
            _Canvas(isDark: isDark, t: canvas.value),
            SafeArea(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _Mark(isDark: isDark, land: land.value, pop: pop.value),
                    const SizedBox(height: AppSpacing.lg),
                    _Wordmark(isDark: isDark, progress: _c.value),
                    const SizedBox(height: AppSpacing.md),
                    _Rule(isDark: isDark, t: rule.value),
                    const SizedBox(height: AppSpacing.md),
                    _Tagline(isDark: isDark, t: tag.value),
                  ],
                ),
              ),
            ),

            // A progress hint, not part of the lockup — held to the bottom and
            // arriving last, so it only reads as an explanation on a launch slow
            // enough to need one.
            Positioned(
              left: 0,
              right: 0,
              bottom: AppSpacing.huge,
              child: Opacity(
                opacity: hint.value,
                child: Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: isDark ? AppColors.slate600 : AppColors.slate300,
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

/// The ground the sequence plays on.
///
/// Both stops are derived from the surface colour rather than written down, so
/// the warm bloom is the brand orange at a whisper on whichever base the theme
/// is using and there is no second palette to keep in step with the first.
class _Canvas extends StatelessWidget {
  const _Canvas({required this.isDark, required this.t});

  final bool isDark;
  final double t;

  @override
  Widget build(BuildContext context) {
    final base = isDark ? AppColors.darkSurface : Colors.white;
    final bloom =
        Color.lerp(base, AppColors.primaryOrange, isDark ? 0.17 : 0.10)!;
    final mid =
        Color.lerp(base, AppColors.primaryOrange, isDark ? 0.07 : 0.04)!;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0, -0.28),
          radius: 1.15,
          colors: [
            Color.lerp(base, bloom, t)!,
            Color.lerp(base, mid, t)!,
            base,
          ],
          stops: const [0, 0.48, 1],
        ),
      ),
      child: DecoratedBox(
        // A vignette pulls the corners down so the centre of the card is the
        // brightest thing on screen. Barely there in light, load-bearing in
        // dark, where a flat field would look like an unpainted surface.
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.28),
            radius: 1.1,
            colors: [
              Colors.transparent,
              (isDark ? AppColors.slate950 : AppColors.slate200)
                  .withValues(alpha: (isDark ? 0.55 : 0.22) * t),
            ],
            stops: const [0.55, 1],
          ),
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

/// The logo, turned in through a real perspective projection.
class _Mark extends StatelessWidget {
  const _Mark({required this.isDark, required this.land, required this.pop});

  final bool isDark;

  /// 0 → turned away and pushed back; 1 → square to the camera.
  final double land;

  /// The settle. Runs on `easeOutBack`, so it briefly passes 1 and returns.
  final double pop;

  static const double _size = 132;

  /// How far forward the mark has travelled, with the settle folded in.
  ///
  /// `pop` runs on `easeOutBack` and so briefly exceeds 1 — that overshoot is
  /// the small pop past full size before the mark comes to rest.
  static double _depth(double land, double pop) =>
      (0.72 + 0.28 * land) * (0.97 + 0.03 * pop);

  @override
  Widget build(BuildContext context) {
    // `setEntry(3, 2, …)` is the part that makes this depth rather than a scale
    // wearing depth's clothes: with it the receding edge of the mark actually
    // foreshortens as it swings round, which is what the eye reads as 3D.
    final transform = Matrix4.identity()
      ..setEntry(3, 2, 0.0014)
      ..rotateY((1 - land) * -0.92)
      ..rotateX((1 - land) * 0.26)
      ..scaleByDouble(_depth(land, pop), _depth(land, pop), 1, 1);

    // Two files, not one tinted file. The mark is a launcher foreground drawn
    // for a white plate, and its lettering is slate-900 — which is the dark
    // canvas's own colour, so on a dark phone the name vanished and the intro
    // showed a roof floating on nothing. The dark variant repaints only that
    // ink; the blue is untouched, being half the mark and readable on both.
    final logo = Image.asset(
      isDark
          ? 'assets/images/icon_foreground_dark.png'
          : 'assets/images/icon_foreground.png',
      width: _size,
      fit: BoxFit.contain,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: _size + AppSpacing.xxl,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // A true radial bloom rather than a `BoxShadow`: the mark is a
              // transparent PNG, and a box shadow behind one paints the
              // rectangle it happens to be drawn in.
              IgnorePointer(
                child: Container(
                  width: _size * 1.7,
                  height: _size * 1.7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.primaryOrange
                            .withValues(alpha: (isDark ? 0.30 : 0.20) * land),
                        AppColors.primaryOrange.withValues(alpha: 0),
                      ],
                      stops: const [0.1, 1],
                    ),
                  ),
                ),
              ),
              Opacity(
                opacity: land.clamp(0, 1),
                child: Transform(
                  alignment: Alignment.center,
                  transform: transform,
                  child: logo,
                ),
              ),
            ],
          ),
        ),

        // A mirrored, fading copy grounds the mark on the canvas. The oldest
        // trick a title card has for implying a polished surface without
        // drawing one, and it costs a second paint of an already-cached asset.
        Transform.translate(
          offset: const Offset(0, -AppSpacing.xl),
          child: SizedBox(
            height: 40,
            child: ClipRect(
              child: OverflowBox(
                alignment: Alignment.topCenter,
                maxHeight: _size,
                child: ShaderMask(
                  blendMode: BlendMode.dstIn,
                  shaderCallback: (rect) => const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.white, Colors.transparent],
                    stops: [0, 0.75],
                  ).createShader(rect),
                  child: Opacity(
                    // Cubed, so the reflection only appears once the mark has
                    // actually arrived instead of sliding in alongside it.
                    opacity: math.pow(land, 3).toDouble() *
                        (isDark ? 0.20 : 0.14),
                    child: Transform(
                      alignment: Alignment.topCenter,
                      transform: Matrix4.identity()..scaleByDouble(1, -1, 1, 1),
                      child: logo,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// `THE HOME TUITIONS`, written a letter at a time.
///
/// Each character owns its own slice of the wordmark's window, so the name
/// assembles left to right instead of appearing all at once — the difference
/// between a logo being *shown* and a logo being *set*.
class _Wordmark extends StatelessWidget {
  const _Wordmark({required this.isDark, required this.progress});

  final bool isDark;

  /// The raw controller value, because each letter needs its own window.
  final double progress;

  static const String _text = 'THE HOME TUITIONS';
  static const double _from = 0.44;
  static const double _span = 0.30;
  static const double _each = 0.13;

  @override
  Widget build(BuildContext context) {
    const step = (_span - _each) / (_text.length - 1);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < _text.length; i++)
          _Letter(
            char: _text[i],
            t: Curves.easeOutCubic.transform(
              (((progress - (_from + step * i)) / _each)).clamp(0.0, 1.0),
            ),
            isDark: isDark,
          ),
      ],
    );
  }
}

class _Letter extends StatelessWidget {
  const _Letter({required this.char, required this.t, required this.isDark});

  final String char;
  final double t;
  final bool isDark;

  @override
  Widget build(BuildContext context) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, (1 - t) * 10),
          child: Text(
            char,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: 2.4,
              height: 1.1,
              color: isDark ? AppColors.slate100 : AppColors.slate900,
            ),
          ),
        ),
      );

  // A space carries no glyph, so nothing would separate the two words if the
  // letter were allowed to collapse — the letterSpacing above is what holds it
  // open, which is why the space is rendered as a character like any other.
}

/// A hairline that opens from the centre, separating the name from the promise.
class _Rule extends StatelessWidget {
  const _Rule({required this.isDark, required this.t});

  final bool isDark;
  final double t;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 1,
        width: 148 * t,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primaryOrange.withValues(alpha: 0),
                AppColors.primaryOrange.withValues(alpha: isDark ? 0.9 : 0.75),
                AppColors.primaryOrange.withValues(alpha: 0),
              ],
            ),
          ),
        ),
      );
}

/// `Learn & Earn` — the last thing on screen and the thing worth remembering.
class _Tagline extends StatelessWidget {
  const _Tagline({required this.isDark, required this.t});

  final bool isDark;
  final double t;

  @override
  Widget build(BuildContext context) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, (1 - t) * 14),
          child: ShaderMask(
            // Painted through a gradient rather than set in a flat colour: it is
            // the one line of type on screen allowed to look expensive.
            blendMode: BlendMode.srcIn,
            shaderCallback: (rect) => const LinearGradient(
              colors: [
                AppColors.primaryOrangeDark,
                AppColors.primaryOrange,
                AppColors.primaryOrangeDark,
              ],
            ).createShader(rect),
            child: const Text(
              'Learn & Earn',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 21,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.6,
                height: 1.2,
                // Replaced by the shader; stated so the glyphs are opaque and
                // the gradient has something to paint into.
                color: Colors.white,
              ),
            ),
          ),
        ),
      );
}
