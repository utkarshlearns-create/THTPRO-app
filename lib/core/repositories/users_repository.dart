import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tht_app/core/models/app_user.dart';
import 'package:tht_app/core/models/kyc_status.dart';
import 'package:tht_app/core/models/paginated.dart';
import 'package:tht_app/core/models/public_tutor.dart';
import 'package:tht_app/core/models/tutor_profile.dart';
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

  /// The teacher's own profile.
  Future<TutorProfile> tutorProfile() async =>
      TutorProfile.fromJson(await getMap('/api/users/profile/'));

  /// Patches only the fields that changed, so a partial edit never blanks a
  /// field the app doesn't model.
  Future<TutorProfile> updateTutorProfile(Map<String, dynamic> changes) async =>
      TutorProfile.fromJson(await patchMap('/api/users/profile/', body: changes));

  /// Where the teacher stands in KYC — drives the verification banner.
  Future<KycStatus> kycStatus() async =>
      KycStatus.fromJson(await getMap('/api/users/kyc/status/'));

  /// Submits KYC documents for review.
  ///
  /// [documents] maps a backend field name (`aadhaar_front`,
  /// `highest_qualification_certificate`, …) to a local file path. The API
  /// accepts images only — PDFs are rejected server-side — and requires both
  /// sides of the Aadhaar on a first submission.
  Future<KycStatus> submitKyc(Map<String, String> documents) => guard(() async {
        final form = FormData();
        for (final entry in documents.entries) {
          form.files.add(
            MapEntry(entry.key, await MultipartFile.fromFile(entry.value)),
          );
        }
        final res = await dio.post('/api/users/kyc/upload/', data: form);
        final data = res.data;
        return KycStatus.fromJson(
          data is Map ? data.cast<String, dynamic>() : const {},
        );
      });

  /// Adds or replaces one supplementary certificate without resubmitting the
  /// whole KYC record, so a verified teacher can fill a gap without going back
  /// into review.
  Future<void> uploadKycDocument({
    required String field,
    required String filePath,
  }) =>
      guard(() async {
        final form = FormData();
        form.files.add(MapEntry(field, await MultipartFile.fromFile(filePath)));
        await dio.patch('/api/users/kyc/document/', data: form);
      });

  /// Records acceptance of the Terms & Conditions, which KYC submission
  /// requires before it will accept any documents.
  Future<void> acceptTerms() async {
    await patchMap('/api/users/profile/', body: {'terms_accepted': true});
  }

  /// Leads this teacher has already spent credits to see.
  Future<List<Map<String, dynamic>>> unlockedLeads() =>
      getList('/api/users/dashboard/unlocked-leads/');

  /// Teacher contacts this parent has already unlocked.
  Future<List<PublicTutor>> unlockedContacts() async =>
      (await getList('/api/users/dashboard/unlocked-contacts/'))
          .map(PublicTutor.fromJson)
          .toList();

  /// Spends a credit to reveal a teacher's phone and WhatsApp number.
  Future<Map<String, dynamic>> unlockTutorContact(int tutorId) =>
      postMap('/api/users/tutor/$tutorId/unlock/');

  Future<List<PublicTutor>> favouriteTutors() async =>
      (await getList('/api/users/dashboard/favourite-tutors/'))
          .map(PublicTutor.fromJson)
          .toList();

  /// Adds or removes a teacher from the parent's saved list.
  Future<Map<String, dynamic>> toggleFavourite(int tutorId) =>
      postMap('/api/users/tutors/$tutorId/favourite/');

  /// A teacher's full public profile.
  Future<PublicTutor> tutorDetail(int tutorId) async =>
      PublicTutor.fromJson(await getMap('/api/users/tutors/$tutorId/'));

  /// Searches active teachers. Public — works before sign-in too.
  Future<Paginated<PublicTutor>> searchTutors({
    Map<String, dynamic>? filters,
    int page = 1,
    CancelToken? cancelToken,
  }) =>
      guard(() async {
        final res = await dio.get(
          '/api/users/tutors/search/',
          queryParameters: {...?filters, 'page': page},
          cancelToken: cancelToken,
        );
        return Paginated.fromJson(res.data, PublicTutor.fromJson, page: page);
      });

  /// The curated teachers shown on the home screen.
  Future<List<PublicTutor>> featuredTutors() async =>
      (await getList('/api/users/tutors/featured/'))
          .map(PublicTutor.fromJson)
          .toList();

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
