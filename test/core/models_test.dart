import 'package:flutter_test/flutter_test.dart';
import 'package:tht_app/core/models/application.dart';
import 'package:tht_app/core/models/affiliate.dart';
import 'package:tht_app/core/models/attendance_record.dart';
import 'package:tht_app/core/models/chance_detail.dart';
import 'package:tht_app/core/models/co_applicants.dart';
import 'package:tht_app/core/models/payment_record.dart';
import 'package:tht_app/core/models/upgrade_quote.dart';
import 'package:tht_app/core/models/faculty_vacancy.dart';
import 'package:tht_app/core/models/job.dart';
import 'package:tht_app/core/models/kyc_status.dart';
import 'package:tht_app/core/models/lead_purchase.dart';
import 'package:tht_app/core/models/tutor_profile.dart';
import 'package:tht_app/core/utils/api_error.dart';
import 'package:tht_app/features/jobs/widgets/ineligible_notice.dart';
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

  // Pay-per-lead decides whether a teacher sees a price, a lock, or a number.
  // Reading the flags wrong either hides a buyable lead or offers a purchase
  // the server will refuse — and money is involved either way.
  group('Job pay-per-lead flags', () {
    Job lead({bool contact = false, bool ppl = false, int? price}) =>
        Job.fromJson({
          'id': 1,
          'allow_contact': contact,
          'allow_pay_per_lead': ppl,
          if (price != null) 'lead_price': price,
        });

    test('buyable needs contact, the opt-in, and a price together', () {
      expect(lead(contact: true, ppl: true, price: 700).isBuyable, isTrue);
      expect(lead(contact: true, ppl: true).isBuyable, isFalse,
          reason: 'no price means the server did not offer it for sale');
      expect(lead(contact: true, price: 700).isBuyable, isFalse);
      expect(lead(ppl: true, price: 700).isBuyable, isFalse);
    });

    test('a zero price is not a free lead', () {
      // The server sends null for "not for sale". A 0 would be a bug, and
      // showing "Buy for Rs 0" is worse than showing nothing.
      expect(lead(contact: true, ppl: true, price: 0).isBuyable, isFalse);
    });

    test('THT-managed is contact without the opt-in', () {
      expect(lead(contact: true).isThtManaged, isTrue);
      expect(lead(contact: true, ppl: true, price: 700).isThtManaged, isFalse);
      expect(lead().isThtManaged, isFalse);
    });

    test('the price is never invented — absent means absent', () {
      expect(Job.fromJson({'id': 1}).leadPrice, isNull);
      expect(Job.fromJson({'id': 1, 'lead_price': null}).leadPrice, isNull);
    });
  });

  group('UnlockStatus buying rules', () {
    UnlockStatus at({
      bool unlocked = false,
      bool approved = true,
      int count = 0,
      int max = 0,
      bool limit = false,
    }) =>
        UnlockStatus.fromJson({
          'is_unlocked': unlocked,
          'is_approved': approved,
          'unlock_count': count,
          'max_unlocks': max,
          'limit_reached': limit,
        });

    test('an unapproved teacher cannot buy, however open the lead', () {
      expect(at(approved: false).canBuy(leadIsBuyable: true), isFalse,
          reason: 'the server refuses this, so the button must not appear');
    });

    test('a full lead cannot be bought', () {
      expect(at(count: 3, max: 3).canBuy(leadIsBuyable: true), isFalse);
      expect(at(limit: true).canBuy(leadIsBuyable: true), isFalse);
      expect(at(count: 2, max: 3).canBuy(leadIsBuyable: true), isTrue);
    });

    test('an already-held lead is not for sale again', () {
      expect(at(unlocked: true).canBuy(leadIsBuyable: true), isFalse);
    });

    test('a lead that is not for sale cannot be bought by anyone', () {
      expect(at().canBuy(leadIsBuyable: false), isFalse);
    });

    test('credits do not gate a purchase', () {
      // Pay-per-lead is real money through Razorpay. A zero credit balance is
      // irrelevant, and gating on it would block every teacher who has never
      // bought a package.
      final broke =
          UnlockStatus.fromJson({'is_approved': true, 'balance': 0});
      expect(broke.canBuy(leadIsBuyable: true), isTrue);
    });

    test('spots line counts down against a cap', () {
      expect(at(count: 2, max: 5).spotsLine, '2 of 5 taken — only 3 left');
      expect(at(count: 5, max: 5).spotsLine, 'All places taken');
    });

    test('uncapped leads talk about interest, not scarcity', () {
      expect(at().spotsLine, 'Be the first to buy this lead');
      expect(at(count: 1).spotsLine, '1 teacher has bought this lead');
    });
  });

  group('LeadOrder', () {
    test('keeps paise and rupees apart', () {
      final order = LeadOrder.fromJson({
        'order_id': 'order_abc',
        'amount': 70000,
        'currency': 'INR',
        'key_id': 'rzp_test_x',
        'lead_price': 700,
        'job_id': 42,
      });
      // Razorpay charges paise; the button shows rupees. Deriving one from the
      // other in the app is how a 100x charge happens.
      expect(order.amountPaise, 70000);
      expect(order.leadPrice, 700);
    });
  });

  // The chance breakdown is advice a teacher acts on, so the weighting has to
  // survive parsing intact — a pillar worth 10 and one worth 2 are not the
  // same miss.
  group('ChanceDetail', () {
    ChanceDetail parse(Map<String, dynamic> labels, {double? pct}) =>
        ChanceDetail.fromJson({
          if (pct != null) 'chance_percentage': pct,
          'compatibility_labels': labels,
        });

    test('orders pillars by weight, heaviest first', () {
      final d = parse({
        'salary': {'label': 'Salary Fit', 'max': 2, 'score': 2},
        'subject': {'label': 'Subject Match', 'max': 10, 'score': 7},
        'location': {'label': 'Location', 'max': 5, 'score': 1},
      });
      expect(d.pillars.map((p) => p.label),
          ['Subject Match', 'Location', 'Salary Fit']);
    });

    test('weakest is measured by points lost, not by score', () {
      // 3/10 loses 7; 0/2 loses only 2. The low score is not the big problem.
      final d = parse({
        'subject': {'label': 'Subject Match', 'max': 10, 'score': 3},
        'salary': {'label': 'Salary Fit', 'max': 2, 'score': 0},
      });
      expect(d.weakest?.label, 'Subject Match');
    });

    test('a perfect score has no weakest pillar to name', () {
      final d = parse({
        'subject': {'label': 'Subject Match', 'max': 10, 'score': 10},
        'salary': {'label': 'Salary Fit', 'max': 2, 'score': 2},
      });
      expect(d.weakest, isNull);
    });

    test('a zero-weight pillar reads as complete, not as a divide by zero', () {
      final p = ChancePillar.fromJson({'label': 'X', 'max': 0, 'score': 0});
      expect(p.fraction, 1);
      expect(p.isFull, isTrue);
      expect(p.lost, 0);
    });

    test('survives a payload with no breakdown at all', () {
      final d = ChanceDetail.fromJson({'chance_percentage': 62});
      expect(d.percentage, 62);
      expect(d.hasBreakdown, isFalse);
      expect(d.weakest, isNull);
    });
  });

  // Eligibility is a curation gate an admin sets. Getting the default wrong
  // would bar every teacher on a server that does not send the field yet, so
  // the absent case matters more than the present one.
  group('TutorProfile eligibility', () {
    test('only an explicit false bars anyone', () {
      expect(
        TutorProfile.fromJson({'id': 1, 'is_eligible': false}).isEligible,
        isFalse,
      );
      expect(
        TutorProfile.fromJson({'id': 1, 'is_eligible': true}).isEligible,
        isTrue,
      );
    });

    test('an older server that omits the field leaves everyone eligible', () {
      expect(TutorProfile.fromJson({'id': 1}).isEligible, isTrue);
      expect(
        TutorProfile.fromJson({'id': 1, 'is_eligible': null}).isEligible,
        isTrue,
        reason: 'a null flag must never be read as barred',
      );
    });

    test('carries the reason when one was recorded', () {
      final p = TutorProfile.fromJson({
        'id': 1,
        'is_eligible': false,
        'ineligible_reason': 'Not in the serviceable city',
      });
      expect(p.ineligibleReason, 'Not in the serviceable city');
    });
  });

  group('IneligibleNotice copy', () {
    test('falls back when no reason was stored', () {
      // The server sends an empty string rather than null when the admin left
      // the reason blank, so both have to fall through.
      expect(IneligibleNotice.reasonOr(null), contains('THT coordinator'));
      expect(IneligibleNotice.reasonOr(''), contains('THT coordinator'));
      expect(IneligibleNotice.reasonOr('   '), contains('THT coordinator'));
    });

    test('uses the admin reason when there is one', () {
      expect(
        IneligibleNotice.reasonOr('Not in the serviceable city'),
        'Not in the serviceable city',
      );
    });
  });

  group('ApiFailure raw body', () {
    test('keeps boolean refusal flags that fieldErrors drops', () {
      // fieldErrors only retains strings and lists, so `not_eligible: true`
      // vanished before any screen could branch on it.
      const f = ApiFailure(
        'blocked',
        statusCode: 403,
        body: {'not_eligible': true, 'ineligible_reason': 'No service'},
      );
      expect(f.flag('not_eligible'), isTrue);
      expect(f.flag('lead_full'), isFalse);
      expect(f.body['ineligible_reason'], 'No service');
    });

    test('a missing flag is false, not an error', () {
      expect(const ApiFailure('x').flag('not_eligible'), isFalse);
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

  group('UnlockStatus slots', () {
    test('reports no cap as null slots, not zero', () {
      // Null means unlimited; 0 would read as "sold out" and hide the button.
      expect(UnlockStatus.fromJson({'max_unlocks': 0}).slotsLeft, isNull);
      expect(
        UnlockStatus.fromJson({'max_unlocks': 3, 'unlock_count': 3}).slotsLeft,
        0,
      );
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
