import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tht_app/core/models/tuition.dart';
import 'package:tht_app/core/repositories/repository.dart';

/// Jobs, applications, attendance and notifications — all of `/api/jobs/`.
///
/// A "job" is a tuition requirement a parent or institute posts; teachers spend
/// credits to unlock the contact behind one and then apply.
class JobsRepository extends Repository {
  JobsRepository([super.dio]);

  // ── Parent ────────────────────────────────────────────────────────────────

  /// The parent's own posted requirements.
  Future<List<Map<String, dynamic>>> myJobs() => getList('/api/jobs/my-jobs/');

  Future<Map<String, dynamic>> jobDetail(int jobId) =>
      getMap('/api/jobs/$jobId/');

  /// Counts for the parent dashboard.
  Future<Map<String, dynamic>> parentStats() =>
      getMap('/api/jobs/stats/parent/');

  /// Reference data the post-a-requirement form needs: subjects, boards,
  /// classes, locations.
  Future<Map<String, dynamic>> masterData() => getMap('/api/jobs/master/');

  Future<Map<String, dynamic>> createJob(Map<String, dynamic> job) =>
      postMap('/api/jobs/create/', body: job);

  /// Teachers who have applied to one of the parent's jobs.
  Future<List<Map<String, dynamic>>> applicants(int jobId) =>
      getList('/api/jobs/$jobId/applicants/');

  /// Accepts or declines a teacher on the parent's job.
  Future<Map<String, dynamic>> applicationAction(
    int applicationId,
    Map<String, dynamic> action,
  ) =>
      postMap('/api/jobs/parent/application-action/$applicationId/', body: action);

  /// Accepts, declines or reschedules a demo the teacher proposed.
  Future<Map<String, dynamic>> demoAction(
    int applicationId,
    Map<String, dynamic> action,
  ) =>
      postMap('/api/jobs/parent/application-action/$applicationId/demo/',
          body: action);

  /// Confirms the teacher the parent wants to go ahead with.
  Future<Map<String, dynamic>> confirmTutor(int applicationId) =>
      postMap('/api/jobs/parent/application-action/$applicationId/confirm/');

  /// Closes a requirement that is no longer needed.
  Future<Map<String, dynamic>> closeJob(int jobId, {String? reason}) =>
      postMap('/api/jobs/parent/jobs/$jobId/close/',
          body: reason == null ? null : {'reason': reason});

  /// Rates a teacher after a tuition.
  Future<Map<String, dynamic>> rateTutor(Map<String, dynamic> rating) =>
      postMap('/api/jobs/parent/tutor-rating/', body: rating);

  /// The attendance the teacher has logged, as the parent sees it.
  Future<List<Map<String, dynamic>>> tutorAttendanceForParent({int? jobId}) =>
      getList('/api/jobs/parent/tutor-attendance/',
          query: jobId == null ? null : {'job_id': jobId});

  // ── Teacher ───────────────────────────────────────────────────────────────

  /// Open requirements a teacher can apply to.
  Future<Map<String, dynamic>> searchJobs({
    Map<String, dynamic>? filters,
    int page = 1,
    CancelToken? cancelToken,
  }) =>
      getMap('/api/jobs/search/',
          query: {...?filters, 'page': page}, cancelToken: cancelToken);

  Future<List<Map<String, dynamic>>> tutorApplications() =>
      getList('/api/jobs/tutor/applications/');

  /// Demos the teacher has been booked for.
  Future<List<Map<String, dynamic>>> tutorDemos() =>
      getList('/api/jobs/tutor/demos/');

  /// Today's teaching, with attendance state per tuition.
  Future<TodaySchedule> todaySchedule() async =>
      TodaySchedule.fromJson(await getMap('/api/jobs/tutor/today-schedule/'));

  /// Every running tuition, not just today's.
  Future<List<Map<String, dynamic>>> myTuitions() =>
      getList('/api/jobs/tutor/my-tuitions/');

  Future<List<Map<String, dynamic>>> attendanceHistory({int? jobId}) =>
      getList('/api/jobs/tutor/attendance/',
          query: jobId == null ? null : {'job_id': jobId});

  /// Records a session: present or absent, plus what was taught.
  Future<Map<String, dynamic>> markAttendance({
    required int jobId,
    required String status,
    String? topicTaught,
    String? homeworkGiven,
    String? remarks,
    DateTime? date,
  }) =>
      postMap('/api/jobs/tutor/mark-attendance/', body: {
        'job_id': jobId,
        'status': status,
        if (topicTaught != null) 'topic_taught': topicTaught,
        if (homeworkGiven != null) 'homework_given': homeworkGiven,
        if (remarks != null) 'remarks': remarks,
        if (date != null) 'date': date.toIso8601String().split('T').first,
      });

  /// Applies to a requirement. The contact must already be unlocked.
  Future<Map<String, dynamic>> applyToJob(int jobId,
          {Map<String, dynamic>? body}) =>
      postMap('/api/jobs/$jobId/apply/', body: body);

  /// Spends credits to reveal the parent's contact behind a lead.
  Future<Map<String, dynamic>> unlockJobContact(int jobId) =>
      postMap('/api/users/jobs/$jobId/unlock-contact/');

  /// Marks a demo as taken.
  Future<Map<String, dynamic>> completeDemo(int applicationId) =>
      postMap('/api/jobs/tutor/demos/$applicationId/complete/');

  /// Ends a tuition the teacher is no longer taking.
  Future<Map<String, dynamic>> endTuition(int applicationId,
          {String? reason}) =>
      postMap('/api/jobs/tutor/applications/$applicationId/end-tuition/',
          body: reason == null ? null : {'reason': reason});

  /// How many other teachers are in the running for a job.
  Future<Map<String, dynamic>> coApplicants(int jobId) =>
      getMap('/api/jobs/$jobId/co-applicants/');

  // ── Institute ─────────────────────────────────────────────────────────────

  /// Requirements posted by the institute.
  Future<List<Map<String, dynamic>>> institutionJobs() =>
      getList('/api/jobs/institution/jobs/');

  Future<Map<String, dynamic>> createInstitutionJob(Map<String, dynamic> job) =>
      postMap('/api/jobs/institution/jobs/', body: job);

  Future<Map<String, dynamic>> updateInstitutionJob(
          int jobId, Map<String, dynamic> changes) =>
      patchMap('/api/jobs/institution/jobs/$jobId/', body: changes);

  // ── Notifications ─────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> notifications() =>
      getList('/api/jobs/notifications/');

  /// Drives the badge on the bell icon.
  Future<int> unreadNotificationCount() async {
    final data = await getMap('/api/jobs/notifications/unread-count/');
    final v = data['count'] ?? data['unread_count'] ?? 0;
    return v is num ? v.toInt() : int.tryParse(v.toString()) ?? 0;
  }

  Future<void> markNotificationRead(int id) async {
    await postMap('/api/jobs/notifications/$id/read/');
  }

  Future<void> markAllNotificationsRead() async {
    await postMap('/api/jobs/notifications/mark-all-read/');
  }
}

final jobsRepositoryProvider = Provider<JobsRepository>((ref) => JobsRepository());
