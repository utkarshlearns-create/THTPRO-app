import 'package:tht_app/core/utils/json_x.dart';

/// Today's teaching, from `GET /api/jobs/tutor/today-schedule/`.
class TodaySchedule {
  const TodaySchedule({
    this.date,
    this.totalActive = 0,
    this.tuitions = const [],
  });

  final DateTime? date;
  final int totalActive;
  final List<ActiveTuition> tuitions;

  /// The ones still waiting on the teacher to mark attendance today.
  List<ActiveTuition> get unmarked =>
      tuitions.where((t) => !t.markedToday).toList();

  bool get allMarked => tuitions.isNotEmpty && unmarked.isEmpty;

  factory TodaySchedule.fromJson(Map<String, dynamic> json) => TodaySchedule(
        date: asDateOrNull(json, 'date'),
        totalActive: asInt(json, 'total_active'),
        tuitions:
            asMapList(json, 'tuitions').map(ActiveTuition.fromJson).toList(),
      );
}

/// A running tuition — one hired application the teacher is currently teaching.
class ActiveTuition {
  const ActiveTuition({
    required this.applicationId,
    required this.jobId,
    this.subjects = const [],
    this.classGrade = '',
    this.board = '',
    this.locality = '',
    this.detailedAddress = '',
    this.studentName = '',
    this.additionalStudents = const [],
    this.parentName = '',
    this.parentPhone = '',
    this.paymentStatus = '',
    this.tutorPaid = false,
    this.tutorPaymentAmount,
    this.completionStatus = '',
    this.hiredAt,
    this.markedToday = false,
    this.todayStatus,
    this.todayTopic = '',
    this.todayHomework = '',
    this.sessionsPresent = 0,
    this.sessionsTotal = 0,
    this.recentLogs = const [],
  });

  final int applicationId;
  final int jobId;
  final List<String> subjects;
  final String classGrade;
  final String board;
  final String locality;
  final String detailedAddress;
  final String studentName;

  /// Siblings taught in the same slot.
  final List<Map<String, dynamic>> additionalStudents;

  final String parentName;
  final String parentPhone;
  final String paymentStatus;

  /// True once the teacher's month-end share has actually been paid out.
  final bool tutorPaid;

  final double? tutorPaymentAmount;
  final String completionStatus;
  final DateTime? hiredAt;

  /// Whether attendance for today is already recorded.
  final bool markedToday;

  /// `PRESENT` / `ABSENT` / `CANCELLED`, once marked.
  final String? todayStatus;

  final String todayTopic;
  final String todayHomework;
  final int sessionsPresent;
  final int sessionsTotal;
  final List<AttendanceLog> recentLogs;

  /// Every student in this slot, the named one first.
  List<String> get allStudents => [
        if (studentName.isNotEmpty) studentName,
        ...additionalStudents
            .map((s) => asString(s, 'name'))
            .where((n) => n.isNotEmpty),
      ];

  /// Attendance rate 0–1, or null before the first session is logged.
  double? get attendanceRate =>
      sessionsTotal == 0 ? null : sessionsPresent / sessionsTotal;

  /// `Maths · Class 10 · CBSE`
  String get summaryLine => [
        if (subjects.isNotEmpty) subjects.join(', '),
        if (classGrade.isNotEmpty) classGrade,
        if (board.isNotEmpty) board,
      ].join(' · ');

  factory ActiveTuition.fromJson(Map<String, dynamic> json) {
    final stats = asMapOrNull(json, 'attendance_stats') ?? const {};
    return ActiveTuition(
      applicationId: asInt(json, 'application_id'),
      jobId: asInt(json, 'job_id'),
      subjects: asStringList(json, 'subjects'),
      classGrade: asString(json, 'class_grade'),
      board: asString(json, 'board'),
      locality: asString(json, 'locality'),
      detailedAddress: asString(json, 'detailed_address'),
      studentName: asString(json, 'student_name'),
      additionalStudents: asMapList(json, 'additional_students'),
      parentName: asString(json, 'parent_name'),
      parentPhone: asString(json, 'parent_phone'),
      paymentStatus: asString(json, 'payment_status'),
      tutorPaid: asBool(json, 'tutor_paid'),
      tutorPaymentAmount: asDoubleOrNull(json, 'tutor_payment_amount'),
      completionStatus: asString(json, 'job_completion_status'),
      hiredAt: asDateOrNull(json, 'hired_at'),
      markedToday: asBool(json, 'today_marked'),
      todayStatus: asStringOrNull(json, 'today_status'),
      todayTopic: asString(json, 'today_topic'),
      todayHomework: asString(json, 'today_homework'),
      sessionsPresent: asInt(stats, 'present'),
      sessionsTotal: asInt(stats, 'total'),
      recentLogs:
          asMapList(json, 'recent_logs').map(AttendanceLog.fromJson).toList(),
    );
  }
}

/// One day's attendance record against a tuition.
class AttendanceLog {
  const AttendanceLog({
    this.date,
    this.status = '',
    this.topicTaught = '',
    this.homeworkGiven = '',
    this.remarks = '',
  });

  final DateTime? date;
  final String status;
  final String topicTaught;
  final String homeworkGiven;
  final String remarks;

  bool get wasPresent => status.toUpperCase() == 'PRESENT';

  factory AttendanceLog.fromJson(Map<String, dynamic> json) => AttendanceLog(
        date: asDateOrNull(json, 'date'),
        status: asString(json, 'status'),
        topicTaught: asString(json, 'topic_taught'),
        homeworkGiven: asString(json, 'homework_given'),
        remarks: asString(json, 'remarks'),
      );
}
