import 'package:tht_app/core/utils/json_x.dart';

/// A teacher's standing on the platform, from `GET /api/ranking/me/`.
///
/// The score is rescaled to 100 across whichever modules the teacher actually
/// has data for, so a new teacher is `PENDING` with no score rather than a bad
/// one — an important distinction to keep in the UI.
class TutorScore {
  const TutorScore({
    this.totalScore,
    this.badge = 'PENDING',
    this.attendancePercent,
    this.lateCount = 0,
    this.absentCount = 0,
    this.modulesPresent = 0,
    this.qualificationScore,
    this.attendanceScore,
    this.communicationScore,
    this.demoScore,
    this.monthOneReviewScore,
    this.parentRatingScore,
    this.studentPerformanceScore,
    this.cityRank,
    this.cityCohort,
    this.lastCalculatedAt,
  });

  /// Out of 100, or null when nothing has been scored yet.
  final double? totalScore;

  /// `ELITE`, `PRO`, `RISING`, `NEEDS_IMPROVEMENT`, `PENDING`.
  final String badge;

  final double? attendancePercent;
  final int lateCount;
  final int absentCount;

  /// How many of the seven scoring modules have data. Zero means the score is
  /// not meaningful yet.
  final int modulesPresent;

  // ── The seven modules the score is made of ──
  //
  // Each is null until there is data for it. That is the point of
  // [modulesPresent]: the total is rescaled across whichever modules a teacher
  // actually has, so a missing module is "not measured yet", never a zero.

  final double? qualificationScore;
  final double? attendanceScore;
  final double? communicationScore;
  final double? demoScore;
  final double? monthOneReviewScore;
  final double? parentRatingScore;
  final double? studentPerformanceScore;

  /// The modules that have been scored, in the order a teacher earns them.
  List<({String label, double? value, String hint})> get modules => [
        (
          label: 'Qualifications',
          value: qualificationScore,
          hint: 'Your degrees, B.Ed and teaching certifications',
        ),
        (
          label: 'Demo classes',
          value: demoScore,
          hint: 'How your demo lessons were rated',
        ),
        (
          label: 'Attendance',
          value: attendanceScore,
          hint: 'Turning up, and turning up on time',
        ),
        (
          label: 'Parent reviews',
          value: parentRatingScore,
          hint: 'What the families you taught said',
        ),
        (
          label: 'Communication',
          value: communicationScore,
          hint: 'How you deal with families and our team',
        ),
        (
          label: 'First month',
          value: monthOneReviewScore,
          hint: 'Your review after a month of teaching',
        ),
        (
          label: 'Student progress',
          value: studentPerformanceScore,
          hint: 'How the students you teach are doing',
        ),
      ];

  /// Position among teachers in the same city, when a snapshot exists.
  final int? cityRank;
  final int? cityCohort;

  final DateTime? lastCalculatedAt;

  /// True once there is enough data for the score to mean something.
  bool get isRated =>
      totalScore != null && modulesPresent > 0 && badge.toUpperCase() != 'PENDING';

  /// The badge in words, as a teacher would read it.
  String get badgeLabel {
    switch (badge.toUpperCase()) {
      case 'ELITE':
        return 'Elite teacher';
      case 'PRO':
        return 'Pro teacher';
      case 'RISING':
        return 'Rising teacher';
      case 'NEEDS_IMPROVEMENT':
        return 'Needs improvement';
      default:
        return 'Not rated yet';
    }
  }

  /// One line explaining where the teacher stands, or what to do about it.
  String get standing {
    if (!isRated) {
      return 'Your rating starts once you have taken a demo and taught your '
          'first month.';
    }
    if (cityRank != null && cityCohort != null && cityCohort! > 1) {
      return 'Ranked #$cityRank of $cityCohort teachers in your city.';
    }
    return 'Based on your demos, attendance and parent reviews.';
  }

  factory TutorScore.fromJson(Map<String, dynamic> json) {
    // `ranks` is a list of snapshots by scope; the city one is what a teacher
    // recognises. Anything else is left alone rather than guessed at.
    Map<String, dynamic>? city;
    final ranks = json['ranks'];
    if (ranks is List) {
      for (final entry in ranks.whereType<Map>()) {
        if (asString(entry.cast<String, dynamic>(), 'scope').toUpperCase() ==
            'CITY') {
          city = entry.cast<String, dynamic>();
          break;
        }
      }
    } else if (ranks is Map) {
      final map = ranks.cast<String, dynamic>();
      city = asMapOrNull(map, 'city');
    }

    return TutorScore(
      totalScore: asDoubleOrNull(json, 'total_score'),
      badge: asString(json, 'rank_badge', fallback: 'PENDING'),
      attendancePercent: asDoubleOrNull(json, 'attendance_percent'),
      lateCount: asInt(json, 'late_count'),
      absentCount: asInt(json, 'absent_count'),
      modulesPresent: asInt(json, 'modules_present'),
      qualificationScore: asDoubleOrNull(json, 'qualification_score'),
      attendanceScore: asDoubleOrNull(json, 'attendance_score'),
      communicationScore: asDoubleOrNull(json, 'communication_score'),
      demoScore: asDoubleOrNull(json, 'demo_score'),
      monthOneReviewScore: asDoubleOrNull(json, 'month1_review_score'),
      parentRatingScore: asDoubleOrNull(json, 'parent_rating_score'),
      studentPerformanceScore:
          asDoubleOrNull(json, 'student_performance_score'),
      cityRank: city == null ? null : asIntOrNull(city, 'rank'),
      cityCohort: city == null ? null : asIntOrNull(city, 'cohort_size'),
      lastCalculatedAt: asDateOrNull(json, 'last_calculated_at'),
    );
  }
}
