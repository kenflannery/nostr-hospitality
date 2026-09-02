import 'package:flutter_test/flutter_test.dart';
import 'package:nostr_hospitality/core/utils/geohash_helper.dart';

void main() {
  group('GeohashHelper Tests', () {
    test('Encodes Seattle coordinates to 4-char geohash "c23n" and 5-char "c23nb"', () {
      final g4 = GeohashHelper.encode(47.6062, -122.3321, precision: 4);
      expect(g4, 'c23n');

      final g5Default = GeohashHelper.encode(47.6062, -122.3321);
      expect(g5Default, 'c23nb');

      final g3 = GeohashHelper.encode(47.6062, -122.3321, precision: 3);
      expect(g3, 'c23');
    });

    test('Decodes 4-char and 5-char geohash back to approximate center coordinates', () {
      final decoded4 = GeohashHelper.decode('c23n');
      expect(decoded4, isNotNull);
      expect(decoded4!.latitude, closeTo(47.6, 0.2));
      expect(decoded4.longitude, closeTo(-122.3, 0.2));

      final decoded5 = GeohashHelper.decode('c23nb');
      expect(decoded5, isNotNull);
      expect(decoded5!.latitude, closeTo(47.6, 0.05));
      expect(decoded5.longitude, closeTo(-122.3, 0.05));
    });

    test('Generates cascading prefix geohash list up to 5 characters', () {
      final prefixes = GeohashHelper.cascadingPrefixes('c23nb');
      expect(prefixes, ['c', 'c2', 'c23', 'c23n', 'c23nb']);
    });

    test('Generates cascading prefix geohash list for 3 and 4 character geohashes', () {
      expect(GeohashHelper.cascadingPrefixes('c23'), ['c', 'c2', 'c23']);
      expect(GeohashHelper.cascadingPrefixes('c23n'), ['c', 'c2', 'c23', 'c23n']);
    });

    test('Handles invalid geohash character gracefully', () {
      final decoded = GeohashHelper.decode('invalid_a#');
      expect(decoded, isNull);
    });
  });
}
