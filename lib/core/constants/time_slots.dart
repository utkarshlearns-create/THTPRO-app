/// The one list of time slots used by both sides of the marketplace: a job's
/// requested `preferred_time` and a teacher's `available_time_slots`.
///
/// A direct port of the website's `lib/timeSlots.js`, and it has to stay one.
/// The two only compare if they speak the same vocabulary — free text on either
/// side, or two drifting copies of this list, and a teacher's availability can
/// never be checked against a job's timing. Change this only alongside the
/// website's copy.
class TimeSlots {
  const TimeSlots._();

  static const anyTime = 'Flexible / Any Time';

  /// One-hour slots from 6 AM to 10 PM: `6 - 7 AM` … `9 - 10 PM`.
  static final List<String> hourly = _build();

  /// Every slot a teacher can pick, with "flexible" last.
  static final List<String> all = [...hourly, anyTime];

  static List<String> _build({int startHour = 6, int endHour = 22}) {
    String label(int h) => (h % 12 == 0 ? 12 : h % 12).toString();
    String period(int h) => h >= 12 ? 'PM' : 'AM';

    return [
      for (var h = startHour; h < endHour; h++)
        period(h) == period(h + 1)
            // "6 - 7 AM"
            ? '${label(h)} - ${label(h + 1)} ${period(h)}'
            // "11 AM - 12 PM"
            : '${label(h)} ${period(h)} - ${label(h + 1)} ${period(h + 1)}',
    ];
  }
}
