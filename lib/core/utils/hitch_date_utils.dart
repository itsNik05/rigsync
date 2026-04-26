/// Utilities for oilfield hitch pattern calculations.
class HitchDateUtils {
  HitchDateUtils._();

  /// Given a [startDate], [daysOn], and [daysOff],
  /// returns a list of [HitchPeriod] covering [months] months.
  static List<HitchPeriod> generatePattern({
    required DateTime startDate,
    required int daysOn,
    required int daysOff,
    int months = 12,
  }) {
    final result = <HitchPeriod>[];
    final endDate = DateTime(
      startDate.year,
      startDate.month + months,
      startDate.day,
    );

    var current = startDate;
    var onShift = true;

    while (current.isBefore(endDate)) {
      final days = onShift ? daysOn : daysOff;
      final periodEnd = current.add(Duration(days: days - 1));

      result.add(HitchPeriod(
        start: current,
        end: periodEnd,
        isOnShift: onShift,
      ));

      current = periodEnd.add(const Duration(days: 1));
      onShift = !onShift;
    }

    return result;
  }

  /// Returns days remaining until the next OFF period.
  static int daysUntilNextOff(List<HitchPeriod> periods) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (final period in periods) {
      if (period.isOnShift &&
          !today.isAfter(period.end) &&
          !today.isBefore(period.start)) {
        return period.end.difference(today).inDays + 1;
      }
    }
    return 0;
  }

  /// Returns days remaining until the next ON period.
  static int daysUntilNextOn(List<HitchPeriod> periods) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (final period in periods) {
      if (!period.isOnShift && today.isBefore(period.start)) {
        return period.start.difference(today).inDays;
      }
    }
    return 0;
  }

  /// Strips time from a DateTime, returning midnight.
  static DateTime dateOnly(DateTime dt) =>
      DateTime(dt.year, dt.month, dt.day);

  /// Returns true if two dates fall on the same calendar day.
  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Common oilfield hitch patterns.
  static const List<HitchTemplate> commonPatterns = [
    HitchTemplate(label: '7/7', daysOn: 7, daysOff: 7),
    HitchTemplate(label: '14/14', daysOn: 14, daysOff: 14),
    HitchTemplate(label: '21/7', daysOn: 21, daysOff: 7),
    HitchTemplate(label: '28/28', daysOn: 28, daysOff: 28),
    HitchTemplate(label: '14/7', daysOn: 14, daysOff: 7),
    HitchTemplate(label: '28/14', daysOn: 28, daysOff: 14),
  ];
}

class HitchPeriod {
  const HitchPeriod({
    required this.start,
    required this.end,
    required this.isOnShift,
  });

  final DateTime start;
  final DateTime end;
  final bool isOnShift;

  int get durationDays => end.difference(start).inDays + 1;
}

class HitchTemplate {
  const HitchTemplate({
    required this.label,
    required this.daysOn,
    required this.daysOff,
  });

  final String label;
  final int daysOn;
  final int daysOff;
}