/// The one place our own phone numbers and support address are written down.
///
/// Three screens reached for this independently — support, the wallet and the
/// teacher's job screen — and a number duplicated across screens is a number
/// that goes stale on two of them.
///
/// Neither of these is a counsellor's personal number: a lead's own counsellor
/// is carried on the lead and shown by `CounsellorStrip`.
abstract final class ThtContact {
  /// The public business line — parents, general support, the store listing
  /// and the website footer.
  ///
  /// Country code and number, no `+`: the shape `wa.me` wants.
  static const String phone = '916387488141';

  /// How the public line is written when a human reads it.
  static const String phoneLabel = '+91 63874 88141';

  /// The tutor desk: a teacher's OWN account — credits, plan, verification,
  /// login, payout.
  ///
  /// Teachers are sent here rather than to the public line for two reasons.
  /// The desk is the team that actually adds credits by hand, so the message
  /// lands with the person who can act on it. And the public line answers to
  /// the WhatsApp bot first, which — by its own rules — never settles an
  /// account question itself; it replies with this very number, so routing a
  /// teacher through it only makes them ask twice.
  static const String tutorAdminPhone = '916393108908';

  /// How the tutor desk's number is written when a human reads it.
  static const String tutorAdminPhoneLabel = '+91 63931 08908';

  static const String email = 'support@thehometuitions.in';

  static Uri get whatsapp => whatsappTo(phone);
  static Uri get call => callTo(phone);
  static Uri get mail => Uri.parse('mailto:$email');

  static Uri callTo(String number) => Uri.parse('tel:+$number');

  /// WhatsApp, optionally with the chat already opened on a subject.
  ///
  /// Saves the sender typing and tells whoever picks it up what it is about
  /// before they have read a word of it.
  static Uri whatsappTo(String number, [String? message]) => Uri.parse(
        message == null
            ? 'https://wa.me/$number'
            : 'https://wa.me/$number?text=${Uri.encodeComponent(message)}',
      );

  /// The public line, with an opening message. Kept for the callers that only
  /// ever write to that number.
  static Uri whatsappAbout(String message) => whatsappTo(phone, message);
}
