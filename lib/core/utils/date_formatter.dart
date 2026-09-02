import 'package:intl/intl.dart';

/// Formatting utilities for dates and relative timestamps.
class DateFormatter {
  DateFormatter._();

  static final DateFormat _shortDateFormat = DateFormat.yMMMd();
  static final DateFormat _timeFormat = DateFormat.jm();

  /// Formats date to a human-friendly relative string or formatted date.
  static String formatRelative(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return '$minutes ${minutes == 1 ? 'min' : 'mins'} ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return '$days ${days == 1 ? 'day' : 'days'} ago';
    } else if (difference.inDays < 365 && dateTime.year == now.year) {
      return DateFormat('MMM d').format(dateTime);
    } else {
      return _shortDateFormat.format(dateTime);
    }
  }

  /// Formats date as "Oct 24, 2026".
  static String formatShort(DateTime dateTime) {
    return _shortDateFormat.format(dateTime);
  }

  /// Formats time as "3:45 PM".
  static String formatTime(DateTime dateTime) {
    return _timeFormat.format(dateTime);
  }

  /// Formats a date range as "Nov 2 – Nov 5, 2026" or "From Nov 2, 2026".
  static String formatDateRange(DateTime? start, DateTime? end) {
    if (start == null && end == null) return '';
    if (start != null && end == null) return 'From ${_shortDateFormat.format(start)}';
    if (start == null && end != null) return 'Until ${_shortDateFormat.format(end)}';
    if (start!.year == end!.year) {
      if (start.month == end.month) {
        return '${DateFormat.MMM().format(start)} ${start.day} – ${end.day}, ${start.year}';
      }
      return '${DateFormat.MMMd().format(start)} – ${_shortDateFormat.format(end)}';
    }
    return '${_shortDateFormat.format(start)} – ${_shortDateFormat.format(end)}';
  }
}
