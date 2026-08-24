import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tht_app/core/models/app_notification.dart';
import 'package:tht_app/core/models/application.dart';
import 'package:tht_app/core/models/attendance_record.dart';
import 'package:tht_app/core/models/faculty_vacancy.dart';
import 'package:tht_app/core/models/co_applicants.dart';
import 'package:tht_app/core/models/job.dart';
import 'package:tht_app/core/models/paginated.dart';
import 'package:tht_app/core/models/parent_stats.dart';
import 'package:tht_app/core/models/tuition.dart';
import 'package:tht_app/core/models/tuition_record.dart';
import 'package:tht_app/core/models/unlock_status.dart';
import 'package:tht_app/core/repositories/repository.dart';

/// Jobs, applications, attendance and notifications — all of `/api/jobs/`.
///
/// A "job" is a tuition requirement a parent or institute posts; teachers spend
/// credits to unlock the contact behind one and then apply.
class JobsRepository extends Repository {
  JobsRepository([super.dio]);

  // ── Parent ────────────────────────────────────────────────────────────────

  /// The parent's own posted requirements, newest first.
  Future<List<Job>> myJobs() => _ownedJobs();

  /// Requirements the signed-in account posted or is the client on.
  ///
  /// `/api/jobs/my-jobs/` is owner-scoped server-side to
  /// `posted_by=me OR parent=me` and is unpaginated, so it is the complete
  /// list for whoever asks — a parent or an institute alike.
  Future<List<Job>> _ownedJobs() async {
    final rows = await getList('/api/jobs/my-jobs/');
    return rows.map(Job.fromJson).toList()
      ..sort((a, b) {
        final at = a.postedAt, bt = b.postedAt;
        if (at == null && bt == null) return b.id.compareTo(a.id);
        if (at == null) return 1;
        if (bt == null) return -1;
        return bt.compareTo(at);
      });
  }

  /// The parent dashboard: counts, activity feed and recommendations.
  Future<ParentStats> parentStats() async =>
      ParentStats.fromJson(await getMap('/api/jobs/stats/parent/'));

  /// Reference data the post-a-requirement form needs: subjects, boards,
  /// classes, locations.
  Future<Map<String, dynamic>> masterData() => getMap('/api/jobs/master/');

  Future<Map<String, dynamic>> createJob(Map<String, dynamic> job) =>
      postMap('/api/jobs/create/', body: job);

  /// Teachers who have put themselves forward for one of the parent's jobs.
  Future<List<Application>> applicants(int jobId) async =>
      (await getList('/api/jobs/$jobId/applicants/'))
          .map(Application.fromJson)
          .toList();

  /// What a parent can do to a teacher who applied.
  ///
  /// `ACCEPT_DEMO` shortlists them and asks our team to schedule the demo — the
  /// parent does not pick the date. `ACCEPT` hires outright, `REJECT` declines.
  /// Every one of these is **PARENT-only** server-side, so an institute reading
  /// the same applicant list must not be offered them.
  Future<Map<String, dynamic>> applicationAction(
    int applicationId,
    String action,
  ) =>
      // PATCH, not POST: ParentApplicationActionView only defines `patch`, so
      // posting here answered 405 rather than doing anything.
      patchMap('/api/jobs/parent/application-action/$applicationId/',
          body: {'action': action});

  /// Accepts or declines a demo our team has scheduled. `ACCEPT` or `REJECT`.
  ///
  /// `REJECT` is the change-teacher path: it reopens the requirement and raises
  /// a reassignment request, so [remarks] is what our team acts on.
  Future<Map<String, dynamic>> demoAction(
    int applicationId,
    String action, {
    String? remarks,
  }) =>
      postMap('/api/jobs/parent/application-action/$applicationId/demo/',
          body: {
            'action': action,
            if (remarks != null && remarks.isNotEmpty) 'remarks': remarks,
          });

  /// Approves the teacher after their demo.
  ///
  /// [review] is required, not optional decoration: the server rejects the
  /// request unless `teaching_skill`, `subject_knowledge` and `confidence` are
  /// all present and between 1 and 5. It also refuses until the demo is
  /// `COMPLETED`, and approving records the review rather than hiring — a
  /// counsellor still finalises the fee and schedule.
  Future<Map<String, dynamic>> confirmTutor(
    int applicationId, {
    required Map<String, dynamic> review,
  }) =>
      postMap('/api/jobs/parent/application-action/$applicationId/confirm/',
          body: review);

  /// Closes a requirement that is no longer needed.
  ///
  /// PATCH, not POST — `ParentCloseJobView` defines only `patch`. It takes no
  /// body: the view records nothing but the new status, so there is no reason
  /// field to send and none is asked for.
  Future<Map<String, dynamic>> closeJob(int jobId) =>
      patchMap('/api/jobs/parent/jobs/$jobId/close/');

  /// Rates a teacher the parent has worked with.
  ///
  /// [tutorProfileId] is the **TutorProfile** id — what `tutor_details.id`
  /// carries on an applicant, not the teacher's user id. One rating per
  /// (teacher, parent, requirement); posting a second is a uniqueness error.
  Future<Map<String, dynamic>> rateTutor({
    required int tutorProfileId,
    required int jobId,
    required int rating,
    String review = '',
  }) =>
      postMap('/api/jobs/parent/tutor-rating/', body: {
        'tutor': tutorProfileId,
        'job': jobId,
        'rating': rating,
        'review': review,
      });

  /// Asks our team to replace the teacher on a running tuition.
  ///
  /// PARENT-only, and only while the job is `ASSIGNED` or `TUTOR_SELECTED`.
  /// [reason] is required — the server rejects a blank one — and only one
  /// request may be pending at a time.
  Future<Map<String, dynamic>> requestReassignment(
    int jobId, {
    required String reason,
  }) =>
      postMap('/api/jobs/$jobId/request-reassignment/',
          body: {'reason': reason});

  /// Why the server rates this teacher's chances on a lead, pillar by pillar.
  ///
  /// A teacher may ask only about themselves; staff may ask about anyone.
  Future<Map<String, dynamic>> chanceDetail(int jobId, int tutorProfileId) =>
      getMap('/api/jobs/$jobId/applicants/$tutorProfileId/chance-detail/');

  /// Attendance for one of the parent's requirements, newest first.
  ///
  /// Two books exist for the same sessions and they are not the same thing:
  ///
  ///  * [fromTutor] false — what **this parent** marked.
  ///  * [fromTutor] true  — what the **teacher** logged, scoped server-side to
  ///    jobs this parent owns.
  ///
  /// The teacher's view needs the `?source=tutor` parameter added alongside
  /// this change; against an older server it is ignored and the parent's own
  /// record comes back, which reads as an empty teacher log rather than an
  /// error.
  Future<List<AttendanceRecord>> parentAttendance({
    int? jobId,
    bool fromTutor = false,
  }) async {
    final rows = await getList(
      '/api/jobs/parent/tutor-attendance/',
      query: {
        if (fromTutor) 'source': 'tutor',
        if (jobId != null) 'job': jobId,
      },
    );
    return rows.map(AttendanceRecord.fromJson).toList()
      ..sort((a, b) {
        final at = a.date, bt = b.date;
        if (at == null && bt == null) return b.id.compareTo(a.id);
        if (at == null) return 1;
        if (bt == null) return -1;
        return bt.compareTo(at);
      });
  }

  /// Records whether the teacher turned up, from the parent's side.
  ///
  /// [tutorProfileId] is the TutorProfile id — `tutor_details.id` on an
  /// applicant. One row per (teacher, requirement, date); marking the same day
  /// twice is a uniqueness error rather than an update.
  Future<Map<String, dynamic>> markTutorAttendance({
    required int tutorProfileId,
    required int jobId,
    required DateTime date,
    required String status,
  }) =>
      postMap('/api/jobs/parent/tutor-attendance/', body: {
        'tutor': tutorProfileId,
        'job': jobId,
        'date': date.toIso8601String().split('T').first,
        'status': status,
      });

  // ── Teacher ───────────────────────────────────────────────────────────────

  /// Open requirements a teacher can apply to.
  Future<Paginated<Job>> searchJobs({
    Map<String, dynamic>? filters,
    int page = 1,
    CancelToken? cancelToken,
  }) =>
      guard(() async {
        final res = await dio.get(
          '/api/jobs/search/',
          queryParameters: {...?filters, 'page': page},
          cancelToken: cancelToken,
        );
        return Paginated.fromJson(res.data, Job.fromJson, page: page);
      });

  /// One requirement in full.
  Future<Job> job(int jobId) async => Job.fromJson(await getMap('/api/jobs/$jobId/'));

  /// Every application this teacher has made, newest first.
  ///
  /// The payload is `{'applications': [...], 'stats': {...}}`, not a bare list.
  Future<List<Application>> tutorApplications() async {
    final rows =
        await getList('/api/jobs/tutor/applications/', key: 'applications');
    final apps = rows.map(Application.fromJson).toList()
      ..sort((a, b) {
        final at = a.createdAt, bt = b.createdAt;
        if (at == null && bt == null) return b.id.compareTo(a.id);
        if (at == null) return 1;
        if (bt == null) return -1;
        return bt.compareTo(at);
      });
    return apps;
  }

  /// Demos the teacher has been booked for.
  Future<List<Application>> tutorDemos() async =>
      (await getList('/api/jobs/tutor/demos/', key: 'demos'))
          .map(Application.fromJson)
          .toList();

  /// Today's teaching, with attendance state per tuition.
  Future<TodaySchedule> todaySchedule() async =>
      TodaySchedule.fromJson(await getMap('/api/jobs/tutor/today-schedule/'));

  /// Every tuition this teacher holds, split by whether it is still running.
  ///
  /// The endpoint answers with both lists in one envelope, so this returns both
  /// rather than pretending it is a single list — the previous signature could
  /// only ever have shown one of them.
  Future<({List<TuitionRecord> active, List<TuitionRecord> past})>
      myTuitions() async {
    final data = await getMap('/api/jobs/tutor/my-tuitions/');
    List<TuitionRecord> at(String key) =>
        (data[key] is List ? data[key] as List : const [])
            .whereType<Map>()
            .map((e) => TuitionRecord.fromJson(e.cast<String, dynamic>()))
            .toList();
    return (active: at('active'), past: at('past'));
  }

  /// The teacher's own attendance log, newest first, optionally for a single
  /// tuition.
  ///
  /// The filter parameter is `job`; sending `job_id` returned the full history
  /// silently, which looks identical to a tuition with every session logged.
  Future<List<AttendanceRecord>> attendanceHistory({int? jobId}) async {
    final rows = await getList('/api/jobs/tutor/attendance/',
        query: jobId == null ? null : {'job': jobId});
    return rows.map(AttendanceRecord.fromJson).toList()
      ..sort((a, b) {
        final at = a.date, bt = b.date;
        if (at == null && bt == null) return b.id.compareTo(a.id);
        if (at == null) return 1;
        if (bt == null) return -1;
        return bt.compareTo(at);
      });
  }

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

  /// Whether this teacher already holds the parent's contact for [jobId], and
  /// whether they are allowed to take it.
  Future<UnlockStatus> unlockStatus(int jobId) async =>
      UnlockStatus.fromJson(await getMap('/api/users/jobs/$jobId/unlock-contact/'));

  /// Reveals the parent's contact behind a lead.
  ///
  /// Free, but not free of consequence: it also registers the teacher as an
  /// applicant, and a credit is deducted later if they never visit the family.
  Future<UnlockStatus> unlockJobContact(int jobId) async =>
      UnlockStatus.fromJson(await postMap('/api/users/jobs/$jobId/unlock-contact/'));

  /// Marks a demo as taken.
  /// Records that the teacher has taken the demo.
  ///
  /// This is the gate on the parent's side: their "Approve this teacher" button
  /// is refused until `demo_status` is COMPLETED, so a demo nobody marks leaves
  /// the hire stuck. Needs a scheduled `demo_date`, and refuses a second call.
  Future<Map<String, dynamic>> completeDemo(int applicationId) =>
      postMap('/api/jobs/tutor/demos/$applicationId/complete/');

  /// Ends a tuition the teacher is no longer taking.
  /// Closes a tuition the teacher has finished.
  ///
  /// PATCH, not POST — `TutorEndTuitionView` defines only `patch`. It takes no
  /// body either: the view writes `job_completion_status` and `completed_at`
  /// and nothing else, so a reason would be discarded. Refused unless the
  /// application is HIRED and the tuition is ONGOING.
  Future<Map<String, dynamic>> endTuition(int applicationId) =>
      patchMap('/api/jobs/tutor/applications/$applicationId/end-tuition/');

  /// Who else is in the running for a job.
  ///
  /// Refused with 403 unless this teacher has already applied, so callers must
  /// gate on `hasApplied` rather than showing an error.
  Future<CoApplicants> coApplicants(int jobId) async =>
      CoApplicants.fromJson(await getMap('/api/jobs/$jobId/co-applicants/'));

  // ── Institute ─────────────────────────────────────────────────────────────
  //
  // An institute has two distinct kinds of job. Keeping them apart is the whole
  // job of this section:
  //
  //   Tuition Requirement — a `JobPost`. The THT team posts it *for* the
  //     institute, runs the demos and the hiring. The institute monitors it and
  //     may close it. Owner-scoped `/api/jobs/my-jobs/`.
  //
  //   Faculty Vacancy — an `InstituteJob`. The institute posts it itself to
  //     hire its own teaching staff. No application pipeline, no unlock, just
  //     OPEN/CLOSED.
  //
  // Their ids collide, so a row from one must never be opened as the other.

  /// Tuition requirements this institute is the client on, newest first.
  Future<List<Job>> institutionTuitionRequirements() => _ownedJobs();

  /// Faculty vacancies this institute has posted, newest first.
  ///
  /// `?mode=my_jobs` is not optional: without it the view falls through to
  /// `filter(status='OPEN')` and returns **every institute's** open listings,
  /// which reads as your own board full of other people's posts.
  Future<List<FacultyVacancy>> facultyVacancies() async {
    final rows = await getList(
      '/api/jobs/institution/jobs/',
      query: {'mode': 'my_jobs'},
    );
    return rows.map(FacultyVacancy.fromJson).toList()
      ..sort((a, b) {
        final at = a.createdAt, bt = b.createdAt;
        if (at == null && bt == null) return b.id.compareTo(a.id);
        if (at == null) return 1;
        if (bt == null) return -1;
        return bt.compareTo(at);
      });
  }

  /// Posts a faculty vacancy. `INSTITUTION` role only, server-side.
  ///
  /// The institute cannot post a *tuition requirement* — those are created by
  /// THT staff with the institute as the client — so this is the only job an
  /// institute creates for itself.
  Future<FacultyVacancy> createFacultyVacancy(Map<String, dynamic> body) async =>
      FacultyVacancy.fromJson(
        await postMap('/api/jobs/institution/jobs/', body: body),
      );

  Future<FacultyVacancy> updateFacultyVacancy(
    int id,
    Map<String, dynamic> changes,
  ) async =>
      FacultyVacancy.fromJson(
        await patchMap('/api/jobs/institution/jobs/$id/', body: changes),
      );

  // ── Notifications ─────────────────────────────────────────────────────────

  Future<List<AppNotification>> notifications() async =>
      (await getList('/api/jobs/notifications/'))
          .map(AppNotification.fromJson)
          .toList();

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
