import 'package:intl/intl.dart';

/// Display formatting shared across every screen, so ₹ amounts and dates read
/// the same in the wallet as they do on a lead card.
abstract final class Fmt {
  static final NumberFormat _inr = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );
  static final NumberFormat _inrCompact = NumberFormat.compactCurrency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 1,
  );
  static final NumberFormat _plain = NumberFormat.decimalPattern('en_IN');

  /// `₹1,20,000` — Indian digit grouping, no paise.
  static String rupees(num? amount) => _inr.format(amount ?? 0);

  /// `₹1.2L` — for stat tiles where the full number would wrap.
  static String rupeesCompact(num? amount) {
    final v = amount ?? 0;
    return v < 1000 ? _inr.format(v) : _inrCompact.format(v);
  }

  /// `1,20,000`
  static String number(num? value) => _plain.format(value ?? 0);

  /// `12 Mar 2026`
  static String date(DateTime? d) => d == null ? '—' : DateFormat('d MMM yyyy').format(d);

  /// `12 Mar, 4:30 PM`
  static String dateTime(DateTime? d) =>
      d == null ? '—' : DateFormat('d MMM, h:mm a').format(d);

  /// `4:30 PM`
  static String time(DateTime? d) => d == null ? '—' : DateFormat('h:mm a').format(d);

  /// `Monday, 12 March` — for a schedule header.
  static String longDate(DateTime? d) =>
      d == null ? '—' : DateFormat('EEEE, d MMMM').format(d);

  /// `2 days ago`, `Just now`, `In 3 days`.
  static String relative(DateTime? d) {
    if (d == null) return '—';
    final diff = DateTime.now().difference(d);
    final future = diff.isNegative;
    final abs = diff.abs();

    String phrase;
    if (abs.inMinutes < 1) {
      return 'Just now';
    } else if (abs.inMinutes < 60) {
      phrase = plural(abs.inMinutes, 'minute');
    } else if (abs.inHours < 24) {
      phrase = plural(abs.inHours, 'hour');
    } else if (abs.inDays < 30) {
      phrase = plural(abs.inDays, 'day');
    } else if (abs.inDays < 365) {
      phrase = plural(abs.inDays ~/ 30, 'month');
    } else {
      phrase = plural(abs.inDays ~/ 365, 'year');
    }
    return future ? 'In $phrase' : '$phrase ago';
  }

  /// `1 day` / `3 days`
  static String plural(int count, String noun, {String? pluralForm}) =>
      '$count ${count == 1 ? noun : (pluralForm ?? '${noun}s')}';

  /// `UD` from "Utkarsh Dubey" — for avatar fallbacks.
  static String initials(String? name) {
    final parts = (name ?? '').trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  /// `Utkarsh` from "utkarsh" — names come back from the API uncapitalised.
  static String titleCase(String? value) {
    final s = (value ?? '').trim();
    if (s.isEmpty) return '';
    return s
        .split(RegExp(r'\s+'))
        .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1).toLowerCase())
        .join(' ');
  }

  /// `HIRED` → `Hired`, `NOT_SELECTED` → `Not selected`.
  static String status(String? raw) {
    final s = (raw ?? '').trim();
    if (s.isEmpty) return '';
    final words = s.toLowerCase().replaceAll('_', ' ');
    return words[0].toUpperCase() + words.substring(1);
  }

  /// `Maths, Science and English` — for a subject list in running text.
  static String list(List<String> items, {int max = 3}) {
    if (items.isEmpty) return '—';
    if (items.length <= max) {
      if (items.length == 1) return items.first;
      return '${items.take(items.length - 1).join(', ')} and ${items.last}';
    }
    return '${items.take(max).join(', ')} +${items.length - max} more';
  }

  /// `+91 98765 43210`
  static String phone(String? raw) {
    final digits = (raw ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.length == 10) {
      return '+91 ${digits.substring(0, 5)} ${digits.substring(5)}';
    }
    if (digits.length == 12 && digits.startsWith('91')) {
      return '+91 ${digits.substring(2, 7)} ${digits.substring(7)}';
    }
    return raw ?? '';
  }
}
