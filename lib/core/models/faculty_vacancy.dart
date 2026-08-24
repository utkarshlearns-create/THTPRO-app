import 'package:tht_app/core/utils/json_x.dart';

/// A teaching post the institute is hiring for, itself.
///
/// An institute deals with **two** kinds of job and they must never be merged:
///
///  * A **Tuition Requirement** is a `JobPost` — the THT team posts it for the
///    institute, runs the demos and the hiring, and the institute monitors it.
///    Read from `/api/jobs/my-jobs/`.
///  * A **Faculty Vacancy** is this: an `InstituteJob`, posted by the institute,
///    owned by the institute, with its own `OPEN`/`CLOSED` lifecycle and no
///    application pipeline behind it.
///
/// They share nothing but the word "job" — different models, different
/// endpoints, different owners. Their ids also collide, so treating one as the
/// other opens an unrelated record.
class FacultyVacancy {
  const FacultyVacancy({
    required this.id,
    this.title = '',
    this.subject = '',
    this.classLevel = '',
    this.requirements = '',
    this.salaryRange = '',
    this.jobType = 'FULL_TIME',
    this.status = 'OPEN',
    this.institutionName = '',
    this.startDate,
    this.createdAt,
  });

  final int id;
  final String title;
  final String subject;

  /// Free text, e.g. `Class 11-12 (JEE Main)` — not the platform's class list.
  final String classLevel;

  final String requirements;
  final String salaryRange;

  /// `FULL_TIME`, `PART_TIME`, `CONTRACT`, `GUEST_LECTURE`.
  final String jobType;

  /// `OPEN` or `CLOSED` — the whole lifecycle. Nothing like the tuition
  /// requirement's eight-state pipeline.
  final String status;

  final String institutionName;
  final DateTime? startDate;
  final DateTime? createdAt;

  bool get isOpen => status.toUpperCase() == 'OPEN';

  /// `Physics • Class 11-12`
  String get summaryLine => [
        if (subject.isNotEmpty) subject,
        if (classLevel.isNotEmpty) classLevel,
      ].join(' • ');

  String get jobTypeLabel {
    switch (jobType.toUpperCase()) {
      case 'FULL_TIME':
        return 'Full time';
      case 'PART_TIME':
        return 'Part time';
      case 'CONTRACT':
        return 'Contract';
      case 'GUEST_LECTURE':
        return 'Guest lecture';
      default:
        return jobType;
    }
  }

  /// The choices the server accepts, in the order the form offers them.
  static const jobTypes = <String, String>{
    'FULL_TIME': 'Full time',
    'PART_TIME': 'Part time',
    'CONTRACT': 'Contract',
    'GUEST_LECTURE': 'Guest lecture',
  };

  factory FacultyVacancy.fromJson(Map<String, dynamic> json) => FacultyVacancy(
        id: asInt(json, 'id'),
        title: asString(json, 'title'),
        subject: asString(json, 'subject'),
        classLevel: asString(json, 'class_level'),
        requirements: asString(json, 'requirements'),
        salaryRange: asString(json, 'salary_range'),
        jobType: asString(json, 'job_type', fallback: 'FULL_TIME'),
        status: asString(json, 'status', fallback: 'OPEN'),
        institutionName: asString(json, 'institution_name'),
        startDate: asDateOrNull(json, 'start_date'),
        createdAt: asDateOrNull(json, 'created_at'),
      );
}
