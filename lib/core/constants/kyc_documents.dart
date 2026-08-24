import 'package:flutter/material.dart';

/// One document slot the KYC record holds.
class KycDoc {
  const KycDoc(
    this.field,
    this.label,
    this.hint, {
    this.required = false,
    this.verifiedField,
    this.icon = Icons.description_outlined,
  });

  /// The multipart form field this file is posted as.
  final String field;

  final String label;
  final String hint;

  /// Blocks submission until attached.
  final bool required;

  /// The flag on the KYC record that says our team has checked it. Null when
  /// the backend keeps no separate flag for this slot.
  final String? verifiedField;

  final IconData icon;
}

/// Every document the KYC record accepts, grouped as a teacher thinks about
/// them.
///
/// The app used to offer three of these. The rest were uploadable only on the
/// website even though `POST /api/users/kyc/upload/` has always accepted every
/// field — and several of them feed the qualification score.
class KycDocuments {
  const KycDocuments._();

  /// Proof of who they are. Aadhaar is the only hard requirement.
  static const identity = <KycDoc>[
    KycDoc(
      'aadhaar_front',
      'Aadhaar — front',
      'The side with your photo',
      required: true,
      verifiedField: 'aadhaar_front_verified',
      icon: Icons.badge_outlined,
    ),
    KycDoc(
      'aadhaar_back',
      'Aadhaar — back',
      'The side with your address',
      required: true,
      verifiedField: 'aadhaar_back_verified',
      icon: Icons.badge_outlined,
    ),
    KycDoc(
      'pan_document',
      'PAN card',
      'Needed before we can pay you',
      verifiedField: 'pan_verified',
      icon: Icons.credit_card_outlined,
    ),
    KycDoc(
      'passport_document',
      'Passport',
      'Optional — an alternative address proof',
      icon: Icons.book_outlined,
    ),
    KycDoc(
      'police_verification',
      'Police verification',
      'Optional, but families trust it',
      icon: Icons.local_police_outlined,
    ),
  ];

  /// Degrees and marksheets. These feed the qualification part of the score.
  static const academic = <KycDoc>[
    KycDoc(
      'highest_qualification_certificate',
      'Highest qualification',
      'Degree or marksheet — speeds up approval',
      verifiedField: 'qualification_verified',
      icon: Icons.school_outlined,
    ),
    KycDoc(
      'intermediate_certificate',
      '12th / Intermediate',
      'Marksheet or passing certificate',
      verifiedField: 'intermediate_certificate_verified',
      icon: Icons.school_outlined,
    ),
    KycDoc(
      'graduation_certificate',
      'Graduation',
      'Degree certificate',
      verifiedField: 'graduation_certificate_verified',
      icon: Icons.school_outlined,
    ),
    KycDoc(
      'post_grad_certificate',
      'Post-graduation',
      'Degree certificate',
      verifiedField: 'post_grad_certificate_verified',
      icon: Icons.school_outlined,
    ),
  ];

  /// Teaching qualifications. Each verified one lifts the score.
  static const professional = <KycDoc>[
    KycDoc('bed_certificate', 'B.Ed', 'Bachelor of Education',
        verifiedField: 'bed_certificate_verified',
        icon: Icons.workspace_premium_outlined),
    KycDoc('btc_certificate', 'BTC / D.El.Ed', 'Elementary education',
        verifiedField: 'btc_certificate_verified',
        icon: Icons.workspace_premium_outlined),
    KycDoc('tet_certificate', 'TET', 'State eligibility test',
        verifiedField: 'tet_certificate_verified',
        icon: Icons.workspace_premium_outlined),
    KycDoc('ctet_certificate', 'CTET', 'Central eligibility test',
        verifiedField: 'ctet_certificate_verified',
        icon: Icons.workspace_premium_outlined),
    KycDoc('net_certificate', 'NET', 'National eligibility test',
        verifiedField: 'net_certificate_verified',
        icon: Icons.workspace_premium_outlined),
    KycDoc('mphil_certificate', 'M.Phil', 'Research degree',
        verifiedField: 'mphil_certificate_verified',
        icon: Icons.workspace_premium_outlined),
    KycDoc('phd_certificate', 'PhD', 'Doctorate',
        verifiedField: 'phd_certificate_verified',
        icon: Icons.workspace_premium_outlined),
    KycDoc('subject_diploma_certificate', 'Subject diploma',
        'Diploma in the subject you teach',
        verifiedField: 'subject_diploma_certificate_verified',
        icon: Icons.workspace_premium_outlined),
    KycDoc('teaching_certificate', 'Other teaching certificate',
        'Anything else that proves you can teach',
        icon: Icons.workspace_premium_outlined),
  ];

  static const all = [...identity, ...academic, ...professional];

  static List<KycDoc> get requiredDocs =>
      all.where((d) => d.required).toList();
}
