import 'package:tht_app/core/utils/json_x.dart';

/// Where a teacher stands in verification, from `GET /api/users/kyc/status/`.
///
/// The response has two shapes — a bare `NOT_SUBMITTED` marker before any
/// documents are uploaded, and a full record afterwards — so this flattens both
/// into one thing the UI can read.
class KycStatus {
  const KycStatus({
    this.status = 'NOT_SUBMITTED',
    this.tutorStatus = '',
    this.adminFeedback,
    this.rejectionReason,
    this.documentsToResubmit = const [],
  });

  /// `NOT_SUBMITTED`, `PENDING`, `VERIFIED`, `REJECTED`.
  final String status;

  /// The teacher's overall standing: `APPROVED`, `ACTIVE`, `ON_HOLD`…
  final String tutorStatus;

  final String? adminFeedback;
  final String? rejectionReason;

  /// Specific documents the reviewer wants uploaded again.
  final List<String> documentsToResubmit;

  bool get isVerified =>
      status.toUpperCase() == 'VERIFIED' ||
      tutorStatus.toUpperCase() == 'APPROVED' ||
      tutorStatus.toUpperCase() == 'ACTIVE';

  bool get isPending => status.toUpperCase() == 'PENDING' && !isVerified;
  bool get isRejected => status.toUpperCase() == 'REJECTED';
  bool get notStarted => status.toUpperCase() == 'NOT_SUBMITTED';

  /// One line for the header pill.
  String get shortLabel {
    if (isVerified) return 'Verified teacher';
    if (isPending) return 'Verification in review';
    if (isRejected) return 'Verification needs attention';
    return 'Not verified yet';
  }

  /// What the teacher should do next, or null when nothing is required.
  String? get nextStep {
    if (isVerified) return null;
    if (notStarted) {
      return 'Upload your ID and qualification documents to start getting leads.';
    }
    if (isRejected) {
      return rejectionReason?.trim().isNotEmpty == true
          ? rejectionReason
          : 'Some documents were not accepted. Upload them again to continue.';
    }
    if (documentsToResubmit.isNotEmpty) {
      return 'Re-upload: ${documentsToResubmit.join(', ')}.';
    }
    return "Our team is checking your documents. You'll hear back shortly.";
  }

  factory KycStatus.fromJson(Map<String, dynamic> json) {
    final kyc = asMapOrNull(json, 'kyc');
    return KycStatus(
      status: kyc != null
          ? asString(kyc, 'status', fallback: 'PENDING')
          : asString(json, 'status', fallback: 'NOT_SUBMITTED'),
      tutorStatus: asString(json, 'tutor_status'),
      adminFeedback: asStringOrNull(json, 'admin_feedback'),
      rejectionReason: asStringOrNull(json, 'rejection_reason'),
      documentsToResubmit: asStringList(json, 'documents_to_resubmit'),
    );
  }
}
