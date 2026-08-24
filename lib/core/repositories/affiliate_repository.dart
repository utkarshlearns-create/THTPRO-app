import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tht_app/core/models/affiliate.dart';
import 'package:tht_app/core/repositories/repository.dart';

/// Refer & Earn — all of `/api/affiliate/`.
///
/// Teacher-only server-side: every endpoint here answers 403 for anyone else.
class AffiliateRepository extends Repository {
  AffiliateRepository([super.dio]);

  /// The referral code, who has joined on it, and what it has earned.
  ///
  /// The code is created on first read, so a teacher who has never opened this
  /// still gets one rather than an empty string.
  Future<Affiliate> dashboard() async =>
      Affiliate.fromJson(await getMap('/api/affiliate/dashboard/'));

  /// The full earnings ledger, rather than the five the dashboard carries.
  Future<List<AffiliateEarning>> earnings() async =>
      (await getList('/api/affiliate/earnings/', key: 'earnings'))
          .map(AffiliateEarning.fromJson)
          .toList();

  /// Asks for everything unpaid to be paid out.
  ///
  /// Takes no amount — the server pays the whole unpaid balance. It refuses
  /// under ₹500, refuses with nothing owing, and refuses a second request while
  /// one is pending.
  Future<Map<String, dynamic>> requestPayout() =>
      postMap('/api/affiliate/payout/request/');
}

final affiliateRepositoryProvider =
    Provider<AffiliateRepository>((ref) => AffiliateRepository());
