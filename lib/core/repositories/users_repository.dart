import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tht_app/core/models/app_user.dart';
import 'package:tht_app/core/models/institution_profile.dart';
import 'package:tht_app/core/models/kyc_status.dart';
import 'package:tht_app/core/models/paginated.dart';
import 'package:tht_app/core/models/public_tutor.dart';
import 'package:tht_app/core/models/tutor_profile.dart';
import 'package:tht_app/core/models/tutor_score.dart';
import 'package:tht_app/core/models/tutor_stats.dart';
import 'package:tht_app/core/models/unlocked_lead.dart';
import 'package:tht_app/core/models/upload_file.dart';
import 'package:tht_app/core/utils/api_error.dart';
import 'package:tht_app/core/repositories/repository.dart';

/// Everything under `/api/users/` that a parent, teacher or institute needs.
class UsersRepository extends Repository {
  UsersRepository([super.dio]);

  /// The signed-in account — the same record the website's session returns.
  Future<AppUser> me() async => AppUser.fromJson(await getMap('/api/users/me/'));

  /// Patches the signed-in account.
  ///
  /// `PATCH /api/users/me/` is role-agnostic — `CurrentUserView` is a
  /// `RetrieveUpdateAPIView` — which makes it the only profile endpoint a
  /// parent has. `/api/users/profile/` is the teacher's.
  ///
  /// Pass only the fields that changed. `role` is writable on this serializer,
  /// so a payload built by copying the whole form back could silently move the
  /// account to another role.
  Future<AppUser> updateMe(Map<String, dynamic> changes) async =>
      AppUser.fromJson(await patchMap('/api/users/me/', body: changes));

  // ── Devices ───────────────────────────────────────────────────────────────

  /// Attaches this device to the signed-in account so push can reach it.
  ///
  /// Idempotent: the same token posted twice updates the existing row rather
  /// than creating a duplicate, which matters because the token is re-sent on
  /// every login and on every FCM rotation.
  Future<void> registerDeviceToken(String token, {String platform = 'ANDROID'}) async {
    await postMap('/api/users/device-token/', body: {
      'token': token,
      'platform': platform,
    });
  }

  /// Detaches this device, so the next account signing in on this phone does
  /// not inherit the last one's notifications.
  Future<void> unregisterDeviceToken(String token) => guard(() async {
        await dio.delete('/api/users/device-token/', data: {'token': token});
      });

  // ── Security ──────────────────────────────────────────────────────────────

  /// Changes the account password. The server requires the current one, wants
  /// at least 8 characters, and refuses a new password equal to the old.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await postMap('/api/users/change-password/', body: {
      'current_password': currentPassword,
      'new_password': newPassword,
    });
  }

  /// Step one of moving the account to a new number: proves the password, checks
  /// the number is free, and sends an OTP to it.
  Future<void> requestPhoneChange({
    required String currentPassword,
    required String newPhone,
  }) async {
    await postMap('/api/users/change-phone/request/', body: {
      'current_password': currentPassword,
      'new_phone': newPhone,
    });
  }

  /// Step two: the OTP that landed on the new number.
  ///
  /// The phone is the login credential, so this is the only safe way to change
  /// it — `PATCH /api/users/me/` would accept a new number without proving the
  /// user holds it, and lock them out of their own account.
  Future<void> confirmPhoneChange({
    required String newPhone,
    required String otp,
  }) async {
    await postMap('/api/users/change-phone/confirm/', body: {
      'new_phone': newPhone,
      'otp': otp,
    });
  }

  /// Raises an enquiry with our team — the app's support channel.
  ///
  /// `POST /api/users/contact/` (`EnquiryCreateView`, `AllowAny`) is the only
  /// route a parent or teacher can reach. The support-ticket API is
  /// `IsAdminOrSuperAdmin` and cannot be called from here, so an enquiry is
  /// what "contact support" actually creates: it lands in the counsellor's
  /// inbox rather than a ticket queue the user can track.
  Future<void> raiseEnquiry({
    required String name,
    required String subject,
    required String message,
    String? phone,
    String? email,
    String? role,
  }) async {
    await postMap('/api/users/contact/', body: {
      'name': name,
      'subject': subject,
      'message': message,
      if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
      if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
      if (role != null && role.trim().isNotEmpty) 'role': role.trim(),
    });
  }

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

  /// Replaces the teacher's profile photo.
  ///
  /// Multipart rather than JSON: `TutorProfileView` accepts both, but an image
  /// only travels as a file. Sent as bytes for the same reason KYC is — a
  /// picked file has no readable path on web.
  Future<TutorProfile> updateProfilePhoto(UploadFile photo) => guard(() async {
        final form = FormData();
        form.files.add(MapEntry(
          'profile_image',
          MultipartFile.fromBytes(photo.bytes, filename: photo.filename),
        ));
        final res = await dio.patch('/api/users/profile/', data: form);
        final data = res.data;
        return TutorProfile.fromJson(
          data is Map ? data.cast<String, dynamic>() : const {},
        );
      });

  /// Replaces the teacher's intro video.
  ///
  /// A `FileField` server-side, so this is an upload rather than a link. The
  /// website caps these at 50 MB; nothing enforces that here, so the picker
  /// limits the recording length instead.
  Future<TutorProfile> updateIntroVideo(UploadFile video) => guard(() async {
        final form = FormData();
        form.files.add(MapEntry(
          'intro_video',
          MultipartFile.fromBytes(video.bytes, filename: video.filename),
        ));
        final res = await dio.patch('/api/users/profile/', data: form);
        final data = res.data;
        return TutorProfile.fromJson(
          data is Map ? data.cast<String, dynamic>() : const {},
        );
      });

  /// The teacher's platform score and rank badge.
  ///
  /// Returns null rather than throwing when the teacher has no score row yet —
  /// the endpoint 404s for a profile that has never been scored, and that is a
  /// normal state for a new teacher, not an error worth a red banner.
  Future<TutorScore?> myScore() async {
    try {
      return TutorScore.fromJson(await getMap('/api/ranking/me/'));
    } on ApiFailure catch (e) {
      if (e.isNotFound) return null;
      rethrow;
    }
  }

  /// Where the teacher stands in KYC — drives the verification banner.
  Future<KycStatus> kycStatus() async =>
      KycStatus.fromJson(await getMap('/api/users/kyc/status/'));

  /// Submits KYC documents for review, keyed by the form field each belongs to
  /// (`aadhaar_front`, `highest_qualification_certificate`, …).
  ///
  /// The API accepts images only — PDFs are rejected server-side — and wants
  /// both sides of the Aadhaar on a first submission.
  ///
  /// Bytes, not paths: `MultipartFile.fromFile` needs `dart:io`, so on web —
  /// where a picked file is a blob URL — every submission threw before it left
  /// the device. [UploadFile] carries what both platforms can produce.
  Future<KycStatus> submitKyc(Map<String, UploadFile> documents) =>
      guard(() async {
        final form = FormData();
        for (final entry in documents.entries) {
          form.files.add(MapEntry(
            entry.key,
            MultipartFile.fromBytes(
              entry.value.bytes,
              filename: entry.value.filename,
            ),
          ));
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
    required UploadFile file,
  }) =>
      guard(() async {
        final form = FormData();
        form.files.add(MapEntry(
          field,
          MultipartFile.fromBytes(file.bytes, filename: file.filename),
        ));
        await dio.patch('/api/users/kyc/document/', data: form);
      });

  /// Records acceptance of the Terms & Conditions, which KYC submission
  /// requires before it will accept any documents.
  Future<void> acceptTerms() async {
    await patchMap('/api/users/profile/', body: {'terms_accepted': true});
  }

  /// Leads this teacher has already unlocked, newest first.
  Future<List<UnlockedLead>> unlockedLeads() async {
    final rows = await getList('/api/users/dashboard/unlocked-leads/');
    return rows.map(UnlockedLead.fromJson).toList()
      ..sort((a, b) {
        final at = a.unlockedAt, bt = b.unlockedAt;
        if (at == null && bt == null) return b.id.compareTo(a.id);
        if (at == null) return 1;
        if (bt == null) return -1;
        return bt.compareTo(at);
      });
  }

  /// Teacher contacts this parent has already unlocked.
  Future<List<PublicTutor>> unlockedContacts() async =>
      (await getList('/api/users/dashboard/unlocked-contacts/'))
          .map(PublicTutor.fromJson)
          .toList();

  /// Spends a credit to reveal a teacher's phone and WhatsApp number.

  /// Spends a credit to reveal a teacher's phone and email.
  ///
  /// `POST /api/users/tutor/{tutorProfileId}/unlock/`, parents only. Three
  /// refusals matter and each needs a different answer from the UI:
  ///
  /// * **403** — the teacher has switched direct unlocks off. Nothing is
  ///   charged. The public profile does not carry that flag, so this is the
  ///   only way to find out.
  /// * **402** — not enough credits. Carries `required` and `current`.
  /// * **200 with "Already unlocked"** — a repeat tap. Also not charged.
  ///
  /// Takes the **TutorProfile** id, not the user id.
  Future<Map<String, dynamic>> unlockTutorContact(int tutorProfileId) =>
      postMap('/api/users/tutor/$tutorProfileId/unlock/');

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
  Future<InstitutionProfile> institutionProfile() async =>
      InstitutionProfile.fromJson(
          await getMap('/api/users/institution/profile/'));

  Future<InstitutionProfile> updateInstitutionProfile(
          Map<String, dynamic> changes) async =>
      InstitutionProfile.fromJson(
          await patchMap('/api/users/institution/profile/', body: changes));

  /// Active teachers an institute can browse and hire from. Despite the URL,
  /// this is a directory of everyone available — not staff already attached to
  /// the institute, which the API has no concept of outside THT Prep.
  Future<List<PublicTutor>> institutionTutors({String? query}) async =>
      (await getList(
        '/api/users/institution/tutors/',
        query: query == null || query.trim().isEmpty ? null : {'q': query.trim()},
      ))
          .map(PublicTutor.fromJson)
          .toList();
}

final usersRepositoryProvider =
    Provider<UsersRepository>((ref) => UsersRepository());
