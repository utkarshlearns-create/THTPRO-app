import 'package:tht_app/core/utils/json_x.dart';

/// Whether this teacher may reveal the parent behind a lead, and on what terms.
///
/// From `GET /api/users/jobs/<id>/unlock-contact/`. Worth reading carefully
/// before writing any copy against it: **unlocking costs nothing up front**. The
/// balance is a gate — a teacher needs at least one credit to unlock at all —
/// and a credit is deducted later only if they never visit the family. It is a
/// commitment, not a purchase.
class UnlockStatus {
  const UnlockStatus({
    this.isUnlocked = false,
    this.balance = 0,
    this.unlockCount = 0,
    this.maxUnlocks = 0,
    this.limitReached = false,
    this.whatsapp,
  });

  final bool isUnlocked;

  /// The teacher's spendable credit balance.
  final double balance;

  /// How many teachers already hold this parent's contact.
  final int unlockCount;

  /// The cap, or 0 when uncapped.
  final int maxUnlocks;

  final bool limitReached;

  /// Returned once unlocked.
  final String? whatsapp;

  bool get hasCredits => balance > 0;

  /// Remaining slots, or null when there is no cap.
  int? get slotsLeft {
    if (maxUnlocks <= 0) return null;
    final left = maxUnlocks - unlockCount;
    return left < 0 ? 0 : left;
  }

  /// True when the teacher can act right now.
  bool get canUnlock => !isUnlocked && !limitReached && hasCredits;

  /// Why the unlock button is disabled, or null when it isn't.
  String? get blockedReason {
    if (isUnlocked || canUnlock) return null;
    if (limitReached) {
      return 'This lead has reached its limit of teachers who can see the '
          'parent. Try another job.';
    }
    return 'You need at least one credit to unlock a lead. Add credits to '
        'continue.';
  }

  factory UnlockStatus.fromJson(Map<String, dynamic> json) => UnlockStatus(
        isUnlocked: asBool(json, 'is_unlocked'),
        balance: asDouble(json, 'balance'),
        unlockCount: asInt(json, 'unlock_count'),
        maxUnlocks: asInt(json, 'max_unlocks'),
        limitReached: asBool(json, 'limit_reached'),
        whatsapp: asStringOrNull(json, 'whatsapp'),
      );
}
