import 'package:tht_app/core/utils/json_x.dart';

/// A teacher as a parent sees them.
///
/// Served by tutor search, tutor detail, and embedded as `tutor_details` on an
/// application. The phone and WhatsApp are gated: [contact] is null until this
/// parent has spent a credit on this teacher, so the absence is the lock.
class PublicTutor {
  const PublicTutor({
    required this.id,
    this.name = '',
    this.gender = '',
    this.age,
    this.aboutMe = '',
    this.subjects = const [],
    this.classes = const [],
    this.state = '',
    this.city = '',
    this.locality = '',
    this.preferredLocations = const [],
    this.preferredBoards = const [],
    this.availableTimeSlots = const [],
    this.teachingMode = '',
    this.experienceYears = 0,
    this.expectedFee,
    this.highestQualification = '',
    this.isBed = false,
    this.isTet = false,
    this.completionPercentage = 0,
    this.imageUrl,
    this.introVideoUrl,
    this.isUnlocked = false,
    this.isFavourite = false,
    this.contact,
    this.ongoingTuitions = 0,
    this.scheduledDemos = 0,
    this.reviews = const [],
    this.avgRating,
    this.ratingCount = 0,
    this.ratingBreakdown = const {},
    this.isKycVerified = false,
    this.memberSince,
  });

  final int id;
  final String name;
  final String gender;
  final int? age;
  final String aboutMe;
  final List<String> subjects;
  final List<String> classes;
  final String state;
  final String city;
  final String locality;
  final List<String> preferredLocations;
  final List<String> preferredBoards;
  final List<String> availableTimeSlots;
  final String teachingMode;
  final int experienceYears;
  final double? expectedFee;
  final String highestQualification;
  final bool isBed;
  final bool isTet;
  final int completionPercentage;
  final String? imageUrl;
  final String? introVideoUrl;

  /// True once this parent has unlocked the teacher's contact.
  final bool isUnlocked;

  final bool isFavourite;

  /// Phone, email and WhatsApp — null while locked.
  final TutorContact? contact;

  /// How many tuitions the teacher is currently running. High numbers are a
  /// signal of demand, but also of limited availability.
  final int ongoingTuitions;

  final int scheduledDemos;
  final List<TutorReview> reviews;

  /// Null when no parent has rated them yet. Never substitute a default — a
  /// fabricated rating is worse than an honest absence.
  final double? avgRating;

  final int ratingCount;

  /// Per-star counts, for the distribution bars.
  final Map<int, int> ratingBreakdown;

  final bool isKycVerified;
  final DateTime? memberSince;

  bool get hasRatings => avgRating != null && ratingCount > 0;

  /// `8 years experience · M.Sc · Gomti Nagar`
  String get credentialLine => [
        if (experienceYears > 0)
          '$experienceYears ${experienceYears == 1 ? 'year' : 'years'} experience',
        if (highestQualification.trim().isNotEmpty) highestQualification,
        if (locality.trim().isNotEmpty) locality,
      ].join(' · ');

  /// How the teacher delivers tuition, in a parent's words.
  String get modeLabel {
    switch (teachingMode.toUpperCase()) {
      case 'HOME':
        return 'Comes to your home';
      case 'ONLINE':
        return 'Teaches online';
      case 'BOTH':
        return 'Home or online';
      default:
        return teachingMode;
    }
  }

  factory PublicTutor.fromJson(Map<String, dynamic> json) {
    final contactMap = asMapOrNull(json, 'contact_info');
    final breakdown = asMapOrNull(json, 'rating_breakdown') ?? const {};

    return PublicTutor(
      id: asInt(json, 'id'),
      name: asString(json, 'name'),
      gender: asString(json, 'gender'),
      age: asIntOrNull(json, 'age'),
      aboutMe: asString(json, 'about_me'),
      subjects: asStringList(json, 'subjects'),
      classes: asStringList(json, 'classes'),
      state: asString(json, 'state'),
      city: asString(json, 'city'),
      locality: asString(json, 'locality'),
      preferredLocations: asStringList(json, 'preferred_locations'),
      preferredBoards: asStringList(json, 'preferred_boards'),
      availableTimeSlots: asStringList(json, 'available_time_slots'),
      teachingMode: asString(json, 'teaching_mode'),
      experienceYears: asInt(json, 'teaching_experience_years'),
      expectedFee: asDoubleOrNull(json, 'expected_fee'),
      highestQualification: asString(json, 'highest_qualification'),
      isBed: asBool(json, 'is_bed'),
      isTet: asBool(json, 'is_tet'),
      completionPercentage: asInt(json, 'profile_completion_percentage'),
      imageUrl: asStringOrNull(json, 'image'),
      introVideoUrl: asStringOrNull(json, 'intro_video'),
      isUnlocked: asBool(json, 'is_unlocked'),
      isFavourite: asBool(json, 'is_favourite'),
      contact: contactMap == null ? null : TutorContact.fromJson(contactMap),
      ongoingTuitions: asInt(json, 'ongoing_tuitions_count'),
      scheduledDemos: asInt(json, 'scheduled_demos_count'),
      reviews: asMapList(json, 'reviews').map(TutorReview.fromJson).toList(),
      avgRating: asDoubleOrNull(json, 'avg_rating'),
      ratingCount: asInt(json, 'rating_count'),
      ratingBreakdown: {
        for (final entry in breakdown.entries)
          if (int.tryParse(entry.key) case final star?)
            star: entry.value is num
                ? (entry.value as num).toInt()
                : int.tryParse('${entry.value}') ?? 0,
      },
      isKycVerified: asBool(json, 'is_kyc_verified'),
      memberSince: asDateOrNull(json, 'member_since'),
    );
  }
}

/// A teacher's contact details, present only once unlocked.
class TutorContact {
  const TutorContact({this.phone, this.email, this.whatsapp});

  final String? phone;
  final String? email;
  final String? whatsapp;

  bool get isEmpty => phone == null && whatsapp == null && email == null;

  factory TutorContact.fromJson(Map<String, dynamic> json) => TutorContact(
        phone: asStringOrNull(json, 'phone'),
        email: asStringOrNull(json, 'email'),
        whatsapp: asStringOrNull(json, 'whatsapp'),
      );
}

/// A written review from a parent who actually hired this teacher.
class TutorReview {
  const TutorReview({
    this.name = 'Verified Parent',
    this.role = '',
    this.rating = 0,
    this.text = '',
    this.at,
  });

  final String name;

  /// e.g. `Parent · Class 10`.
  final String role;

  final int rating;
  final String text;
  final DateTime? at;

  factory TutorReview.fromJson(Map<String, dynamic> json) => TutorReview(
        name: asString(json, 'name', fallback: 'Verified Parent'),
        role: asString(json, 'role'),
        rating: asInt(json, 'rating'),
        text: asString(json, 'text'),
        at: asDateOrNull(json, 'created_at'),
      );
}
