import 'package:tht_app/core/models/job.dart';
import 'package:tht_app/core/utils/json_x.dart';

/// The parent dashboard payload from `GET /api/jobs/stats/parent/`.
class ParentStats {
  const ParentStats({
    this.activeJobs = 0,
    this.applicationsReceived = 0,
    this.hiredCount = 0,
    this.walletBalance = 0,
    this.assignedTutor,
    this.recommendedTutors = const [],
    this.activities = const [],
    this.recentJobs = const [],
  });

  /// Requirements still live: approved, awaiting approval or assigned.
  final int activeJobs;

  /// Teachers who have put themselves forward across all of them.
  final int applicationsReceived;

  final int hiredCount;
  final double walletBalance;

  /// The most recently hired teacher, if there is one.
  final HiredTutor? assignedTutor;

  final List<RecommendedTutor> recommendedTutors;
  final List<ActivityItem> activities;
  final List<Job> recentJobs;

  bool get hasPostedAnything => activeJobs > 0 || recentJobs.isNotEmpty;

  factory ParentStats.fromJson(Map<String, dynamic> json) {
    final stats = asMapOrNull(json, 'stats') ?? const <String, dynamic>{};
    final tutor = asMapOrNull(json, 'assigned_tutor');

    return ParentStats(
      activeJobs: asInt(stats, 'active_jobs'),
      applicationsReceived: asInt(stats, 'applications_received'),
      hiredCount: asInt(stats, 'hired_count'),
      walletBalance: asDouble(stats, 'wallet_balance'),
      assignedTutor: tutor == null ? null : HiredTutor.fromJson(tutor),
      recommendedTutors: asMapList(json, 'recommended_tutors')
          .map(RecommendedTutor.fromJson)
          .toList(),
      activities:
          asMapList(json, 'recent_activities').map(ActivityItem.fromJson).toList(),
      recentJobs: asMapList(json, 'recent_jobs').map(Job.fromJson).toList(),
    );
  }
}

/// The teacher currently teaching this parent's child.
class HiredTutor {
  const HiredTutor({this.name = '', this.subject = '', this.imageUrl});

  final String name;
  final String subject;
  final String? imageUrl;

  factory HiredTutor.fromJson(Map<String, dynamic> json) => HiredTutor(
        name: asString(json, 'name'),
        subject: asString(json, 'subject'),
        imageUrl: asStringOrNull(json, 'image'),
      );
}

/// A suggested teacher, ranked by locality then experience.
///
/// The API also returns a `rating` field, but it is hardcoded to 4.8 for every
/// row in `_get_recommended_tutors`, so it is deliberately not read here — a
/// made-up rating on a recommendation is worse than no rating at all. Real
/// ratings come from the tutor detail endpoint as `avg_rating`.
class RecommendedTutor {
  const RecommendedTutor({
    required this.id,
    this.name = '',
    this.subjects = const [],
    this.locality = '',
    this.experienceYears = 0,
    this.imageUrl,
  });

  final int id;
  final String name;
  final List<String> subjects;
  final String locality;
  final int experienceYears;
  final String? imageUrl;

  factory RecommendedTutor.fromJson(Map<String, dynamic> json) =>
      RecommendedTutor(
        id: asInt(json, 'id'),
        name: asString(json, 'name'),
        subjects: asStringList(json, 'subjects'),
        locality: asString(json, 'locality'),
        experienceYears: asInt(json, 'experience'),
        imageUrl: asStringOrNull(json, 'image'),
      );
}

/// One entry in the parent's activity feed.
class ActivityItem {
  const ActivityItem({
    this.type = 'info',
    this.title = '',
    this.description = '',
    this.at,
  });

  /// `success`, `info`, `warning` — drives the tone, not the wording.
  final String type;

  final String title;
  final String description;
  final DateTime? at;

  factory ActivityItem.fromJson(Map<String, dynamic> json) => ActivityItem(
        type: asString(json, 'type', fallback: 'info'),
        title: asString(json, 'title'),
        description: asString(json, 'description'),
        at: asDateOrNull(json, 'timestamp'),
      );
}
