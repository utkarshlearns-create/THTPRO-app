import 'package:tht_app/core/utils/json_x.dart';

/// A school or coaching centre's profile, from
/// `GET /api/users/institution/profile/`.
class InstitutionProfile {
  const InstitutionProfile({
    required this.id,
    this.name = '',
    this.contactPerson = '',
    this.establishedYear,
    this.address = '',
    this.website = '',
    this.about = '',
    this.logoUrl,
    this.isVerified = false,
    this.createdAt,
  });

  final int id;
  final String name;

  /// Who to speak to. Masked from teachers until they are connected.
  final String contactPerson;

  final int? establishedYear;
  final String address;
  final String website;
  final String about;
  final String? logoUrl;

  /// Set by the THT team once the institute has been checked.
  final bool isVerified;

  final DateTime? createdAt;

  bool get hasName => name.trim().isNotEmpty;

  /// What is still missing before the profile reads as credible to a teacher.
  String? get weakestSpot {
    if (!hasName) return 'Add your institute name so teachers know who is hiring.';
    if (contactPerson.trim().isEmpty) {
      return 'Add a contact person so our team knows who to reach.';
    }
    if (address.trim().isEmpty) {
      return 'Add your address so nearby teachers can judge the travel.';
    }
    if (about.trim().length < 40) {
      return 'Write a few lines about your institute. Teachers read this before applying.';
    }
    return null;
  }

  factory InstitutionProfile.fromJson(Map<String, dynamic> json) =>
      InstitutionProfile(
        id: asInt(json, 'id'),
        name: asString(json, 'institution_name'),
        contactPerson: asString(json, 'contact_person'),
        establishedYear: asIntOrNull(json, 'established_year'),
        address: asString(json, 'address'),
        website: asString(json, 'website'),
        about: asString(json, 'about'),
        logoUrl: asStringOrNull(json, 'logo'),
        isVerified: asBool(json, 'is_verified'),
        createdAt: asDateOrNull(json, 'created_at'),
      );
}
