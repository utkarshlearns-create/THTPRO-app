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
    this.preferredBoards = const [],
    this.preferredLocations = const [],
    this.highestQualification = '',
    this.completionPercentage = 0,
    this.openToInstituteJobs = false,
    this.allowDirectContactUnlock = false,
    this.termsAccepted = false,
    this.imageUrl,
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

  /// Read-only on this endpoint — changed through the website's subject picker.
  final List<String> subjects;
  final List<String> classes;

  final List<String> preferredBoards;
  final List<String> preferredLocations;
  final String highestQualification;

  /// The backend's own completeness score, 0–100.
  final int completionPercentage;

  final bool openToInstituteJobs;

  /// Whether a teacher lets counsellors hand their number straight to parents.
  final bool allowDirectContactUnlock;

  final bool termsAccepted;
  final String? imageUrl;

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
        preferredBoards: asStringList(json, 'preferred_boards'),
        preferredLocations: asStringList(json, 'preferred_locations'),
        highestQualification: asString(json, 'highest_qualification'),
        completionPercentage: asInt(json, 'profile_completion_percentage'),
        openToInstituteJobs: asBool(json, 'open_to_institute_jobs'),
        allowDirectContactUnlock: asBool(json, 'allow_direct_contact_unlock'),
        termsAccepted: asBool(json, 'terms_accepted'),
        imageUrl: asStringOrNull(json, 'image') ??
            asStringOrNull(json, 'external_profile_image_url'),
        raw: json,
      );
}
