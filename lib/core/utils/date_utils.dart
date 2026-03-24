import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateTimeUtils {
  /// Format date to display string
  static String formatDate(DateTime date) {
    return DateFormat('MMM d, yyyy').format(date);
  }

  /// Format date to short string (e.g., "Mon, Jan 1")
  static String formatDateShort(DateTime date) {
    return DateFormat('E, MMM d').format(date);
  }

  /// Format time to display string
  static String formatTime(TimeOfDay time) {
    final now = DateTime.now();
    final dateTime =
        DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat('h:mm a').format(dateTime);
  }

  /// Get date only (without time)
  static DateTime dateOnly(DateTime dateTime) {
    return DateTime(dateTime.year, dateTime.month, dateTime.day);
  }

  /// Check if two dates are the same day
  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Check if date is today
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return isSameDay(date, now);
  }

  /// Check if date is yesterday
  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return isSameDay(date, yesterday);
  }

  /// Get relative date string (Today, Yesterday, or date)
  static String getRelativeDateString(DateTime date) {
    if (isToday(date)) return 'Today';
    if (isYesterday(date)) return 'Yesterday';
    return formatDateShort(date);
  }

  /// Get start of week for a given date
  static DateTime startOfWeek(DateTime date,
      {int firstDayOfWeek = DateTime.monday}) {
    int daysToSubtract = (date.weekday - firstDayOfWeek) % 7;
    return dateOnly(date.subtract(Duration(days: daysToSubtract)));
  }

  /// Get end of week for a given date
  static DateTime endOfWeek(DateTime date,
      {int firstDayOfWeek = DateTime.monday}) {
    return startOfWeek(date, firstDayOfWeek: firstDayOfWeek)
        .add(const Duration(days: 6));
  }

  /// Get start of month for a given date
  static DateTime startOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  /// Get end of month for a given date
  static DateTime endOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0);
  }

  /// Get list of dates in a week
  static List<DateTime> getDatesInWeek(DateTime referenceDate,
      {int firstDayOfWeek = DateTime.monday}) {
    final start = startOfWeek(referenceDate, firstDayOfWeek: firstDayOfWeek);
    return List.generate(7, (index) => start.add(Duration(days: index)));
  }

  /// Get list of dates in a month
  static List<DateTime> getDatesInMonth(DateTime referenceDate) {
    final start = startOfMonth(referenceDate);
    final end = endOfMonth(referenceDate);
    final days = end.day;
    return List.generate(days, (index) => start.add(Duration(days: index)));
  }

  /// Parse time string to TimeOfDay
  static TimeOfDay? parseTimeOfDay(String? timeString) {
    if (timeString == null || timeString.isEmpty) return null;
    try {
      final parts = timeString.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } catch (e) {
      return null;
    }
  }

  /// Convert TimeOfDay to string
  static String timeOfDayToString(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  /// Get day name
  static String getDayName(int weekday, {bool short = false}) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    const shortDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return short ? shortDays[weekday - 1] : days[weekday - 1];
  }

  /// Get month name
  static String getMonthName(int month, {bool short = false}) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    const shortMonths = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return short ? shortMonths[month - 1] : months[month - 1];
  }

  /// Get days between two dates
  static int daysBetween(DateTime from, DateTime to) {
    from = dateOnly(from);
    to = dateOnly(to);
    return (to.difference(from).inHours / 24).round();
  }
}
