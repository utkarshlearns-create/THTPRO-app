import 'package:tht_app/core/utils/json_x.dart';

/// Who else is in the running for a lead, once this teacher has applied.
///
/// The endpoint refuses anyone who has not applied, and never sends a phone or
/// an email — this is standing, not contacts.
class CoApplicants {
  const CoApplicants({
    this.applicants = const [],
    this.totalCount = 0,
    this.hired,
    this.myRank,
  });

  final List<CoApplicant> applicants;
  final int totalCount;

  /// Set once someone has been hired — at which point the race is over.
  final CoApplicant? hired;

  /// Where this teacher sits by application order, 1-based. Null if the server
  /// could not place them.
  final int? myRank;

  CoApplicant? get me {
    for (final a in applicants) {
      if (a.isMe) return a;
    }
    return null;
  }

  /// Everyone but this teacher, so the list can be headed "others".
  List<CoApplicant> get others =>
      applicants.where((a) => !a.isMe).toList();

  factory CoApplicants.fromJson(Map<String, dynamic> json) {
    final hired = asMapOrNull(json, 'hired_tutor');
    return CoApplicants(
      applicants: asMapList(json, 'applicants')
          .map(CoApplicant.fromJson)
          .toList(),
      totalCount: asInt(json, 'total_count'),
      hired: hired == null ? null : CoApplicant.fromJson(hired),
      myRank: asIntOrNull(json, 'my_rank'),
    );
  }
}

/// One teacher on the list.
class CoApplicant {
  const CoApplicant({
    required this.tutorId,
    this.name = 'Teacher',
    this.imageUrl,
    this.experienceYears = 0,
    this.subjects = const [],
    this.locality = '',
    this.badge = 'PENDING',
    this.totalScore = 0,
    this.globalRank,
    this.cohortSize,
    this.isPremium = false,
    this.applicationRank = 0,
    this.isMe = false,
    this.isHired = false,
    this.chancePercentage,
  });

  final int tutorId;
  final String name;
  final String? imageUrl;
  final int experienceYears;
  final List<String> subjects;
  final String locality;

  /// `ELITE`, `PRO`, `RISING`, `NEEDS_IMPROVEMENT`, `PENDING`.
  final String badge;

  final double totalScore;
  final int? globalRank;
  final int? cohortSize;

  /// On a paid plan — which is what makes a teacher assignable.
  final bool isPremium;

  /// Position in application order, 1 for the first to apply.
  final int applicationRank;

  final bool isMe;
  final bool isHired;

  /// The backend's estimate of this teacher's chance on this lead.
  final double? chancePercentage;

  bool get isRated => badge.toUpperCase() != 'PENDING' && totalScore > 0;

  factory CoApplicant.fromJson(Map<String, dynamic> json) => CoApplicant(
        tutorId: asInt(json, 'tutor_id'),
        name: asString(json, 'name', fallback: 'Teacher'),
        imageUrl: asStringOrNull(json, 'profile_image'),
        experienceYears: asInt(json, 'experience_years'),
        subjects: asStringList(json, 'subjects'),
        locality: asString(json, 'locality'),
        badge: asString(json, 'rank_badge', fallback: 'PENDING'),
        totalScore: asDoubleOrNull(json, 'total_score') ?? 0,
        globalRank: asIntOrNull(json, 'global_rank'),
        cohortSize: asIntOrNull(json, 'cohort_size'),
        isPremium: asBool(json, 'is_premium'),
        applicationRank: asInt(json, 'application_rank'),
        isMe: asBool(json, 'is_me'),
        isHired: asBool(json, 'is_hired'),
        chancePercentage: asDoubleOrNull(json, 'chance_percentage'),
      );
}
