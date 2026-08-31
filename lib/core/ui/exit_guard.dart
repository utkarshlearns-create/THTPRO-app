import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Asks for a second back press before letting Android close the app.
///
/// Wraps a shell's home tab. Everywhere else, back pops a screen — this only
/// matters at the bottom of the stack, where the next press would otherwise
/// close the app without warning. Two seconds is the window Android apps have
/// used for this long enough that it needs no explanation.
class ExitGuard extends StatefulWidget {
  const ExitGuard({super.key, required this.child});

  final Widget child;

  @override
  State<ExitGuard> createState() => _ExitGuardState();
}

class _ExitGuardState extends State<ExitGuard> {
  DateTime? _firstPress;

  static const _window = Duration(seconds: 2);

  bool get _withinWindow {
    final first = _firstPress;
    return first != null && DateTime.now().difference(first) < _window;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Never pops itself. Leaving the app is the platform's job, and doing it
      // here would close it on the first press — the thing this exists to
      // prevent.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;

        if (_withinWindow) {
          // Second press inside the window: close the app properly rather than
          // popping to a blank route.
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
