/// The controlled vocabularies behind a teacher's education record.
///
/// Every key here is a value the Django `TextChoices` will accept; sending
/// anything else is a 400. Kept in one place so the pickers and the payload
/// cannot drift apart.
class Education {
  const Education._();

  /// How marks were recorded. Which of the three grade inputs is shown depends
  /// on this, and so does what the server validates.
  static const gradeTypes = <String, String>{
    'PERCENTAGE': 'Percentage',
    'CGPA_10': 'CGPA (out of 10)',
    'CGPA_4': 'CGPA (out of 4)',
    'GRADE': 'Letter grade',
  };

  /// The CGPA ceiling the server enforces for a grade type, or null when the
  /// type is not a CGPA at all.
  static double? cgpaLimit(String? gradeType) => switch (gradeType) {
        'CGPA_10' => 10,
        'CGPA_4' => 4,
        _ => null,
      };

  static const gradStatuses = <String, String>{
    'PURSUING': 'Pursuing',
    'COMPLETED': 'Completed',
    'DROPPED': 'Dropped',
  };

  static const postGradStatuses = <String, String>{
    'NA': 'Not applicable',
    'PURSUING': 'Pursuing',
    'COMPLETED': 'Completed',
  };

  static const gradDegrees = <String, String>{
    'BA': 'B.A',
    'BSC': 'B.Sc',
    'BCOM': 'B.Com',
    'BTECH': 'B.Tech',
    'BE': 'B.E',
    'BED': 'B.Ed',
    'BBA': 'BBA',
    'BCA': 'BCA',
    'BARCH': 'B.Arch',
    'MBBS': 'MBBS',
    'BDS': 'BDS',
    'BAMS': 'BAMS',
    'BHMS': 'BHMS',
    'BPHARM': 'B.Pharm',
    'LLB': 'LLB',
    'BHM': 'BHM',
    'BFA': 'B.F.A',
    'BPED': 'B.P.Ed',
    'BSW': 'B.S.W',
    'BLIB': 'B.Lib',
    'OTHER': 'Other',
  };

  static const postGradDegrees = <String, String>{
    'MA': 'M.A',
    'MSC': 'M.Sc',
    'MCOM': 'M.Com',
    'MTECH': 'M.Tech',
    'ME': 'M.E',
    'MED': 'M.Ed',
    'MBA': 'MBA',
    'MCA': 'MCA',
    'MARCH': 'M.Arch',
    'MD': 'MD',
    'MS': 'MS',
    'MDS': 'MDS',
    'MPHARM': 'M.Pharm',
    'LLM': 'LLM',
    'MFA': 'M.F.A',
    'MPED': 'M.P.Ed',
    'MSW': 'M.S.W',
    'MLIB': 'M.Lib',
    'MPHIL': 'M.Phil',
    'PGDIP': 'PG Diploma',
    'OTHER': 'Other',
  };

  /// The teaching certifications a profile records, as `field → label`.
  static const certifications = <String, String>{
    'is_bed': 'B.Ed',
    'is_btc': 'BTC / D.El.Ed',
    'is_tet': 'TET',
    'is_ctet': 'CTET',
    'is_net': 'NET',
    'is_mphil': 'M.Phil',
    'is_phd': 'PhD',
    'is_subject_diploma': 'Subject diploma',
  };
}
