import 'package:flutter_test/flutter_test.dart';
import 'package:tht_app/core/models/application.dart';
import 'package:tht_app/core/models/job.dart';
import 'package:tht_app/core/models/kyc_status.dart';
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

    test('names the documents an admin asked to be re-sent', () {
      final status = KycStatus.fromJson({
        'kyc': {'status': 'PENDING'},
        'documents_to_resubmit': ['aadhaar_back'],
      });
      expect(status.nextStep, contains('aadhaar_back'));
    });
  });
}
