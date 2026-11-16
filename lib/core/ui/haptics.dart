import 'package:flutter/services.dart';

/// Touch feedback, named by what a tap *means* rather than by how hard it buzzes.
///
/// Every haptic in the app goes through this file. That is the point: the whole
/// app can be retuned, or silenced for a device that does it badly, by editing
/// four lines here instead of hunting call sites.
abstract final class Haptics {
  /// A committing tap — apply, submit, post, pay. The one the user will
  /// remember, so it is the only one that gets a real thump.
  static void action() => HapticFeedback.mediumImpact();

  /// Moving between peers: a bottom-nav tab, a segmented control, a filter
  /// chip. Nothing has been committed, so this is a tick, not a thump.
  static void select() => HapticFeedback.selectionClick();

  /// A light acknowledgement for secondary and text buttons — Cancel, Skip,
  /// See all. Present, but quieter than the primary action beside it.
  static void light() => HapticFeedback.lightImpact();

  /// Something was refused: a failed submit, a blocked action, not enough
  /// credits. Deliberately the heaviest, because it is the one worth noticing.
  static void warn() => HapticFeedback.heavyImpact();
}
