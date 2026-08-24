import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tht_app/core/models/attendance_record.dart';
import 'package:tht_app/core/repositories/jobs_repository.dart';

/// Every session this teacher has logged, newest first.
final attendanceHistoryProvider =
    FutureProvider.autoDispose<List<AttendanceRecord>>(
  (ref) => ref.watch(jobsRepositoryProvider).attendanceHistory(),
);

/// Job id → a short label for the tuition it belongs to.
///
/// Attendance rows carry only `job` as an id, so without this every record
/// would read as an anonymous date. Built from the teacher's own tuition list,
/// which names the student and the class.
final tuitionLabelsProvider =
    FutureProvider.autoDispose<Map<int, String>>((ref) async {
  final tuitions = await ref.watch(jobsRepositoryProvider).myTuitions();

  final labels = <int, String>{};
  for (final row in [...tuitions.active, ...tuitions.past]) {
    if (row.jobId == 0 || labels.containsKey(row.jobId)) continue;

    final parts = [
      if (row.studentName.trim().isNotEmpty) row.studentName.trim(),
      if (row.classGrade.trim().isNotEmpty) row.classGrade.trim(),
      if (row.subjects.isNotEmpty) row.subjects.take(2).join(', '),
    ];
    if (parts.isNotEmpty) labels[row.jobId] = parts.join(' · ');
  }
  return labels;
});
