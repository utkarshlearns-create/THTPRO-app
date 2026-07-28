import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tht_app/core/models/app_user.dart';
import 'package:tht_app/core/models/tutor_stats.dart';
import 'package:tht_app/core/repositories/repository.dart';

/// Everything under `/api/users/` that a parent, teacher or institute needs.
class UsersRepository extends Repository {
  UsersRepository([super.dio]);

  /// The signed-in account — the same record the website's session returns.
  Future<AppUser> me() async => AppUser.fromJson(await getMap('/api/users/me/'));

  /// A teacher's applications, earnings and demo counts.
  Future<TutorStats> tutorStats() async =>
      TutorStats.fromJson(await getMap('/api/users/dashboard/stats/'));

  /// The teacher's own editable profile.
  Future<Map<String, dynamic>> tutorProfile() => getMap('/api/users/profile/');

  Future<Map<String, dynamic>> updateTutorProfile(Map<String, dynamic> changes) =>
      patchMap('/api/users/profile/', body: changes);

  /// Where the teacher stands in KYC — drives the verification banner.
  Future<Map<String, dynamic>> kycStatus() => getMap('/api/users/kyc/status/');

  /// Leads this teacher has already spent credits to see.
  Future<List<Map<String, dynamic>>> unlockedLeads() =>
      getList('/api/users/dashboard/unlocked-leads/');

  /// Teacher contacts this parent has already unlocked.
  Future<List<Map<String, dynamic>>> unlockedContacts() =>
      getList('/api/users/dashboard/unlocked-contacts/');

  /// Spends credits to reveal a teacher's phone and WhatsApp number.
  Future<Map<String, dynamic>> unlockTutorContact(int tutorId) =>
      postMap('/api/users/tutor/$tutorId/unlock/');

  Future<List<Map<String, dynamic>>> favouriteTutors() =>
      getList('/api/users/dashboard/favourite-tutors/');

  /// Adds or removes a teacher from the parent's saved list.
  Future<Map<String, dynamic>> toggleFavourite(int tutorId) =>
      postMap('/api/users/tutors/$tutorId/favourite/');

  /// A teacher's full public profile.
  Future<Map<String, dynamic>> tutorDetail(int tutorId) =>
      getMap('/api/users/tutors/$tutorId/');

  /// The curated teachers shown on the home screen.
  Future<List<Map<String, dynamic>>> featuredTutors() =>
      getList('/api/users/tutors/featured/');

  /// The institute's own profile record.
  Future<Map<String, dynamic>> institutionProfile() =>
      getMap('/api/users/institution/profile/');

  Future<Map<String, dynamic>> updateInstitutionProfile(
          Map<String, dynamic> changes) =>
      patchMap('/api/users/institution/profile/', body: changes);

  /// Teachers attached to this institute.
  Future<List<Map<String, dynamic>>> institutionTutors() =>
      getList('/api/users/institution/tutors/');
}

final usersRepositoryProvider =
    Provider<UsersRepository>((ref) => UsersRepository());
