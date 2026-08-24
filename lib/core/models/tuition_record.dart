import 'package:tht_app/core/utils/json_x.dart';

/// One tuition this teacher holds or has held.
///
/// Distinct from `ActiveTuition`, which is today's schedule with attendance
/// state attached. This is the ledger row: what was agreed, what it pays, and
/// whether the money has landed.
class TuitionRecord {
  const TuitionRecord({
    required this.applicationId,
    required this.jobId,
    this.subjects = const [],
    this.classGrade = '',
    this.board = '',
    this.locality = '',
    this.detailedAddress = '',
    this.studentName = '',
    this.parentName = '',
    this.completionStatus = '',
    this.paymentStatus = '',
    this.tutorPaid = false,
    this.tutorPaymentAmount,
    this.finalizedAmount,
    this.startDate,
    this.timeFrom = '',
    this.timeTo = '',
  });

  final int applicationId;
  final int jobId;
  final List<String> subjects;
  final String classGrade;
  final String board;
  final String locality;
  final String detailedAddress;
  final String studentName;
  final String parentName;

  /// `ONGOING`, `COMPLETED`, `ENDED`.
  final String completionStatus;

  /// `PAID`, `UNPAID`, `PARTIAL`.
  final String paymentStatus;

  /// True once the teacher's own share has actually been transferred — which
  /// is a later, separate event from the parent paying THT.
  final bool tutorPaid;

  final double? tutorPaymentAmount;

  /// The agreed monthly fee for the tuition as a whole.
  final double? finalizedAmount;

  final DateTime? startDate;
  final String timeFrom;
  final String timeTo;

  bool get isRunning => completionStatus.toUpperCase() == 'ONGOING';

  /// `4:00 PM – 5:30 PM`, or empty when no slot was fixed.
  String get slot => timeFrom.isEmpty || timeTo.isEmpty
      ? ''
      : '$timeFrom – $timeTo';

  /// `Class 10 · CBSE · Maths`
  String get summaryLine => [
        if (classGrade.isNotEmpty) classGrade,
        if (board.isNotEmpty) board,
        if (subjects.isNotEmpty) subjects.take(2).join(', '),
      ].join(' · ');

  /// What the teacher takes home. Falls back to half the agreed fee, which is
  /// the platform's split, when no explicit share has been recorded yet.
  double? get earning =>
      tutorPaymentAmount ??
      (finalizedAmount != null ? finalizedAmount! * 0.5 : null);

  factory TuitionRecord.fromJson(Map<String, dynamic> json) => TuitionRecord(
        applicationId: asInt(json, 'application_id'),
        jobId: asInt(json, 'job_id'),
        subjects: asStringList(json, 'subjects'),
        classGrade: asString(json, 'class_grade'),
        board: asString(json, 'board'),
        locality: asString(json, 'locality'),
        detailedAddress: asString(json, 'detailed_address'),
        studentName: asString(json, 'student_name'),
        parentName: asString(json, 'parent_name'),
        completionStatus: asString(json, 'job_completion_status'),
        paymentStatus: asString(json, 'payment_status'),
        tutorPaid: asBool(json, 'tutor_paid'),
        tutorPaymentAmount: asDoubleOrNull(json, 'tutor_payment_amount'),
        finalizedAmount: asDoubleOrNull(json, 'finalized_amount'),
        startDate: asDateOrNull(json, 'tuition_start_date'),
        timeFrom: asString(json, 'finalized_time_from'),
        timeTo: asString(json, 'finalized_time_to'),
      );
}
