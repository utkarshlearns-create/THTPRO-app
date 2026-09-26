import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tht_app/core/auth/auth_provider.dart';
import 'package:tht_app/core/notifications/push_service.dart';
import 'package:tht_app/core/theme/app_theme.dart';
import 'package:tht_app/core/theme/parent_theme.dart';
import 'package:tht_app/core/router/app_router.dart';
import 'package:tht_app/core/ui/intro_timing.dart';
import 'package:tht_app/core/ui/responsive_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Awaited so a notification that launched the app is already parked in
  // PushService.pendingRoute before the router builds and can consume it.
  // Never throws — an unconfigured Firebase leaves push off, not the app dead.
  await PushService.instance.init();
  // Settled before the first frame so the splash and the auth gate agree on how
  // long the intro is, rather than each racing the same disk read.
  await IntroTiming.resolve();
  runApp(const ProviderScope(child: THTApp()));
}

class THTApp extends ConsumerWidget {
  const THTApp({super.key});

  /// The text-scale range the layouts survive.
  ///
  /// Android and iOS both let a display-size setting go past 2×, and at that
  /// size a fee, a class label and a board name on one card stop ellipsising and
  /// start colliding — the shared components guard against long *strings*, not
  /// against every glyph doubling. Clamped rather than ignored: 1.35 is a real
  /// accessibility gain that the cards genuinely hold, and 0.9 stops a user who
  /// has shrunk their system text from reaching an 11px nav label.
  static const double _minTextScale = 0.9;
  static const double _maxTextScale = 1.35;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final isParent = ref.watch(authProvider).role == UserRole.parent;

    return MaterialApp.router(
      title: 'The Home Tuitions',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: router,
      // Parents get the blue theme, everyone else the orange one.
      //
      // This sits above the Navigator rather than around the parent shell so it
      // holds across the routes declared at the router's root — /post-requirement,
      // /packages, /tutors/:id — which a parent reaches constantly and which a
      // shell-scoped Theme would have handed back in orange.
      //
      // The clamp and the wide-screen frame live here for the same reason: one
      // placement that every route, dialog and bottom sheet passes through.
      builder: (context, child) {
        if (child == null) return const SizedBox.shrink();

        final framed = ResponsiveShell(
          child: isParent
              ? Theme(
                  data: Theme.of(context).brightness == Brightness.dark
                      ? ParentTheme.dark
                      : ParentTheme.light,
                  child: child,
                )
              : child,
        );

        return MediaQuery.withClampedTextScaling(
          minScaleFactor: _minTextScale,
          maxScaleFactor: _maxTextScale,
          child: framed,
        );
      },
    );
  }
}
