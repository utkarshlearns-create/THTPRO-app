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

  // ── the coupon arm ────────────────────────────────────────────────────────
  //
  // A coupon is the only discount the buyer presents, and it does not behave
  // like the other two. CreateRazorpayOrderView reads it FIRST and only falls
  // back to the renewal offer (`elif offer`), so applying one retires that
  // offer outright — while the sale stays in the running and the larger of the
  // two is charged. These pin that asymmetry, because the obvious reading
  // ("the biggest of the three wins") is wrong in a way that quietly overstates
  // the discount on the card.
  group('a coupon the buyer applied', () {
    final coupon = CouponCheck.fromJson(
      {'valid': true, 'code': 'RAHUL15', 'percent_off': '15.00'},
    );

    test('a coupon on its own applies', () {
      final d = Discount.betterWithCoupon(
        RenewalOffer.none,
        PlatformPromo.none,
        coupon,
      );
      expect(d.percentOff, 15);
      expect(d.applyTo(1000), 850);
    });

    test('it retires the renewal offer even when it is smaller', () {
      final d = Discount.betterWithCoupon(bigOffer, PlatformPromo.none, coupon);
      expect(d.percentOff, 15, reason: 'the 30% offer is out of the running');
      expect(d.applyTo(1000), 850);
    });

    test('a running sale still wins when it is larger', () {
      final d = Discount.betterWithCoupon(bigOffer, promo, coupon);
      expect(d.percentOff, 20,
          reason: 'the sale beats the coupon, and the offer is retired');
      expect(d.applyTo(1000), 800, reason: '35% would mean they stacked');
    });

    test('the coupon wins over a smaller sale', () {
      final big = CouponCheck.fromJson(
        {'valid': true, 'code': 'BIG40', 'percent_off': '40'},
      );
      expect(Discount.betterWithCoupon(offer, promo, big).percentOff, 40);
    });

    test('no coupon leaves the ordinary choice alone', () {
      expect(Discount.betterWithCoupon(offer, promo, null).percentOff, 20);
      expect(
        Discount.betterWithCoupon(bigOffer, promo, CouponCheck.none).percentOff,
        30,
      );
    });

    test('a rejected code changes nothing', () {
      final no = CouponCheck.fromJson({'valid': false});
      expect(no.isValid, isFalse);
      expect(Discount.betterWithCoupon(bigOffer, promo, no).percentOff, 30,
          reason: 'an unknown code must not cost the teacher their own offer');
    });

    test('a valid code worth nothing is still a valid code', () {
      // Its job can be attribution alone — it credits the staff member who
      // shared it — so hasDiscount is kept apart from isValid.
      final zero = CouponCheck.fromJson(
        {'valid': true, 'code': 'ZERO', 'percent_off': '0'},
      );
      expect(zero.isValid, isTrue);
      expect(zero.hasDiscount, isFalse);
      expect(Discount.betterWithCoupon(bigOffer, promo, zero).percentOff, 20,
          reason: 'the sale is all that is left once the offer is retired');
    });

    test('the code reads back as the server spells it', () {
      expect(coupon.code, 'RAHUL15');
      expect(coupon.percentOff, 15);
      expect(coupon.hasDiscount, isTrue);
    });
  });
}
