import 'package:tht_app/core/utils/json_x.dart';

/// A teacher's application to a requirement, and everything that happened to it.
///
/// This is the teacher's view of their own pipeline: applied → demo → hired →
/// completed, with the money that follows. The parent's contact is never in this
/// payload; it comes from the unlock endpoint.
class Application {
  const Application({
    required this.id,
    required this.jobId,
    this.job,
    this.status = '',
    this.coverMessage = '',
    this.demoDate,
    this.demoStatus = '',
    this.demoRemarks = '',
    this.demoRejectionReason = '',
    this.demoCompletedAt,
    this.isConfirmed = false,
    this.parentApproved = false,
    this.paymentStatus = '',
    this.tutorPaid = false,
    this.completionStatus = '',
    this.closureReason = '',
    this.parentFeedback = '',
    this.paymentAmount,
    this.tutorPaymentAmount,
    this.finalizedAmount,
    this.tuitionStartDate,
    this.completedAt,
    this.chancePercentage,
    this.isRestricted = false,
    this.restrictionReason = '',
    this.hasUnlockedContact = false,
    this.createdAt,
  });

  final int id;
  final int jobId;

  /// A lean projection of the requirement this application is against.
  final JobSummary? job;

  /// `APPLIED`, `SHORTLISTED`, `HIRED`, `REJECTED`, `NOT_SELECTED`.
  final String status;

  final String coverMessage;
  final DateTime? demoDate;

  /// `PENDING`, `ACCEPTED`, `REJECTED`, `COMPLETED`.
  final String demoStatus;

  final String demoRemarks;
  final String demoRejectionReason;
  final DateTime? demoCompletedAt;
  final bool isConfirmed;

  /// True once the parent has submitted their review of the demo.
  final bool parentApproved;

  /// `PAID`, `UNPAID`, `PARTIAL`.
  final String paymentStatus;

  /// True once the teacher's month-end share has actually been paid out.
  final bool tutorPaid;

  /// `ONGOING`, `COMPLETED`, `ENDED`.
  final String completionStatus;

  final String closureReason;
  final String parentFeedback;

  /// What the parent paid THT.
  final double? paymentAmount;

  /// The teacher's share of it.
  final double? tutorPaymentAmount;

  /// The agreed monthly fee once the tuition was finalised.
  final double? finalizedAmount;

  final DateTime? tuitionStartDate;
  final DateTime? completedAt;

  /// The backend's estimate of how likely this application is to convert.
  final double? chancePercentage;

  final bool isRestricted;
  final String restrictionReason;
  final bool hasUnlockedContact;
  final DateTime? createdAt;

  bool get isHired => status.toUpperCase() == 'HIRED';
  bool get isAwaiting => status.toUpperCase() == 'APPLIED';
  bool get isShortlisted => status.toUpperCase() == 'SHORTLISTED';

  bool get isClosed =>
      const {'REJECTED', 'NOT_SELECTED'}.contains(status.toUpperCase());

  bool get isRunning =>
      isHired && completionStatus.toUpperCase() == 'ONGOING';

  bool get isCompleted => completionStatus.toUpperCase() == 'COMPLETED';

  /// A demo the teacher still has to take.
  bool get hasUpcomingDemo =>
      const {'PENDING', 'ACCEPTED'}.contains(demoStatus.toUpperCase()) &&
      !isCompleted;

  /// Where this application sits, as one word for a pill. Reads the demo and
  /// completion state too, so "Hired" doesn't hide a finished tuition.
  String get stageLabel {
    if (isCompleted) return 'Completed';
    if (isRunning) return 'Teaching';
    if (isHired) return 'Hired';
    if (isClosed) return status.toUpperCase() == 'REJECTED' ? 'Declined' : 'Not selected';
    if (demoStatus.toUpperCase() == 'ACCEPTED') return 'Demo booked';
    if (demoStatus.toUpperCase() == 'PENDING') return 'Demo proposed';
    if (isShortlisted) return 'Shortlisted';
    return 'Awaiting reply';
  }

  /// The status string the shared tone map should colour this by.
  String get toneKey {
    if (isCompleted) return 'COMPLETED';
    if (isRunning || isHired) return 'HIRED';
    if (isClosed) return status;
    if (demoStatus.toUpperCase() == 'ACCEPTED') return 'ACCEPTED';
    if (demoStatus.toUpperCase() == 'PENDING') return 'PENDING';
    return 'APPLIED';
  }

  /// What the teacher earns or earned here, preferring the recorded share.
  double? get earning => tutorPaymentAmount ??
      (finalizedAmount != null ? finalizedAmount! * 0.5 : null);

  factory Application.fromJson(Map<String, dynamic> json) {
    final details = asMapOrNull(json, 'job_details');
    return Application(
      id: asInt(json, 'id'),
      jobId: details != null ? asInt(details, 'id') : asInt(json, 'job'),
      job: details == null ? null : JobSummary.fromJson(details),
      status: asString(json, 'status'),
      coverMessage: asString(json, 'cover_message'),
      demoDate: asDateOrNull(json, 'demo_date'),
      demoStatus: asString(json, 'demo_status'),
      demoRemarks: asString(json, 'demo_remarks'),
      demoRejectionReason: asString(json, 'demo_rejection_reason'),
      demoCompletedAt: asDateOrNull(json, 'demo_completed_at'),
      isConfirmed: asBool(json, 'is_confirmed'),
      parentApproved: asBool(json, 'parent_approved'),
      paymentStatus: asString(json, 'payment_status'),
      tutorPaid: asBool(json, 'tutor_paid'),
      completionStatus: asString(json, 'job_completion_status'),
      closureReason: asString(json, 'closure_reason'),
      parentFeedback: asString(json, 'parent_feedback'),
      paymentAmount: asDoubleOrNull(json, 'payment_amount'),
      tutorPaymentAmount: asDoubleOrNull(json, 'tutor_payment_amount'),
      finalizedAmount: asDoubleOrNull(json, 'finalized_amount'),
      tuitionStartDate: asDateOrNull(json, 'tuition_start_date'),
      completedAt: asDateOrNull(json, 'completed_at'),
      chancePercentage: asDoubleOrNull(json, 'chance_percentage'),
      isRestricted: asBool(json, 'is_restricted'),
      restrictionReason: asString(json, 'restriction_reason'),
      hasUnlockedContact: asBool(json, 'has_unlocked_contact'),
      createdAt: asDateOrNull(json, 'created_at'),
    );
  }
}

/// The lean requirement projection embedded in an application.
class JobSummary {
  const JobSummary({
    required this.id,
    this.title = '',
    this.subjects = const [],
    this.classGrade = '',
    this.board = '',
    this.locality = '',
    this.detailedAddress = '',
    this.budgetRange = '',
    this.requirements = '',
    this.status = '',
    this.studentName = '',
    this.parentName = 'Parent',
  });

  final int id;

  /// Pre-built by the backend, e.g. `Maths/Science Tutor for Class 10`.
  final String title;

  final List<String> subjects;
  final String classGrade;
  final String board;
  final String locality;
  final String detailedAddress;
  final String budgetRange;
  final String requirements;
  final String status;
  final String studentName;
  final String parentName;

  /// `Class 10 · CBSE · Gomti Nagar`
  String get contextLine => [
        if (classGrade.isNotEmpty) classGrade,
        if (board.isNotEmpty) board,
        if (locality.isNotEmpty) locality,
      ].join(' · ');

  factory JobSummary.fromJson(Map<String, dynamic> json) => JobSummary(
        id: asInt(json, 'id'),
        title: asString(json, 'title'),
        subjects: asStringList(json, 'subjects'),
        classGrade: asString(json, 'class_grade'),
        board: asString(json, 'board'),
        locality: asString(json, 'locality'),
        detailedAddress: asString(json, 'detailed_address'),
        budgetRange: asString(json, 'budget_range'),
        requirements: asString(json, 'requirements'),
        status: asString(json, 'status'),
        studentName: asString(json, 'student_name'),
        parentName: asString(json, 'parent_name', fallback: 'Parent'),
      );
}
