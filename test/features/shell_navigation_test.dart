import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tht_app/core/ui/shell_back_handler.dart';

/// Navigation across the shell boundary, which produced two separate bugs.
///
/// The app's shape: a job detail is a ROOT route, while the teacher's own
/// sections live inside a ShellRoute. Moving between the two is where both
/// went wrong — pushing a shell route from the root rendered a blank screen,
/// and the guard meant to catch the back button was mounted somewhere it could
/// never be reached.
void main() {
  Future<void> pressBack(WidgetTester t) async {
    await t.binding.defaultBinaryMessenger.handlePlatformMessage(
      'flutter/navigation',
      const JSONMethodCodec().encodeMethodCall(const MethodCall('popRoute')),
      (_) {},
    );
    await t.pumpAndSettle();
  }

  GoRouter build() {
    final shellKey = GlobalKey<NavigatorState>();
    return GoRouter(
      navigatorKey: GlobalKey<NavigatorState>(),
      initialLocation: '/tutor-home',
      routes: [
        GoRoute(
          path: '/jobs/:id',
          builder: (context, _) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => context.go('/tutor-applications'),
                child: const Text('Track it'),
              ),
            ),
          ),
        ),
        ShellRoute(
          navigatorKey: shellKey,
          builder: (_, __, child) => ShellBackHandler(
            home: '/tutor-home',
            child: Scaffold(body: child),
          ),
          routes: [
            for (final r in const [
              ('/tutor-home', 'HOME'),
              ('/tutor-jobs', 'JOBS'),
              ('/tutor-applications', 'APPLICATIONS'),
            ])
              GoRoute(
                path: r.$1,
                pageBuilder: (_, __) => NoTransitionPage(
                  child: Center(child: Text(r.$2)),
                ),
              ),
          ],
        ),
      ],
    );
  }

  testWidgets('Track it renders the applications instead of a blank screen',
      (t) async {
    final router = build();
    await t.pumpWidget(MaterialApp.router(routerConfig: router));
    await t.pumpAndSettle();

    router.push('/jobs/1');
    await t.pumpAndSettle();
    await t.tap(find.text('Track it'));
    await t.pumpAndSettle();

    expect(find.text('APPLICATIONS'), findsOneWidget,
        reason: 'a push across the shell boundary renders nothing at all');
  });

  testWidgets('back from a go-arrived section returns to the home tab',
      (t) async {
    final router = build();
    await t.pumpWidget(MaterialApp.router(routerConfig: router));
    await t.pumpAndSettle();

    router.push('/jobs/1');
    await t.pumpAndSettle();
    await t.tap(find.text('Track it'));
    await t.pumpAndSettle();

    // go rebuilt the stack, so there is nothing beneath this screen and the
    // press would otherwise reach the platform and close the app.
    expect(router.canPop(), isFalse);

    await pressBack(t);
    expect(find.text('HOME'), findsOneWidget);
  });

  testWidgets('back pops a pushed page rather than jumping home', (t) async {
    final router = build();
    await t.pumpWidget(MaterialApp.router(routerConfig: router));
    await t.pumpAndSettle();

    router.push('/tutor-jobs');
    await t.pumpAndSettle();
    expect(find.text('JOBS'), findsOneWidget);

    await pressBack(t);
    expect(find.text('HOME'), findsOneWidget);
  });

  testWidgets('the home tab needs two presses to leave', (t) async {
    final router = build();
    await t.pumpWidget(MaterialApp.router(routerConfig: router));
    await t.pumpAndSettle();
    expect(find.text('HOME'), findsOneWidget);

    await pressBack(t);
    expect(find.text('Press back again to exit'), findsOneWidget,
        reason: 'the first press must warn, never close the app');
    expect(find.text('HOME'), findsOneWidget);
  });
}
