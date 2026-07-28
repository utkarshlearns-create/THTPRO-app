/// User roles — mirrors the Django/Next.js role strings stored in the JWT.
///
/// Lives in its own file so models can name a role without importing the whole
/// auth notifier, which would import the repositories, which import the models.
enum UserRole {
  parent('PARENT'),
  teacher('TEACHER'),
  counsellor('COUNSELLOR'),
  tutorAdmin('TUTOR_ADMIN'),
  teamLeader('TEAM_LEADER'),
  superadmin('SUPERADMIN'),
  institution('INSTITUTION'),
  student('STUDENT');

  const UserRole(this.value);
  final String value;

  static UserRole? fromString(String? s) {
    if (s == null) return null;
    final upper = s.toUpperCase();
    return UserRole.values.cast<UserRole?>().firstWhere(
          (r) => r!.value == upper,
          orElse: () => null,
        );
  }

  /// The three audiences this app is built for. Counsellors, team leaders and
  /// superadmins keep working on thehometuitions.com — their tools are
  /// desk-shaped, not phone-shaped, so the app sends them there instead of
  /// shipping a worse version of the same screens.
  bool get isSupportedInApp =>
      this == UserRole.parent ||
      this == UserRole.teacher ||
      this == UserRole.institution;

  /// How to refer to this role in copy shown to the user.
  String get label {
    switch (this) {
      case UserRole.parent:
        return 'Parent';
      case UserRole.teacher:
        return 'Teacher';
      case UserRole.institution:
        return 'Institute';
      case UserRole.counsellor:
        return 'Counsellor';
      case UserRole.tutorAdmin:
        return 'Tutor admin';
      case UserRole.teamLeader:
        return 'Team leader';
      case UserRole.superadmin:
        return 'Superadmin';
      case UserRole.student:
        return 'Student';
    }
  }
}
