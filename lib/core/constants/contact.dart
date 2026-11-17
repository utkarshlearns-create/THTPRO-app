/// The one place our own phone number and support address are written down.
///
/// Three screens reached for this independently — support, the wallet and the
/// teacher's job screen — and a number duplicated across screens is a number
/// that goes stale on two of them.
///
/// This is the public business line on the website footer and in the Play
/// Console store listing, not a counsellor's personal number: a lead's own
/// counsellor is carried on the lead and shown by `CounsellorStrip`.
abstract final class ThtContact {
  /// Country code and number, no `+`: the shape `wa.me` wants.
  static const String phone = '916387488141';

  /// How the number is written when a human reads it.
  static const String phoneLabel = '+91 63874 88141';

  static const String email = 'support@thehometuitions.in';

  static Uri get whatsapp => Uri.parse('https://wa.me/$phone');
  static Uri get call => Uri.parse('tel:+$phone');
  static Uri get mail => Uri.parse('mailto:$email');

  /// WhatsApp, with the chat already opened on a subject.
  ///
  /// Saves the sender typing and tells whoever picks it up what it is about
  /// before they have read a word of it.
  static Uri whatsappAbout(String message) =>
      Uri.parse('https://wa.me/$phone?text=${Uri.encodeComponent(message)}');
}
