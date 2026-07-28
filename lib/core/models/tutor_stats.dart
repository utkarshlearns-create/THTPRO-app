import 'package:tht_app/core/utils/json_x.dart';

/// A teacher's numbers, from `GET /api/users/dashboard/stats/`.
class TutorStats {
  const TutorStats({
    this.totalApplications = 0,
    this.acceptedApplications = 0,
    this.pendingApplications = 0,
    this.rejectedApplications = 0,
    this.notSelectedApplications = 0,
    this.demoScheduled = 0,
    this.totalEarned = 0,
    this.totalFeeCollected = 0,
    this.pendingPayment = 0,
    this.completedTuitions = 0,
    this.earnings = const [],
  });

  /// Every application this teacher has made.
  final int totalApplications;

  /// Applications that turned into a hire.
  final int acceptedApplications;

  final int pendingApplications;
  final int rejectedApplications;
  final int notSelectedApplications;

  /// Demos the parent has accepted and the teacher still has to take.
  final int demoScheduled;

  /// The teacher's own share across completed tuitions.
  final int totalEarned;

  /// The full agreed fee across those tuitions, teacher share plus platform.
  final int totalFeeCollected;

  /// Earned but not yet paid out at month end.
  final double pendingPayment;

  final int completedTuitions;
  final List<EarningsRow> earnings;

  /// Share of applications that became a hire, 0–1. Null until they've applied.
  double? get hireRate =>
      totalApplications == 0 ? null : acceptedApplications / totalApplications;

  factory TutorStats.fromJson(Map<String, dynamic> json) => TutorStats(
        totalApplications: asInt(json, 'total_applications'),
        acceptedApplications: asInt(json, 'accepted_applications'),
        pendingApplications: asInt(json, 'pending_applications'),
        rejectedApplications: asInt(json, 'rejected_applications'),
        notSelectedApplications: asInt(json, 'not_selected_applications'),
        demoScheduled: asInt(json, 'demo_scheduled'),
        totalEarned: asInt(json, 'total_earned'),
        totalFeeCollected: asInt(json, 'total_fee_collected'),
        pendingPayment: asDouble(json, 'pending_payment'),
        completedTuitions: asInt(json, 'completed_tuitions'),
        earnings:
            asMapList(json, 'earnings_breakdown').map(EarningsRow.fromJson).toList(),
      );
}

/// One completed tuition and how its fee was split.
class EarningsRow {
  const EarningsRow({
    required this.id,
    this.student = '',
    this.classGrade = '',
    this.paymentStatus = '',
    this.totalFee = 0,
    this.yourShare = 0,
    this.platformShare = 0,
    this.completedOn = '',
  });

  final int id;
  final String student;
  final String classGrade;
  final String paymentStatus;

  /// The agreed monthly fee, not the amount collected online.
  final int totalFee;

  final int yourShare;
  final int platformShare;

  /// Pre-formatted by the backend, e.g. `12 Mar 2026`.
  final String completedOn;

  bool get isPaid => paymentStatus.toUpperCase() == 'PAID';

  factory EarningsRow.fromJson(Map<String, dynamic> json) => EarningsRow(
        id: asInt(json, 'id'),
        student: asString(json, 'student'),
        classGrade: asString(json, 'class_grade'),
        paymentStatus: asString(json, 'payment_status'),
        totalFee: asInt(json, 'total_fee'),
        yourShare: asInt(json, 'your_share'),
        platformShare: asInt(json, 'platform_share'),
        completedOn: asString(json, 'completed_at'),
      );
}
