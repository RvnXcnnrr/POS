import 'package:intl/intl.dart';

/// Business day logic with a cutoff time.
///
/// Default cutoff: 4:00 AM local time.
/// - A time before cutoff counts as the previous business day.
/// - A time at/after cutoff counts as the current business day.
class BusinessDay {
  static const int defaultCutoffHour = 4;

  /// Returns the business-day start timestamp (local time) for the given [now].
  static DateTime businessDayStart(
    DateTime now, {
    int cutoffHour = defaultCutoffHour,
  }) {
    final local = now.toLocal();
    final cutoffToday = DateTime(
      local.year,
      local.month,
      local.day,
      cutoffHour,
    );
    if (local.isBefore(cutoffToday)) {
      return cutoffToday.subtract(const Duration(days: 1));
    }
    return cutoffToday;
  }

  /// Returns the business date as `yyyy-MM-dd`.
  static String businessDateFor(
    DateTime now, {
    int cutoffHour = defaultCutoffHour,
  }) {
    final start = businessDayStart(now, cutoffHour: cutoffHour);
    return DateFormat('yyyy-MM-dd').format(start);
  }

  /// Returns an inclusive-exclusive time range for the business day of [now].
  static ({int startMs, int endExclusiveMs}) businessDayRange(
    DateTime now, {
    int cutoffHour = defaultCutoffHour,
  }) {
    final start = businessDayStart(now, cutoffHour: cutoffHour);
    final end = start.add(const Duration(days: 1));
    return (
      startMs: start.millisecondsSinceEpoch,
      endExclusiveMs: end.millisecondsSinceEpoch,
    );
  }
}
