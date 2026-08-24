import 'package:tht_app/core/utils/json_x.dart';

/// A tuition requirement — what a teacher browses and applies to.
///
/// The backend gates the parent's contact behind an unlock: `parent_phone` and
/// `parent_whatsapp_number` come back null until this teacher has spent a credit
/// on this job (or been hired for it). That absence is the signal the UI reads,
/// so there is no separate "unlocked" flag to keep in sync.
class Job {
  const Job({
    required this.id,
    this.studentName = '',
    this.additionalStudents = const [],
    this.classGrade = '',
    this.board = '',
    this.subjects = const [],
    this.locality = '',
    this.detailedAddress = '',
    this.mapLink = '',
    this.preferredTime = '',
    this.daysPerWeek = '',
    this.budgetRange = '',
    this.requirements = '',
    this.tuitionMode = '',
    this.tutorGenderPreference = '',
    this.status = '',
    this.leadSource = '',
    this.createdAt,
    this.repostedAt,
    this.applicationCount = 0,
    this.contactUnlockCount = 0,
    this.hasApplied = false,
    this.genderMismatch = false,
    this.isInstituteJob = false,
    this.isCompleted = false,
    this.parentName = 'Parent',
    this.parentPhone,
    this.parentWhatsapp,
  });

  final int id;

  /// Masked to a neutral label on institute leads until the contact is unlocked.
  final String studentName;

  /// Siblings sharing this requirement: `[{name, class_grade}]`.
  final List<Map<String, dynamic>> additionalStudents;

  final String classGrade;
  final String board;
  final List<String> subjects;
  final String locality;
  final String detailedAddress;

  /// A Google Maps link or `lat,lng`, so a teacher can judge the travel.
  final String mapLink;

  final String preferredTime;
  final String daysPerWeek;

  /// The teacher-facing fee, e.g. `4000-4500`. The parent's quoted fee is a
  /// separate field the API never sends to a teacher.
  final String budgetRange;

  final String requirements;

  /// `HOME`, `ONLINE_ONE_TO_ONE`, `ONLINE_GROUP`, `INSTITUTION`, `BOTH`.
  final String tuitionMode;

  /// `Male`, `Female` or `Any`.
  final String tutorGenderPreference;

  final String status;
  final String leadSource;
  final DateTime? createdAt;

  /// Set when the lead was put back in the feed; newer than [createdAt].
  final DateTime? repostedAt;

  final int applicationCount;

  /// How many teachers have already paid to see this parent.
  final int contactUnlockCount;

  final bool hasApplied;

  /// True when the parent asked for a teacher of the other gender.
  final bool genderMismatch;

  final bool isInstituteJob;
  final bool isCompleted;
  final String parentName;

  /// Null until this teacher unlocks the contact.
  final String? parentPhone;
  final String? parentWhatsapp;

  /// Whether this teacher has already paid to see the parent behind this lead.
  bool get isContactUnlocked => parentPhone != null || parentWhatsapp != null;

  /// When it entered the feed — a repost counts as fresh.
  DateTime? get postedAt => repostedAt ?? createdAt;

  /// Every child on this lead, the named one first.
  List<String> get allStudents => [
        if (studentName.isNotEmpty) studentName,
        ...additionalStudents
            .map((s) => asString(s, 'name'))
            .where((n) => n.isNotEmpty),
      ];

  bool get isMultiChild => additionalStudents.isNotEmpty;

  /// `Class 10 · CBSE · Maths, Science`
  String get summaryLine => [
        if (classGrade.isNotEmpty) classGrade,
        if (board.isNotEmpty) board,
        if (subjects.isNotEmpty) subjects.join(', '),
      ].join(' · ');

  /// How the tuition is delivered, in words a teacher uses.
  String get modeLabel {
    switch (tuitionMode.toUpperCase()) {
      case 'HOME':
        return 'At home';
      case 'ONLINE_ONE_TO_ONE':
        return 'Online, one-to-one';
      case 'ONLINE_GROUP':
        return 'Online, group';
      case 'INSTITUTION':
        return 'At a centre';
      case 'BOTH':
        return 'Home or online';
      default:
        return tuitionMode;
    }
  }

  /// `₹4,000–4,500 / month`, or null when no budget was recorded.
  ///
  /// `budget_range` is not a structured field. Depending on where the
  /// requirement was posted it arrives as a bare range (`4000-4500`), as a
  /// sentence the wizard composed (`₹6,500 - ₹7,000 / month (2 days a week)`),
  /// or as prose (`Negotiable based on requirements`).
  ///
  /// So the numbers are *extracted*, never derived by deleting the other
  /// characters. Stripping non-digits from the sentence form concatenated every
  /// figure in it — 6,500 and 7,000 and the 2 from "2 days" became a fee of
  /// ₹65,00,70,002 a month.
  String? get feeLabel {
    final raw = budgetRange.trim();
    if (raw.isEmpty) return null;

    final amounts = _amountsIn(raw);
    // Nothing numeric to show — "Negotiable based on requirements" is a real
    // answer, so pass it through rather than inventing a figure.
    if (amounts.isEmpty) return raw;

    if (amounts.length == 1 || amounts.first == amounts.last) {
      return '₹${_grouped(amounts.first)} / month';
    }
    return '₹${_grouped(amounts.first)}–${_grouped(amounts.last)} / month';
  }

  /// The plausible money figures in [text], smallest first.
  ///
  /// Digit groups under 100 are dropped: they are the day counts, subject
  /// counts and child counts that share the sentence with the fee, and no
  /// monthly tuition is ₹6. Only the lowest and highest survive, so a stray
  /// third figure cannot widen the range.
  static List<int> _amountsIn(String text) {
    final found = RegExp(r'\d[\d,]*')
        .allMatches(text)
        .map((m) => int.tryParse(m.group(0)!.replaceAll(',', '')))
        .whereType<int>()
        .where((n) => n >= 100)
        .toList()
      ..sort();

    if (found.isEmpty) return const [];
    return [found.first, found.last];
  }

  /// Indian digit grouping without pulling in intl for one label.
  static String _grouped(int n) {
    final s = n.toString();
    if (s.length <= 3) return s;
    final last3 = s.substring(s.length - 3);
    var rest = s.substring(0, s.length - 3);
    final buf = <String>[];
    while (rest.length > 2) {
      buf.insert(0, rest.substring(rest.length - 2));
      rest = rest.substring(0, rest.length - 2);
    }
    if (rest.isNotEmpty) buf.insert(0, rest);
    return '${buf.join(',')},$last3';
  }

  factory Job.fromJson(Map<String, dynamic> json) => Job(
        id: asInt(json, 'id'),
        studentName: asString(json, 'student_name'),
        additionalStudents: asMapList(json, 'additional_students'),
        classGrade: asString(json, 'class_grade'),
        board: asString(json, 'board'),
        subjects: asStringList(json, 'subjects'),
        locality: asString(json, 'locality'),
        detailedAddress: asString(json, 'detailed_address'),
        mapLink: asString(json, 'map_link'),
        preferredTime: asString(json, 'preferred_time'),
        daysPerWeek: asString(json, 'days_per_week'),
        budgetRange: asString(json, 'budget_range'),
        requirements: asString(json, 'requirements'),
        tuitionMode: asString(json, 'tuition_mode'),
        tutorGenderPreference: asString(json, 'tutor_gender_preference'),
        status: asString(json, 'status'),
        leadSource: asString(json, 'lead_source'),
        createdAt: asDateOrNull(json, 'created_at'),
        repostedAt: asDateOrNull(json, 'reposted_at'),
        applicationCount: asInt(json, 'application_count'),
        contactUnlockCount: asInt(json, 'contact_unlock_count'),
        hasApplied: asBool(json, 'has_applied'),
        genderMismatch: asBool(json, 'gender_mismatch'),
        isInstituteJob: asBool(json, 'is_institute_job'),
        isCompleted: asBool(json, 'is_completed'),
        parentName: asString(json, 'parent_name', fallback: 'Parent'),
        parentPhone: asStringOrNull(json, 'parent_phone'),
        parentWhatsapp: asStringOrNull(json, 'parent_whatsapp_number'),
      );
}
