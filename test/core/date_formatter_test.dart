import 'package:flutter_test/flutter_test.dart';
import 'package:nostr_hospitality/core/utils/date_formatter.dart';

void main() {
  group('DateFormatter Tests', () {
    test('formatRelative handles just now, minutes, hours, days', () {
      final now = DateTime.now();

      final justNow = now.subtract(const Duration(seconds: 15));
      expect(DateFormatter.formatRelative(justNow), 'just now');

      final minsAgo = now.subtract(const Duration(minutes: 5));
      expect(DateFormatter.formatRelative(minsAgo), '5 mins ago');

      final oneMinAgo = now.subtract(const Duration(minutes: 1));
      expect(DateFormatter.formatRelative(oneMinAgo), '1 min ago');

      final hoursAgo = now.subtract(const Duration(hours: 3));
      expect(DateFormatter.formatRelative(hoursAgo), '3 hours ago');

      final daysAgo = now.subtract(const Duration(days: 2));
      expect(DateFormatter.formatRelative(daysAgo), '2 days ago');
    });

    test('formatShort outputs readable short date', () {
      final date = DateTime(2026, 8, 30);
      expect(DateFormatter.formatShort(date), 'Aug 30, 2026');
    });
  });
}
