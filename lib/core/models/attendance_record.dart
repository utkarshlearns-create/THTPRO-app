import 'package:tht_app/core/utils/json_x.dart';

/// One session a teacher logged against a tuition.
///
/// The serializer sends `job` as a bare id, so nothing here names the student —
/// the screen pairs the record with the teacher's tuition list to label it.
class AttendanceRecord {
  const AttendanceRecord({
    required this.id,
    required this.jobId,
    this.date,
    this.status = '',
    this.remarks = '',
    this.topicTaught = '',
    this.homeworkGiven = '',
    this.minutesLate = 0,
  });

  final int id;
  final int jobId;
  final DateTime? date;

  /// `PRESENT`, `LATE`, `ABSENT`, `RESCHEDULED`.
  final String status;

  final String remarks;
  final String topicTaught;
  final String homeworkGiven;
  final int minutesLate;

  bool get isPresent => status.toUpperCase() == 'PRESENT';
  bool get isAbsent => status.toUpperCase() == 'ABSENT';

  /// A session that happened, however late. Absences and reschedules did not.
  bool get counted =>
      const {'PRESENT', 'LATE'}.contains(status.toUpperCase());

  /// Whether the teacher wrote up what they covered.
  bool get hasLesson =>
      topicTaught.trim().isNotEmpty || homeworkGiven.trim().isNotEmpty;

  String get statusLabel {
    switch (status.toUpperCase()) {
      case 'PRESENT':
        return 'Present';
      case 'LATE':
        return minutesLate > 0 ? 'Late by $minutesLate min' : 'Late';
      case 'ABSENT':
        return 'Absent';
      case 'RESCHEDULED':
        return 'Rescheduled';
      default:
        return status;
    }
  }

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) =>
      AttendanceRecord(
        id: asInt(json, 'id'),
        jobId: asInt(json, 'job'),
        date: asDateOrNull(json, 'date'),
        status: asString(json, 'status'),
        remarks: asString(json, 'remarks'),
        topicTaught: asString(json, 'topic_taught'),
        homeworkGiven: asString(json, 'homework_given'),
        minutesLate: asInt(json, 'minutes_late'),
      );
}
