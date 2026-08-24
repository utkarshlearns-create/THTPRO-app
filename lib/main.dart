import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tht_app/core/auth/auth_provider.dart';
import 'package:tht_app/core/notifications/push_service.dart';
import 'package:tht_app/core/theme/app_theme.dart';
import 'package:tht_app/core/theme/parent_theme.dart';
import 'package:tht_app/core/router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Awaited so a notification that launched the app is already parked in
  // PushService.pendingRoute before the router builds and can consume it.
  // Never throws — an unconfigured Firebase leaves push off, not the app dead.
  await PushService.instance.init();
  runApp(const ProviderScope(child: THTApp()));
}

class THTApp extends ConsumerWidget {
  const THTApp({super.key});

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
      builder: (context, child) {
        if (child == null) return const SizedBox.shrink();
        if (!isParent) return child;
        return Theme(
          data: Theme.of(context).brightness == Brightness.dark
              ? ParentTheme.dark
              : ParentTheme.light,
          child: child,
        );
      },
    );
  }
}
