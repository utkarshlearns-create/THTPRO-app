import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

const Duration _kForward = Duration(milliseconds: 260);
const Duration _kReverse = Duration(milliseconds: 210);

/// The one motion this app uses when a screen gives way to another.
///
/// A short horizontal shared axis: the arriving screen travels the last 6% of
/// the width as it fades up, the departing one fades out and drifts 3% the
/// other way. The distances are small on purpose — the job is to say "this is
/// somewhere else, and it came from over there", not to perform. 260ms in,
/// 210ms back, because returning should feel quicker than leaving.
Widget _sharedAxis(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  // Someone who has asked their phone to stop animating has asked this app too.
  if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) return child;

  final enter = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
  final leave =
      CurvedAnimation(parent: secondaryAnimation, curve: Curves.easeInCubic);

  return FadeTransition(
    opacity: enter,
    child: SlideTransition(
      position: Tween<Offset>(begin: const Offset(0.06, 0), end: Offset.zero)
          .animate(enter),
      child: FadeTransition(
        opacity: Tween<double>(begin: 1, end: 0).animate(leave),
        child: SlideTransition(
          position:
              Tween<Offset>(begin: Offset.zero, end: const Offset(-0.03, 0))
                  .animate(leave),
          child: child,
        ),
      ),
    ),
  );
}

/// The app's page-transition policy, installed on both themes.
///
/// Android and the desktop hosts get the shared axis above. iOS and macOS keep
/// Cupertino: the back-edge swipe is part of that platform's grammar, and
/// replacing it would cost more than this motion is worth.
const PageTransitionsTheme kThtPageTransitions = PageTransitionsTheme(
  builders: <TargetPlatform, PageTransitionsBuilder>{
    TargetPlatform.android: ThtPageTransitionsBuilder(),
    TargetPlatform.fuchsia: ThtPageTransitionsBuilder(),
    TargetPlatform.linux: ThtPageTransitionsBuilder(),
    TargetPlatform.windows: ThtPageTransitionsBuilder(),
    TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
    TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
  },
);

/// A drill-down reached from inside a shell — My Score, Leads, KYC.
///
/// Bottom-bar destinations must NOT use this. Moving between the five peers of
/// a navigation bar is not travel, and animating it reads as a bug; those stay
/// on [NoTransitionPage].
CustomTransitionPage<void> slidePage(Widget child) =>
    CustomTransitionPage<void>(
      child: child,
      transitionDuration: _kForward,
      reverseTransitionDuration: _kReverse,
      transitionsBuilder: _sharedAxis,
    );

/// The same motion for every route go_router builds a page for itself, so a
/// drill-down inside a shell and a full-screen push are visibly one app rather
/// than two. Installed via [ThemeData.pageTransitionsTheme].
///
/// iOS keeps Cupertino: the back-edge swipe is part of the platform's grammar
/// and replacing it would cost more than this motion is worth.
class ThtPageTransitionsBuilder extends PageTransitionsBuilder {
  const ThtPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) =>
      _sharedAxis(context, animation, secondaryAnimation, child);
}
