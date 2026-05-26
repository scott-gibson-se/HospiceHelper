class DateRangeUtils {
  static DateTime defaultFromDate() {
    final to = defaultToDate();
    return to.subtract(const Duration(days: 30));
  }

  static DateTime defaultToDate() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  static DateTime rangeStart(DateTime fromDate) {
    return DateTime(fromDate.year, fromDate.month, fromDate.day);
  }

  static DateTime rangeEnd(DateTime toDate) {
    return DateTime(toDate.year, toDate.month, toDate.day, 23, 59, 59, 999);
  }

  static bool isInRange(DateTime date, DateTime fromDate, DateTime toDate) {
    final start = rangeStart(fromDate);
    final end = rangeEnd(toDate);
    return !date.isBefore(start) && !date.isAfter(end);
  }
}
