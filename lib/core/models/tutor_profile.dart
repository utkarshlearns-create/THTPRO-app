import 'package:tht_app/core/utils/json_x.dart';

/// The teacher's own profile, from `GET /api/users/profile/`.
///
/// Only the fields the app edits are modelled as named properties. The full
/// record carries about ninety, most of them a three-level education timeline
/// with marks validation that belongs on a laptop; [raw] keeps the rest
/// available for read-only display without pretending the app owns it.
class TutorProfile {
  const TutorProfile({
    required this.id,
    this.fullName = '',
    this.gender = '',
    this.dob,
    this.aboutMe = '',
    this.whatsappNumber = '',
    this.alternateNumber = '',
    this.state = '',
    this.city = '',
    this.locality = '',
    this.pincode = '',
    this.teachingMode = '',
    this.experienceYears = 0,
    this.expectedFee,
    this.subjects = const [],
    this.classes = const [],
    this.classSubjects = const {},
    this.isEligible = true,
    this.ineligibleReason,
    this.availableTimeSlots = const [],
    this.preferredBoards = const [],
    this.preferredLocations = const [],
    this.highestQualification = '',
    this.completionPercentage = 0,
    this.openToInstituteJobs = false,
    this.allowDirectContactUnlock = false,
    this.termsAccepted = false,
    this.imageUrl,
    this.introVideoUrl,
    this.raw = const {},
  });

  final int id;
  final String fullName;

  /// `Male`, `Female` or blank. Gender-specific jobs cannot be applied to while
  /// this is blank, so it is worth prompting for.
  final String gender;

  final DateTime? dob;
  final String aboutMe;
  final String whatsappNumber;
  final String alternateNumber;
  final String state;
  final String city;
  final String locality;
  final String pincode;

  /// `HOME`, `ONLINE`, `BOTH`.
  final String teachingMode;

  final int experienceYears;
  final double? expectedFee;

  /// Read-only on this endpoint — the server derives both from
  /// [classSubjects], which is the field to write.
  final List<String> subjects;
  final List<String> classes;

  /// What the teacher teaches, as `{class: [subjects]}`.
  ///
  /// This is the writable shape. `subjects` and `classes` are in the
  /// serializer's `read_only_fields`, so a PATCH of either is silently
  /// discarded — editing has to go through here.
  final Map<String, List<String>> classSubjects;

  final List<String> preferredBoards;
  final List<String> preferredLocations;

  /// When the teacher is free, e.g. `Weekday evenings`.
  final List<String> availableTimeSlots;
  final String highestQualification;

  /// The backend's own completeness score, 0–100.
  final int completionPercentage;

  final bool openToInstituteJobs;

  /// Whether a teacher lets counsellors hand their number straight to parents.
  final bool allowDirectContactUnlock;

  final bool termsAccepted;
  final String? imageUrl;

  /// A short clip families watch before deciding. Null until one is uploaded.
  final String? introVideoUrl;

  /// Whether this teacher may apply for jobs at all.
  ///
  /// A curation gate, not a ban: an ineligible teacher signs in, browses,
  /// edits their profile and uses their wallet exactly as before — only
  /// applying is closed to them, on every job rather than a particular one.
  ///
  /// **Defaults to true, and only an explicit `false` blocks.** An older
  /// server omits the field entirely, and reading that absence as "barred"
  /// would lock every teacher out of the product.
  final bool isEligible;

  /// Why an admin marked them ineligible, when they recorded one. Null or
  /// empty is normal — the reason is optional on the admin's side.
  final String? ineligibleReason;

  /// Everything the API returned, for fields the app shows but does not edit.
  final Map<String, dynamic> raw;

  /// True when the profile is complete enough to compete for leads well.
  bool get isWellFilled => completionPercentage >= 80;

  /// What the teacher should fix next, or null when nothing is missing.
  String? get weakestSpot {
    if (gender.trim().isEmpty) {
      return 'Add your gender — gender-specific jobs cannot be applied to '
          'without it.';
    }
    if (aboutMe.trim().length < 40) {
      return 'Write a few lines about how you teach. Families read this first.';
    }
    if (subjects.isEmpty) return 'Add the subjects you teach.';
    if (expectedFee == null || expectedFee == 0) {
      return 'Set your expected monthly fee so you are matched to the right '
          'budgets.';
    }
    if (preferredLocations.isEmpty) {
      return 'Add the areas you can travel to.';
    }
    return null;
  }

  /// `{"Class 10": ["Maths", "Science"]}`, tolerating the shapes the field has
  /// held over time: a missing value, a class with no subjects yet, or a single
  /// subject stored as a bare string rather than a list.
  static Map<String, List<String>> _classSubjects(Object? raw) {
    if (raw is! Map) return const {};
    final out = <String, List<String>>{};
    raw.forEach((key, value) {
      final name = key.toString().trim();
      if (name.isEmpty) return;
      if (value is List) {
        out[name] = value
            .map((s) => s.toString().trim())
            .where((s) => s.isNotEmpty)
            .toList();
      } else if (value is String && value.trim().isNotEmpty) {
        out[name] = [value.trim()];
      } else {
        out[name] = const [];
      }
    });
    return out;
  }

  factory TutorProfile.fromJson(Map<String, dynamic> json) => TutorProfile(
        id: asInt(json, 'id'),
        fullName: asString(json, 'full_name'),
        gender: asString(json, 'gender'),
        dob: asDateOrNull(json, 'dob'),
        aboutMe: asString(json, 'about_me'),
        whatsappNumber: asString(json, 'whatsapp_number'),
        alternateNumber: asString(json, 'alternate_number'),
        state: asString(json, 'state'),
        city: asString(json, 'city'),
        locality: asString(json, 'locality'),
        pincode: asString(json, 'pincode'),
        teachingMode: asString(json, 'teaching_mode'),
        experienceYears: asInt(json, 'teaching_experience_years'),
        expectedFee: asDoubleOrNull(json, 'expected_fee'),
        subjects: asStringList(json, 'subjects'),
        classes: asStringList(json, 'classes'),
        classSubjects: _classSubjects(json['class_subjects']),
        // Only an explicit false bars anyone.
        isEligible: json['is_eligible'] != false,
        ineligibleReason: asStringOrNull(json, 'ineligible_reason'),
        preferredBoards: asStringList(json, 'preferred_boards'),
        preferredLocations: asStringList(json, 'preferred_locations'),
        availableTimeSlots: asStringList(json, 'available_time_slots'),
        highestQualification: asString(json, 'highest_qualification'),
        completionPercentage: asInt(json, 'profile_completion_percentage'),
        openToInstituteJobs: asBool(json, 'open_to_institute_jobs'),
        allowDirectContactUnlock: asBool(json, 'allow_direct_contact_unlock'),
        termsAccepted: asBool(json, 'terms_accepted'),
        imageUrl: asStringOrNull(json, 'image') ??
            asStringOrNull(json, 'external_profile_image_url'),
        introVideoUrl: asStringOrNull(json, 'intro_video'),
        raw: json,
      );
}
