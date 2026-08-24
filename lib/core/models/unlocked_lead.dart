import 'package:tht_app/core/utils/json_x.dart';

/// A lead this teacher has already unlocked — the family's contact is theirs.
///
/// Worth its own list: unlocking is the moment a teacher takes on the
/// commitment to visit, and a credit is deducted if they never do. Without
/// somewhere to see what they hold, that promise is easy to forget.
class UnlockedLead {
  const UnlockedLead({
    required this.id,
    required this.jobId,
    this.studentName = '',
    this.classGrade = '',
    this.subjects = const [],
    this.locality = '',
    this.detailedAddress = '',
    this.budgetRange = '',
    this.whatsapp,
    this.jobStatus = '',
    this.unlockedAt,
  });

  /// The unlock record's id, not the job's.
  final int id;

  final int jobId;
  final String studentName;
  final String classGrade;
  final List<String> subjects;
  final String locality;
  final String detailedAddress;
  final String budgetRange;

  /// Present because the contact is already unlocked — that is the point of
  /// this list.
  final String? whatsapp;

  final String jobStatus;
  final DateTime? unlockedAt;

  /// `Class 10 · Maths, Science`
  String get summaryLine => [
        if (classGrade.isNotEmpty) classGrade,
        if (subjects.isNotEmpty) subjects.take(3).join(', '),
      ].join(' · ');

  /// The family has picked someone, so there is nothing left to chase.
  bool get isDecided => const {'TUTOR_SELECTED', 'ASSIGNED', 'CLOSED'}
      .contains(jobStatus.toUpperCase());

  /// Days since the unlock, for the nudge to actually go and visit.
  int? get daysSinceUnlock =>
      unlockedAt == null ? null : DateTime.now().difference(unlockedAt!).inDays;

  /// Unlocked a while ago and still undecided — the case where a credit is
  /// about to be lost for never visiting.
  bool get isGoingCold =>
      !isDecided && (daysSinceUnlock ?? 0) >= 3;

  factory UnlockedLead.fromJson(Map<String, dynamic> json) => UnlockedLead(
        id: asInt(json, 'id'),
        jobId: asInt(json, 'job_id'),
        studentName: asString(json, 'student_name'),
        classGrade: asString(json, 'class_grade'),
        subjects: asStringList(json, 'subjects'),
        locality: asString(json, 'locality'),
        detailedAddress: asString(json, 'detailed_address'),
        budgetRange: asString(json, 'budget_range'),
        whatsapp: asStringOrNull(json, 'whatsapp'),
        jobStatus: asString(json, 'job_status'),
        unlockedAt: asDateOrNull(json, 'unlocked_at'),
      );
}
