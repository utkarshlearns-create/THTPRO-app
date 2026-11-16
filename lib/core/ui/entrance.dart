import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// How long one item takes to arrive.
///
/// Deliberately shorter than the 260ms page transition: the screen has already
/// travelled by the time the list draws, and a list that keeps moving after the
/// page has settled reads as lag rather than as polish.
const Duration kEntranceDuration = Duration(milliseconds: 240);

/// The gap between one item starting and the next.
const Duration kEntranceStagger = Duration(milliseconds: 40);

/// How many items are allowed to wait their turn.
///
/// Past this the stagger stops accumulating, so the eighth card and the
/// eightieth both start at 320ms. Without a cap a long list would still be
/// assembling itself well after the reader had started scrolling.
const int kEntranceMaxStagger = 8;

/// How long the item at [index] waits before it begins.
///
/// A rule rather than an expression buried in a State, because the cap is the
/// interesting half and `test/core/entrance_test.dart` has to be able to read
/// it: beyond [kEntranceMaxStagger] the wait stops growing, so the ninth card
/// and the nine-hundredth start together.
Duration entranceDelayFor(int index) =>
    kEntranceStagger * index.clamp(0, kEntranceMaxStagger);

/// How far a card travels on its way in.
const double kEntranceRise = 12;

/// The window, measured from the first item's arrival, in which an item still
/// counts as part of the list's first draw.
///
/// Items that mount later were scrolled to, not arrived at, and must appear
/// instantly — fading in whatever the thumb drags into view is the single
/// thing that makes a staggered list feel broken.
const Duration _kFirstDrawWindow = Duration(milliseconds: 400);

/// One gate per list, remembering what has already arrived.
///
/// Held on the enclosing [ScrollableState] through an [Expando], so the gate
/// lives exactly as long as the list does and is collected with it. A screen
/// left and returned to builds a new [ScrollableState] and so earns a fresh
/// arrival, which is right — that is a new visit, not a scroll.
class _Gate {
  _Gate(this._openedAt);

  /// Frame time, not wall-clock time.
  ///
  /// The decision is about animation, so it belongs on the clock animation
  /// runs on: a paused or backgrounded app does not age its lists, and a
  /// widget test that pumps 400ms genuinely sees the window close.
  final Duration _openedAt;
  final Set<int> _arrived = <int>{};

  /// Whether the item at [index] should play its entrance.
  ///
  /// Both halves matter. The set stops an item replaying when it is scrolled
  /// back into view; the window stops item 150 of a long list animating when
  /// the reader reaches it ten seconds later.
  bool admit(int index, Duration now) {
    if (!_arrived.add(index)) return false;
    return now - _openedAt < _kFirstDrawWindow;
  }
}

final Expando<_Gate> _gates = Expando<_Gate>('tht entrance gates');

/// Fades and lifts a list item into place on the list's first draw.
///
/// Lists used to appear fully formed between one frame and the next, which is
/// the cheapest-looking thing an app does: the work of fetching is invisible,
/// so the content seems to have been there all along and the screen seems not
/// to have done anything. A short, staggered arrival says the list was built
/// for this reader, just now, and gives the eye an order to read it in.
///
/// Only the first screenful animates. See [_Gate] for why that is the whole
/// trick, and `test/core/entrance_test.dart` for the proof that it holds.
class ThtEntrance extends StatefulWidget {
  const ThtEntrance({super.key, required this.index, required this.child});

  /// The item's position in the list. Drives its place in the stagger.
  final int index;

  final Widget child;

  @override
  State<ThtEntrance> createState() => _ThtEntranceState();
}

class _ThtEntranceState extends State<ThtEntrance>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  Animation<double>? _curve;
  bool _decided = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Here rather than in initState: deciding needs the enclosing Scrollable,
    // and an inherited lookup is not allowed before dependencies are ready.
    if (_decided) return;
    _decided = true;

    // Someone who has asked their phone to stop moving things has asked this
    // to stop too. The same check guards the page transitions.
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) return;

    final now = SchedulerBinding.instance.currentFrameTimeStamp;
    final scrollable = Scrollable.maybeOf(context);
    final gate = scrollable == null
        // No list above us — a card standing on its own still earns the one
        // arrival its own lifetime allows.
        ? _Gate(now)
        : (_gates[scrollable] ??= _Gate(now));
    if (!gate.admit(widget.index, now)) return;

    // The delay is expressed inside the controller instead of through a timer,
    // so there is nothing left pending if this item is disposed mid-arrival —
    // and nothing for a widget test to have to drain.
    final delay = entranceDelayFor(widget.index);
    final total = delay + kEntranceDuration;
    final controller = AnimationController(vsync: this, duration: total);
    _controller = controller;
    _curve = CurvedAnimation(
      parent: controller,
      curve: Interval(
        delay.inMicroseconds / total.inMicroseconds,
        1,
        curve: Curves.easeOutCubic,
      ),
    );
    controller.forward();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curve = _curve;
    // Not animating is the common case once a list is scrolled: return the
    // child untouched rather than wrapping every row in dormant machinery.
    if (curve == null) return widget.child;

    return AnimatedBuilder(
      animation: curve,
      builder: (context, child) => Opacity(
        opacity: curve.value,
        child: Transform.translate(
          offset: Offset(0, kEntranceRise * (1 - curve.value)),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}
