class DateRangeUtils {
  static DateTime defaultLastWeekFromDate() {
    final to = defaultToDate();
    return to.subtract(const Duration(days: 6));
  }

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

  static int minutesSinceMidnight(DateTime dateTime) {
    return dateTime.hour * 60 + dateTime.minute;
  }

  static bool isTimeOfDayInRange(
    DateTime dateTime,
    int fromHour,
    int fromMinute,
    int toHour,
    int toMinute,
  ) {
    final minutes = minutesSinceMidnight(dateTime);
    final fromMinutes = fromHour * 60 + fromMinute;
    final toMinutes = toHour * 60 + toMinute;
    if (fromMinutes <= toMinutes) {
      return minutes >= fromMinutes && minutes <= toMinutes;
    }
    return minutes >= fromMinutes || minutes <= toMinutes;
  }
}
