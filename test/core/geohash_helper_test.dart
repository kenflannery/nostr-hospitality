import 'package:flutter_test/flutter_test.dart';
import 'package:nostr_hospitality/core/utils/geohash_helper.dart';

void main() {
  group('GeohashHelper Tests', () {
    test('Encodes Seattle coordinates to 4-char geohash "c23n"', () {
      final geohash = GeohashHelper.encode(47.6062, -122.3321, precision: 4);
      expect(geohash, 'c23n');
    });

    test('Decodes 4-char geohash back to approximate center coordinates', () {
      final decoded = GeohashHelper.decode('c23n');
      expect(decoded, isNotNull);
      expect(decoded!.latitude, closeTo(47.6, 0.2));
      expect(decoded.longitude, closeTo(-122.3, 0.2));
    });

    test('Generates cascading prefix geohash list up to 4 characters', () {
      final prefixes = GeohashHelper.cascadingPrefixes('c23n', maxPrecision: 4);
      expect(prefixes, ['c', 'c2', 'c23', 'c23n']);
    });

    test('Handles invalid geohash character gracefully', () {
      final decoded = GeohashHelper.decode('invalid_a#');
      expect(decoded, isNull);
    });
  });
}
