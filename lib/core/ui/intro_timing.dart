import 'package:shared_preferences/shared_preferences.dart';

/// How long the launch intro runs, and whether this launch earns the full one.
///
/// The cinematic is a first-impression, not a toll gate. Played in full on the
/// very first open of an install and at roughly twice the tempo on every launch
/// after that, so a daily user is not made to watch a title card to reach their
/// dashboard.
abstract final class IntroTiming {
  /// The full sequence: the mark turns in, the wordmark writes itself, the rule
  /// opens and `Learn & Earn` rises.
  static const Duration full = Duration(milliseconds: 2600);

  /// The same choreography, faster. Every beat still happens — the whole
  /// sequence is expressed as fractions of one controller, so shortening the
  /// controller shortens the film rather than truncating it.
  static const Duration brief = Duration(milliseconds: 1250);

  static const String _key = 'intro_played_v1';

  static bool _playFull = false;

  /// Whether this launch gets the full-length cinematic.
  static bool get playFullIntro => _playFull;

  /// The floor the auth gate holds the splash for. Exactly the length of the
  /// sequence, so the intro always finishes instead of being cut mid-animation.
  static Duration get floor => _playFull ? full : brief;

  /// Decided in `main()` before the first frame.
  ///
  /// Resolved once, up front, so the splash widget and `AuthNotifier` read one
  /// already-settled answer rather than each racing the same disk read and
  /// disagreeing about how long the sequence is.
  static Future<void> resolve() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _playFull = !(prefs.getBool(_key) ?? false);
      // Stamped now rather than when the animation ends: a launch killed
      // half-way through the intro should not be shown the long version again
      // on every subsequent open.
      if (_playFull) await prefs.setBool(_key, true);
    } catch (_) {
      // Storage that will not open is not a reason to fail a launch. The short
      // intro is the safe default — it can never outlast a slow device's
      // patience, and the app still opens.
      _playFull = false;
    }
  }
}
