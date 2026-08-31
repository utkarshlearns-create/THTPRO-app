import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

/// Android's back gesture, for everything inside one bottom-navigation shell.
///
/// **This has to wrap the shell builder, not a screen inside it.** A `PopScope`
/// placed on a page within a `ShellRoute` never sees the back button at all —
/// the press is delivered to the root navigator, which does not consult the
/// nested one. An earlier version of this guard sat on the home screen inside
/// the shell and was simply dead code.
///
/// Three cases, in order:
///
/// 1. Something is stacked above — pop it, the ordinary case.
/// 2. Nothing stacked, but this is not the home tab. That happens after a `go`
///    from a root route (a job detail linking to "Track it"), which rebuilds
///    the stack and leaves the destination alone at the bottom. Going to the
///    home tab is the answer; closing the app is not.
/// 3. Nothing stacked and already home — the only place leaving is reasonable,
///    and then only on a second press inside two seconds.
class ShellBackHandler extends StatefulWidget {
  const ShellBackHandler({
    super.key,
    required this.home,
    required this.child,
  });

  /// The shell's first tab, where back retreats to.
  final String home;

  final Widget child;

  @override
  State<ShellBackHandler> createState() => _ShellBackHandlerState();
}

class _ShellBackHandlerState extends State<ShellBackHandler> {
  DateTime? _firstPress;

  static const _window = Duration(seconds: 2);

  bool get _withinWindow {
    final first = _firstPress;
    return first != null && DateTime.now().difference(first) < _window;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Never pops itself: which of the three cases applies is decided here,
      // and letting the framework pop first would close the app on the first
      // press, which is the thing this exists to prevent.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;

        final router = GoRouter.of(context);
        if (router.canPop()) {
          router.pop();
          return;
        }

        if (GoRouterState.of(context).uri.path != widget.home) {
          context.go(widget.home);
          return;
        }

        if (_withinWindow) {
          SystemNavigator.pop();
          return;
        }

        _firstPress = DateTime.now();
        final messenger = ScaffoldMessenger.of(context);
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Press back again to exit'),
            duration: _window,
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: widget.child,
    );
  }
}
