import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tht_app/core/auth/auth_provider.dart';
import 'package:tht_app/core/models/payment_record.dart';
import 'package:tht_app/core/models/wallet.dart';
import 'package:tht_app/features/wallet/providers/wallet_providers.dart';
import 'package:tht_app/features/wallet/screens/wallet_screen.dart';

/// Parents and teachers spend credits on opposite things, and the wallet used
/// to explain only the teacher's version to both.
///
/// The danger is not that the page breaks — it is that it stays up and lies.
/// A parent was being told a credit comes back if they attend the demo, and
/// that their validity would lapse, neither of which is true on their side
/// (the server forces `valid_until = null` for parents). So these tests assert
/// on the *absence* of the other role's copy as much as its presence.
void main() {
  Widget harness(UserRole role) => ProviderScope(
        overrides: [
          authProvider.overrideWith(
            (ref) => _StubAuth(AuthState(
              isAuthenticated: true,
              role: role,
              isLoading: false,
            )),
          ),
          walletProvider.overrideWith((ref) async => const Wallet(balance: 3)),
          walletTransactionsProvider
              .overrideWith((ref) async => <WalletTransaction>[]),
          walletPaymentsProvider
              .overrideWith((ref) async => <PaymentRecord>[]),
          creditPackagesProvider
              .overrideWith((ref) async => <CreditPackage>[]),
        ],
        child: const MaterialApp(home: WalletScreen()),
      );

  testWidgets('a parent is told what a parent credit does', (t) async {
    t.view.physicalSize = const Size(390, 2400);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.reset);

    await t.pumpWidget(harness(UserRole.parent));
    await t.pumpAndSettle();

    expect(find.text('One credit, one teacher'), findsOneWidget);
    expect(find.text('Your credits never expire'), findsOneWidget);

    // The teacher's model, which is false for a parent.
    expect(find.text('Turn up, and it stays yours'), findsNothing);
    expect(find.text('Your clock starts on the first unlock'), findsNothing);
    expect(find.textContaining('Validity-only plans'), findsNothing);
  });

  testWidgets('a teacher still gets the teacher explainer', (t) async {
    t.view.physicalSize = const Size(390, 2400);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.reset);

    await t.pumpWidget(harness(UserRole.teacher));
    await t.pumpAndSettle();

    expect(find.text('Turn up, and it stays yours'), findsOneWidget);
    expect(find.text('Your clock starts on the first unlock'), findsOneWidget);

    expect(find.text('One credit, one teacher'), findsNothing);
    expect(find.text('Your credits never expire'), findsNothing);
  });
}

class _StubAuth extends AuthNotifier {
  _StubAuth(AuthState seed) {
    state = seed;
  }
}
