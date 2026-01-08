class TimeRange {
  TimeRange({required this.startMs, required this.endExclusiveMs});

  final int startMs;
  final int endExclusiveMs;

  static TimeRange forLocalDay(DateTime dayLocal) {
    final start = DateTime(dayLocal.year, dayLocal.month, dayLocal.day);
    final end = start.add(const Duration(days: 1));
    return TimeRange(
      startMs: start.millisecondsSinceEpoch,
      endExclusiveMs: end.millisecondsSinceEpoch,
    );
  }
}
