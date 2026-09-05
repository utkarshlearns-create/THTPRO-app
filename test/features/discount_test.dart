import 'package:flutter_test/flutter_test.dart';
import 'package:tht_app/core/models/wallet.dart';

/// Which discount the page quotes.
///
/// The server charges whichever of the two is larger and never stacks them, so
/// the app has to reach the same answer. Getting this wrong shows one price on
/// the card and takes a different one at the payment sheet, which reads as a
/// pricing bug even when the buyer is better off.
void main() {
  const offer = RenewalOffer(valid: true, code: 'REN10', percentOff: 10);
  const bigOffer = RenewalOffer(valid: true, code: 'REN30', percentOff: 30);
  final promo = PlatformPromo.fromJson({
    'active': true,
    'label': "Teachers' Day",
    'percent_off': '20',
    'ends': '2026-09-06',
  });

  test('nothing running means nothing quoted', () {
    final d = Discount.better(RenewalOffer.none, PlatformPromo.none);
    expect(d.isReal, isFalse);
    expect(d.applyTo(1000), 1000);
  });

  test('a sale alone applies', () {
    final d = Discount.better(RenewalOffer.none, promo);
    expect(d.percentOff, 20);
    expect(d.isSale, isTrue);
    expect(d.label, "Teachers' Day");
    expect(d.applyTo(1000), 800);
  });

  test('the larger wins, and they never add up', () {
    final d = Discount.better(offer, promo);
    expect(d.percentOff, 20, reason: 'the sale beats a 10% renewal offer');
    expect(d.applyTo(1000), 800, reason: '30% would mean they stacked');
  });

  test('a bigger personal offer beats the sale', () {
    final d = Discount.better(bigOffer, promo);
    expect(d.percentOff, 30);
    expect(d.isSale, isFalse, reason: 'a renewal offer has no sale name');
  });

  test('an inactive promo is ignored even when it carries a percent', () {
    final ended = PlatformPromo.fromJson({
      'active': false,
      'percent_off': '50',
    });
    expect(Discount.better(RenewalOffer.none, ended).isReal, isFalse);
    expect(Discount.better(offer, ended).percentOff, 10);
  });

  test('the price never falls below a rupee', () {
    final all = PlatformPromo.fromJson({'active': true, 'percent_off': '100'});
    expect(Discount.better(RenewalOffer.none, all).applyTo(500), 1);
  });

  test('whole percentages read without a decimal', () {
    expect(Discount.better(RenewalOffer.none, promo).percentLabel, '20');
    expect(
      Discount.better(
        const RenewalOffer(valid: true, percentOff: 12.5),
        PlatformPromo.none,
      ).percentLabel,
      '12.5',
    );
  });
}
