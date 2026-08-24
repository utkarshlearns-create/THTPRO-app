import 'package:flutter_test/flutter_test.dart';
import 'package:tht_app/core/models/application.dart';
import 'package:tht_app/core/models/affiliate.dart';
import 'package:tht_app/core/models/attendance_record.dart';
import 'package:tht_app/core/models/co_applicants.dart';
import 'package:tht_app/core/models/payment_record.dart';
import 'package:tht_app/core/models/upgrade_quote.dart';
import 'package:tht_app/core/models/faculty_vacancy.dart';
import 'package:tht_app/core/models/job.dart';
import 'package:tht_app/core/models/kyc_status.dart';
import 'package:tht_app/core/models/tutor_profile.dart';
import 'package:tht_app/core/models/tutor_score.dart';
import 'package:tht_app/core/models/unlock_status.dart';
import 'package:tht_app/core/models/wallet.dart';

/// The models carry the rules screens read off. These are the ones where getting
/// it wrong would show a teacher something untrue.
void main() {
  group('Job', () {
    test('treats an absent parent phone as a locked contact', () {
      final locked = Job.fromJson({'id': 1});
      final unlocked = Job.fromJson({'id': 1, 'parent_phone': '9876543210'});
      expect(locked.isContactUnlocked, isFalse);
      expect(unlocked.isContactUnlocked, isTrue);
    });

    test('a repost counts as the time it entered the feed', () {
      final job = Job.fromJson({
        'id': 1,
        'created_at': '2026-01-01T00:00:00Z',
        'reposted_at': '2026-03-01T00:00:00Z',
      });
      expect(job.postedAt, job.repostedAt);
    });

    test('lists every child with the named one first', () {
      final job = Job.fromJson({
        'id': 1,
        'student_name': 'Aarav',
        'additional_students': [
          {'name': 'Ishita'},
          {'name': ''},
        ],
      });
      expect(job.allStudents, ['Aarav', 'Ishita']);
      expect(job.isMultiChild, isTrue);
    });

    test('formats a fee range in Indian grouping', () {
      expect(
        Job.fromJson({'id': 1, 'budget_range': '4000-4500'}).feeLabel,
        '₹4,000–4,500 / month',
      );
      expect(
        Job.fromJson({'id': 1, 'budget_range': '12000'}).feeLabel,
        '₹12,000 / month',
      );
      expect(
        Job.fromJson({'id': 1, 'budget_range': '150000'}).feeLabel,
        '₹1,50,000 / month',
      );
    });

    test('has no fee label when no budget was recorded', () {
      expect(Job.fromJson({'id': 1}).feeLabel, isNull);
      expect(Job.fromJson({'id': 1, 'budget_range': '  '}).feeLabel, isNull);
    });

    // The wizard stores a composed sentence rather than a structured range, and
    // the parser used to strip non-digits — gluing 6,500 and 7,000 and the "2"
    // from "2 days a week" into a fee of ₹65,00,70,002 a month.
    test('reads the fee out of a composed sentence, ignoring the other numbers',
        () {
      String? fee(String raw) =>
          Job.fromJson({'id': 1, 'budget_range': raw}).feeLabel;

      expect(
        fee('₹6,500 - ₹7,000 / month (2 days a week)'),
        '₹6,500–7,000 / month',
      );
      // An en-dash is what broke the old split and sent the whole string
      // through the digit-stripper.
      expect(
        fee('₹6,500 – ₹7,000 / month (2 days a week)'),
        '₹6,500–7,000 / month',
      );
      expect(
        fee('₹7,000 - ₹9,000 / month (per subject, 3 days a week)'),
        '₹7,000–9,000 / month',
      );
      expect(
        fee('₹3,500 - ₹5,000 / month (6 days a week)'),
        '₹3,500–5,000 / month',
      );
    });

    test('collapses a range whose ends are equal', () {
      expect(
        Job.fromJson({'id': 1, 'budget_range': '5000-5000'}).feeLabel,
        '₹5,000 / month',
      );
    });

    test('orders a reversed range', () {
      expect(
        Job.fromJson({'id': 1, 'budget_range': '7000-4000'}).feeLabel,
        '₹4,000–7,000 / month',
      );
    });

    test('passes prose through rather than inventing a figure', () {
      expect(
        Job.fromJson({'id': 1, 'budget_range': 'Negotiable based on requirements'})
            .feeLabel,
        'Negotiable based on requirements',
      );
      // Every figure here is a day count, not money.
      expect(
        Job.fromJson({'id': 1, 'budget_range': 'Negotiable, 3 days a week'})
            .feeLabel,
        'Negotiable, 3 days a week',
      );
    });
  });

  // The parent's applicant screen picks its buttons off these. The server runs
  // a strict sequence — shortlist, agree the slot, approve with a review — and
  // refuses anything out of order, so reading a state wrong shows a parent an
  // action that can only fail.
  group('Application demo stages', () {
    Application at({String? status, String? demo, String? date}) =>
        Application.fromJson({
          'id': 1,
          'job': 9,
          if (status != null) 'status': status,
          if (demo != null) 'demo_status': demo,
          if (date != null) 'demo_date': date,
        });

    test('a shortlisted teacher with no date is not awaiting the parent', () {
      // ACCEPT_DEMO sets demo_status=PENDING before anyone has picked a time.
      // Offering "accept this time" here would be offering a time that does
      // not exist.
      final requested = at(status: 'SHORTLISTED', demo: 'PENDING');
      expect(requested.isDemoAwaitingParent, isFalse);
      expect(requested.isDemoBooked, isFalse);
      expect(requested.isDemoDone, isFalse);
    });

    test('a scheduled slot is the parent\'s to accept', () {
      final scheduled = at(
        status: 'SHORTLISTED',
        demo: 'PENDING',
        date: '2026-08-04T16:00:00Z',
      );
      expect(scheduled.isDemoAwaitingParent, isTrue);
      expect(scheduled.stageLabel, 'Demo proposed');
    });

    test('an accepted slot is booked, not done', () {
      final booked = at(demo: 'ACCEPTED', date: '2026-08-04T16:00:00Z');
      expect(booked.isDemoBooked, isTrue);
      expect(booked.isDemoDone, isFalse,
          reason: 'approving here is a guaranteed 400 — the demo has not '
              'happened yet');
    });

    test('only a completed demo unlocks approval', () {
      final done = at(status: 'SHORTLISTED', demo: 'COMPLETED');
      expect(done.isDemoDone, isTrue);
      expect(done.isDemoAwaitingParent, isFalse);
    });

    test('a fresh application is in none of the demo states', () {
      final fresh = at(status: 'APPLIED');
      expect(fresh.isDemoAwaitingParent, isFalse);
      expect(fresh.isDemoBooked, isFalse);
      expect(fresh.isDemoDone, isFalse);
      expect(fresh.isAwaiting, isTrue);
    });
  });

  group('AttendanceRecord', () {
    test('counts a late session as taught, an absence as not', () {
      AttendanceRecord withStatus(String s) =>
          AttendanceRecord.fromJson({'id': 1, 'job': 2, 'status': s});

      expect(withStatus('PRESENT').counted, isTrue);
      expect(withStatus('LATE').counted, isTrue,
          reason: 'the teacher turned up; the fee for it is still owed');
      expect(withStatus('ABSENT').counted, isFalse);
      expect(withStatus('RESCHEDULED').counted, isFalse);
    });

    test('names the lateness when there are minutes to name', () {
      expect(
        AttendanceRecord.fromJson(
                {'id': 1, 'job': 2, 'status': 'LATE', 'minutes_late': 15})
            .statusLabel,
        'Late by 15 min',
      );
      expect(
        AttendanceRecord.fromJson({'id': 1, 'job': 2, 'status': 'LATE'})
            .statusLabel,
        'Late',
      );
    });

    test('has lesson notes only when something was written', () {
      expect(
        AttendanceRecord.fromJson({'id': 1, 'job': 2, 'topic_taught': '  '})
            .hasLesson,
        isFalse,
      );
      expect(
        AttendanceRecord.fromJson(
                {'id': 1, 'job': 2, 'homework_given': 'Ex 4.2'})
            .hasLesson,
        isTrue,
      );
    });

    test('reads the job as the bare id the serializer sends', () {
      // `fields = '__all__'` on a ModelSerializer means `job` is a pk, not an
      // object — the screen pairs it with the tuition list to get a label.
      expect(
        AttendanceRecord.fromJson({'id': 1, 'job': 42}).jobId,
        42,
      );
    });
  });

  // `class_subjects` is the writable field — `subjects` and `classes` are in
  // the serializer's read_only_fields — so parsing it wrong means a teacher
  // cannot set the one thing every job match runs on.
  group('TutorProfile class_subjects', () {
    Map<String, List<String>> parse(Object? raw) =>
        TutorProfile.fromJson({'id': 1, 'class_subjects': raw}).classSubjects;

    test('reads the class → subjects map', () {
      expect(
        parse({
          'Class 10': ['Maths', 'Science'],
          'Class 9': ['Maths'],
        }),
        {
          'Class 10': ['Maths', 'Science'],
          'Class 9': ['Maths'],
        },
      );
    });

    test('keeps a class that has no subjects chosen yet', () {
      // The picker adds the class first and the subjects second, so this is a
      // real intermediate state the server can hold.
      expect(parse({'Class 8': []}), {'Class 8': <String>[]});
    });

    test('tolerates a single subject stored as a bare string', () {
      expect(parse({'Class 12': 'Physics'}), {
        'Class 12': ['Physics'],
      });
    });

    test('is empty rather than throwing on a missing or wrong-typed field', () {
      expect(parse(null), isEmpty);
      expect(parse('nonsense'), isEmpty);
      expect(TutorProfile.fromJson({'id': 1}).classSubjects, isEmpty);
    });

    test('drops blank class names and blank subjects', () {
      expect(
        parse({
          '  ': ['Maths'],
          'Class 7': ['English', '', '  '],
        }),
        {
          'Class 7': ['English'],
        },
      );
    });
  });

  group('TutorScore', () {
    test('a new teacher is unrated rather than badly rated', () {
      final fresh = TutorScore.fromJson({
        'rank_badge': 'PENDING',
        'modules_present': 0,
      });
      expect(fresh.isRated, isFalse);
      expect(fresh.totalScore, isNull,
          reason: 'the screen shows a dash here, never a zero');
      expect(fresh.standing, contains('starts once'));
    });

    test('reads all seven modules, leaving unscored ones null', () {
      final score = TutorScore.fromJson({
        'total_score': 82.4,
        'rank_badge': 'PRO',
        'modules_present': 3,
        'qualification_score': 90.0,
        'demo_score': 78.0,
        'parent_rating_score': 80.0,
      });
      expect(score.isRated, isTrue);

      final measured = score.modules.where((m) => m.value != null);
      expect(measured.length, 3);
      expect(
        score.modules.where((m) => m.value == null).map((m) => m.label),
        containsAll(['Attendance', 'Communication', 'First month']),
      );
    });

    test('reads the city rank out of the ranks list', () {
      final score = TutorScore.fromJson({
        'total_score': 70.0,
        'rank_badge': 'RISING',
        'modules_present': 2,
        'ranks': [
          {'scope': 'STATE', 'rank': 40, 'cohort_size': 900},
          {'scope': 'CITY', 'rank': 4, 'cohort_size': 212},
        ],
      });
      expect(score.cityRank, 4);
      expect(score.standing, 'Ranked #4 of 212 teachers in your city.');
    });
  });

  group('UpgradeQuote', () {
    test('is only a real upgrade when there is value to credit back', () {
      // No active plan: the server still answers, but at full price. Calling
      // that an upgrade would show a discount that does not exist.
      final fresh = UpgradeQuote.fromJson({
        'package_id': 3,
        'package_price': 999.0,
        'remaining_value': 0.0,
        'upgrade_price': 999.0,
      });
      expect(fresh.isRealUpgrade, isFalse);

      final real = UpgradeQuote.fromJson({
        'package_id': 3,
        'package_price': 999.0,
        'remaining_value': 240.0,
        'upgrade_price': 759.0,
        'upgrade_credits': 12,
      });
      expect(real.isRealUpgrade, isTrue);
      expect(real.saving, 240.0);
    });

    test('never reports a negative saving', () {
      final odd = UpgradeQuote.fromJson({
        'package_id': 1,
        'package_price': 500.0,
        'remaining_value': 10.0,
        'upgrade_price': 600.0,
      });
      expect(odd.saving, 0);
      expect(odd.isRealUpgrade, isFalse);
    });
  });

  group('Affiliate', () {
    test('holds a payout below the minimum and says what is missing', () {
      final short = Affiliate.fromJson({
        'referral_code': 'THT123',
        'pending_payout': '320.00',
      });
      expect(short.canRequestPayout, isFalse);
      expect(short.shortfall, 180.0);

      final ready = Affiliate.fromJson({'pending_payout': '640.00'});
      expect(ready.canRequestPayout, isTrue);
      expect(ready.shortfall, 0);
    });

    test('counts only the referrals that bought a plan', () {
      // Signing up earns nothing; buying a plan does. Counting joiners as
      // conversions would promise money that is not coming.
      final a = Affiliate.fromJson({
        'total_referred': 3,
        'referred_users': [
          {'name': 'A', 'purchased_plan': true},
          {'name': 'B', 'purchased_plan': false},
          {'name': 'C', 'purchased_plan': true},
        ],
      });
      expect(a.totalReferred, 3);
      expect(a.convertedCount, 2);
    });
  });

  group('PaymentRecord', () {
    test('tells an abandoned order apart from a declined payment', () {
      final abandoned = PaymentRecord.fromJson({
        'id': 1,
        'order_id': 'order_x',
        'status': 'PENDING',
      });
      expect(abandoned.isAbandoned, isTrue);
      expect(abandoned.statusLabel, 'Not completed');

      final declined = PaymentRecord.fromJson({
        'id': 2,
        'order_id': 'order_y',
        'payment_id': 'pay_y',
        'status': 'FAILED',
      });
      expect(declined.isAbandoned, isFalse);
      expect(declined.statusLabel, 'Failed');
    });

    test('quotes the payment id when there is one, else the order', () {
      expect(
        PaymentRecord.fromJson(
            {'id': 1, 'order_id': 'order_x', 'payment_id': 'pay_x'}).reference,
        'pay_x',
      );
      expect(
        PaymentRecord.fromJson({'id': 1, 'order_id': 'order_x'}).reference,
        'order_x',
      );
    });
  });

  group('CoApplicants', () {
    test('separates the reader from everyone else', () {
      final co = CoApplicants.fromJson({
        'total_count': 3,
        'my_rank': 2,
        'applicants': [
          {'tutor_id': 1, 'name': 'A', 'application_rank': 1},
          {'tutor_id': 2, 'name': 'Me', 'is_me': true, 'application_rank': 2},
          {'tutor_id': 3, 'name': 'C', 'application_rank': 3},
        ],
      });
      expect(co.me?.name, 'Me');
      expect(co.others.map((a) => a.name), ['A', 'C']);
      expect(co.myRank, 2);
    });

    test('an unrated rival shows no score', () {
      // A PENDING badge beside a rated teacher would read as a rating rather
      // than an absence of one.
      final pending = CoApplicant.fromJson({
        'tutor_id': 9,
        'rank_badge': 'PENDING',
        'total_score': 0,
      });
      expect(pending.isRated, isFalse);

      final rated = CoApplicant.fromJson({
        'tutor_id': 9,
        'rank_badge': 'PRO',
        'total_score': 81.0,
      });
      expect(rated.isRated, isTrue);
    });
  });

  // An institute has two kinds of job with colliding ids. Parsing one as the
  // other opens an unrelated record, which is how a vacancy row used to lead to
  // a stranger's applicant list.
  group('FacultyVacancy', () {
    test('reads the InstituteJob shape, which shares no fields with JobPost',
        () {
      final v = FacultyVacancy.fromJson({
        'id': 12,
        'title': 'Senior Physics Faculty',
        'subject': 'Physics',
        'class_level': 'Class 11-12 (JEE Main)',
        'salary_range': '50k - 70k per month',
        'job_type': 'PART_TIME',
        'status': 'OPEN',
      });
      expect(v.isOpen, isTrue);
      expect(v.summaryLine, 'Physics • Class 11-12 (JEE Main)');
      expect(v.jobTypeLabel, 'Part time');
    });

    test('defaults to an open full-time post when the server omits them', () {
      final v = FacultyVacancy.fromJson({'id': 1});
      expect(v.status, 'OPEN');
      expect(v.jobType, 'FULL_TIME');
      expect(v.isOpen, isTrue);
    });

    test('a closed vacancy is not open', () {
      expect(
        FacultyVacancy.fromJson({'id': 1, 'status': 'CLOSED'}).isOpen,
        isFalse,
      );
    });

    test('offers exactly the four job types the server accepts', () {
      expect(
        FacultyVacancy.jobTypes.keys,
        ['FULL_TIME', 'PART_TIME', 'CONTRACT', 'GUEST_LECTURE'],
      );
    });
  });

  group('Wallet', () {
    test('is only expired once validity has actually started', () {
      final notStarted = Wallet.fromJson({
        'balance': 10,
        'validity_activated': false,
        'pending_validity_days': 30,
      });
      expect(notStarted.isExpired, isFalse,
          reason: 'the clock has not begun, so nothing has lapsed');
    });

    test('flags the last week as expiring soon, but not a lapsed plan', () {
      final soon = Wallet.fromJson({
        'balance': 5,
        'validity_activated': true,
        'valid_until':
            DateTime.now().add(const Duration(days: 3)).toIso8601String(),
      });
      expect(soon.isExpiringSoon, isTrue);
      expect(soon.isExpired, isFalse);

      final gone = Wallet.fromJson({
        'balance': 5,
        'validity_activated': true,
        'valid_until':
            DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
      });
      expect(gone.isExpired, isTrue);
      expect(gone.isExpiringSoon, isFalse,
          reason: 'an expired plan must not also read as expiring');
    });

    test('has no days remaining when there is no validity window at all', () {
      expect(Wallet.fromJson({'balance': 3}).daysRemaining, isNull);
    });

    test('a debit renders as an outgoing amount', () {
      final debit = WalletTransaction.fromJson({
        'id': 1,
        'amount': 1,
        'transaction_type': 'DEBIT',
      });
      expect(debit.isCredit, isFalse);
      expect(debit.signedAmount, '−1');
    });
  });

  group('UnlockStatus', () {
    test('needs a credit to unlock even though unlocking is free', () {
      final broke = UnlockStatus.fromJson({'is_unlocked': false, 'balance': 0});
      expect(broke.canUnlock, isFalse);
      expect(broke.blockedReason, contains('at least one credit'));

      final ok = UnlockStatus.fromJson({'is_unlocked': false, 'balance': 2});
      expect(ok.canUnlock, isTrue);
      expect(ok.blockedReason, isNull);
    });

    test('a capped lead blocks regardless of balance', () {
      final capped = UnlockStatus.fromJson({
        'is_unlocked': false,
        'balance': 50,
        'limit_reached': true,
        'unlock_count': 3,
        'max_unlocks': 3,
      });
      expect(capped.canUnlock, isFalse);
      expect(capped.slotsLeft, 0);
      expect(capped.blockedReason, contains('limit'));
    });

    test('reports no cap as null slots, not zero', () {
      final uncapped = UnlockStatus.fromJson({'balance': 1, 'max_unlocks': 0});
      expect(uncapped.slotsLeft, isNull);
    });
  });

  group('Application', () {
    test('a completed tuition no longer reads as merely hired', () {
      final done = Application.fromJson({
        'id': 1,
        'job': 9,
        'status': 'HIRED',
        'job_completion_status': 'COMPLETED',
      });
      expect(done.stageLabel, 'Completed');
      expect(done.toneKey, 'COMPLETED');
    });

    test('a running tuition is distinguished from a fresh hire', () {
      final running = Application.fromJson({
        'id': 1,
        'job': 9,
        'status': 'HIRED',
        'job_completion_status': 'ONGOING',
      });
      expect(running.isRunning, isTrue);
      expect(running.stageLabel, 'Teaching');
    });

    test('an accepted demo takes precedence over "awaiting reply"', () {
      final demo = Application.fromJson({
        'id': 1,
        'job': 9,
        'status': 'APPLIED',
        'demo_status': 'ACCEPTED',
      });
      expect(demo.hasUpcomingDemo, isTrue);
      expect(demo.stageLabel, 'Demo booked');
    });

    test('reads the job id out of the embedded details when present', () {
      final app = Application.fromJson({
        'id': 1,
        'job': 9,
        'job_details': {'id': 42, 'class_grade': 'Class 10'},
      });
      expect(app.jobId, 42);
      expect(app.job?.classGrade, 'Class 10');
    });

    test('falls back to half the finalised fee when no share is recorded', () {
      final app = Application.fromJson({
        'id': 1,
        'job': 9,
        'finalized_amount': '4000.00',
      });
      expect(app.earning, 2000.0);
    });
  });

  group('KycStatus', () {
    test('an approved teacher is verified even without a VERIFIED kyc row', () {
      final status = KycStatus.fromJson({
        'kyc': {'status': 'SUBMITTED'},
        'tutor_status': 'ACTIVE',
      });
      expect(status.isVerified, isTrue);
      expect(status.nextStep, isNull,
          reason: 'a verified teacher should not be nagged');
    });

    test('reads the bare NOT_SUBMITTED shape', () {
      final status = KycStatus.fromJson({'status': 'NOT_SUBMITTED'});
      expect(status.notStarted, isTrue);
      expect(status.nextStep, contains('Upload'));
    });

    test('names the documents an admin asked to be re-sent, in plain words',
        () {
      final status = KycStatus.fromJson({
        'kyc': {'status': 'PENDING'},
        'documents_to_resubmit': ['aadhaar_back', 'pan_document'],
      });
      // Raw field names used to leak into the banner as "Re-upload:
      // pan_document" — a column name shown to a teacher.
      expect(status.nextStep, contains('Aadhaar (back)'));
      expect(status.nextStep, contains('PAN card'));
      expect(status.nextStep, isNot(contains('pan_document')));
    });

    test('falls back to spaced words for a field it does not know', () {
      expect(KycStatus.readableDoc('some_new_doc'), 'some new doc');
    });

    test('reads per-document state off the kyc record', () {
      final status = KycStatus.fromJson({
        'kyc': {
          'status': 'PENDING',
          'submission_count': 2,
          'aadhaar_front': 'https://x/a.jpg',
          'aadhaar_front_verified': true,
          'pan_document': null,
        },
        'documents_to_resubmit': ['pan_document'],
      });
      expect(status.submissionCount, 2);
      expect(status.hasDoc('aadhaar_front'), isTrue);
      expect(status.hasDoc('pan_document'), isFalse,
          reason: 'a null file must not read as uploaded');
      expect(status.isDocVerified('aadhaar_front_verified'), isTrue);
      expect(status.isDocVerified('pan_verified'), isFalse);
      expect(status.isDocVerified(null), isFalse,
          reason: 'slots with no verified flag are never "verified"');
      expect(status.needsResubmit('pan_document'), isTrue);
    });
  });
}
