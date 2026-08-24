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
    this.submissionCount = 0,
    this.record = const {},
  });

  /// `NOT_SUBMITTED`, `PENDING`, `VERIFIED`, `REJECTED`.
  final String status;

  /// The teacher's overall standing: `APPROVED`, `ACTIVE`, `ON_HOLD`…
  final String tutorStatus;

  final String? adminFeedback;
  final String? rejectionReason;

  /// Specific documents the reviewer wants uploaded again.
  final List<String> documentsToResubmit;

  /// How many times this teacher has submitted. The server caps resubmissions,
  /// so a teacher deserves to know where they stand rather than discovering the
  /// limit by hitting it.
  final int submissionCount;

  /// The raw KYC row, for per-document state the model does not name.
  final Map<String, dynamic> record;

  /// Whether our team has checked one specific document.
  bool isDocVerified(String? verifiedField) =>
      verifiedField != null && record[verifiedField] == true;

  /// Whether a file has ever been uploaded into this slot. The serializer
  /// returns a URL when there is one and null when there is not.
  bool hasDoc(String field) {
    final v = record[field];
    return v != null && v.toString().trim().isNotEmpty;
  }

  /// This exact document was named in the reviewer's resubmit list.
  bool needsResubmit(String field) => documentsToResubmit.contains(field);

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
      return 'Re-upload: ${documentsToResubmit.map(readableDoc).join(', ')}.';
    }
    return "Our team is checking your documents. You'll hear back shortly.";
  }

  /// Turns a form field into something a teacher would recognise —
  /// `pan_document` reads as "PAN card", not as a column name.
  ///
  /// Deliberately a plain transform rather than a lookup against the document
  /// catalogue: that lives in the UI layer and pulls in Flutter for its icons,
  /// which a model has no business importing.
  static String readableDoc(String field) {
    const known = <String, String>{
      'aadhaar_front': 'Aadhaar (front)',
      'aadhaar_back': 'Aadhaar (back)',
      'pan_document': 'PAN card',
      'passport_document': 'passport',
      'police_verification': 'police verification',
      'highest_qualification_certificate': 'highest qualification',
      'intermediate_certificate': '12th certificate',
      'graduation_certificate': 'graduation certificate',
      'post_grad_certificate': 'post-graduation certificate',
      'bed_certificate': 'B.Ed certificate',
      'btc_certificate': 'BTC certificate',
      'tet_certificate': 'TET certificate',
      'ctet_certificate': 'CTET certificate',
      'net_certificate': 'NET certificate',
      'mphil_certificate': 'M.Phil certificate',
      'phd_certificate': 'PhD certificate',
      'subject_diploma_certificate': 'subject diploma',
      'teaching_certificate': 'teaching certificate',
      'profile_photo': 'profile photo',
    };
    final hit = known[field.trim().toLowerCase()];
    if (hit != null) return hit;
    // Anything the server adds later still reads as words rather than a slug.
    return field.replaceAll('_', ' ').trim();
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
      submissionCount:
          kyc != null ? asInt(kyc, 'submission_count') : asInt(json, 'submission_count'),
      record: kyc ?? const {},
    );
  }
}
