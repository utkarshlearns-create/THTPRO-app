import 'package:tht_app/core/auth/auth_provider.dart';
import 'package:tht_app/core/utils/json_x.dart';

/// The signed-in user, as returned by `GET /api/users/me/`.
///
/// This is the same account record the website serves, so a parent who signed
/// up on thehometuitions.com sees their own jobs and wallet here with no extra
/// step.
class AppUser {
  const AppUser({
    required this.id,
    required this.role,
    this.username = '',
    this.firstName = '',
    this.email,
    this.phone,
    this.city,
    this.area,
    this.address,
    this.profilePicture,
    this.hasCompletedOnboardingTour = false,
    this.hasChangedRole = false,
    this.tutorProfile,
    this.institutionProfile,
  });

  final int id;
  final UserRole? role;
  final String username;
  final String firstName;
  final String? email;
  final String? phone;
  final String? city;
  final String? area;
  final String? address;
  final String? profilePicture;
  final bool hasCompletedOnboardingTour;
  final bool hasChangedRole;

  /// Present for teachers. Raw map — the teacher screens read what they need.
  final Map<String, dynamic>? tutorProfile;

  /// Present for institutes.
  final Map<String, dynamic>? institutionProfile;

  /// What to greet them with. Falls back through the fields the backend fills
  /// depending on how the account was created (web signup, OTP, Google).
  String get displayName {
    for (final candidate in [firstName, username, phone]) {
      final s = (candidate ?? '').trim();
      if (s.isNotEmpty) return s;
    }
    return 'there';
  }

  bool get isTeacher => role == UserRole.teacher;
  bool get isParent => role == UserRole.parent;
  bool get isInstitution => role == UserRole.institution;

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: asInt(json, 'id'),
        role: UserRole.fromString(asStringOrNull(json, 'role')),
        username: asString(json, 'username'),
        firstName: asString(json, 'first_name'),
        email: asStringOrNull(json, 'email'),
        phone: asStringOrNull(json, 'phone'),
        city: asStringOrNull(json, 'city'),
        area: asStringOrNull(json, 'area'),
        address: asStringOrNull(json, 'address'),
        profilePicture: asStringOrNull(json, 'profile_picture'),
        hasCompletedOnboardingTour: asBool(json, 'has_completed_onboarding_tour'),
        hasChangedRole: asBool(json, 'has_changed_role'),
        tutorProfile: asMapOrNull(json, 'tutor_profile'),
        institutionProfile: asMapOrNull(json, 'institution_profile'),
      );
}
