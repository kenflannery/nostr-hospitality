import 'package:flutter_test/flutter_test.dart';
import 'package:nostr_hospitality/core/services/update_checker_service.dart';

void main() {
  group('SemVer & Version Policy Tests', () {
    test('Parses various semantic version formats', () {
      final v1 = SemVer.parse('1.0.0');
      expect(v1, isNotNull);
      expect(v1!.major, 1);
      expect(v1.minor, 0);
      expect(v1.patch, 0);

      final v2 = SemVer.parse('v2.1.3+4');
      expect(v2, isNotNull);
      expect(v2!.major, 2);
      expect(v2.minor, 1);
      expect(v2.patch, 3);

      final v3 = SemVer.parse('3.4.5-beta');
      expect(v3, isNotNull);
      expect(v3!.major, 3);
      expect(v3.minor, 4);
      expect(v3.patch, 5);

      expect(SemVer.parse('invalid'), isNull);
    });

    test('Correctly determines if a version is older', () {
      final v100 = SemVer.parse('1.0.0')!;
      final v101 = SemVer.parse('1.0.1')!;
      final v110 = SemVer.parse('1.1.0')!;
      final v200 = SemVer.parse('2.0.0')!;

      // Patch increase
      expect(v100.isOlderThan(v101), true);
      expect(v101.isOlderThan(v100), false);

      // Minor increase
      expect(v100.isOlderThan(v110), true);
      expect(v110.isOlderThan(v100), false);

      // Major increase
      expect(v100.isOlderThan(v200), true);
      expect(v200.isOlderThan(v100), false);

      // Same version
      expect(v100.isOlderThan(v100), false);
    });

    test('Correctly identifies breaking major upgrades for protocol gates', () {
      final current = SemVer.parse('1.2.3')!;

      // Minor and patch bumps are not major upgrades
      expect(current.isMajorUpgrade(SemVer.parse('1.2.4')!), false);
      expect(current.isMajorUpgrade(SemVer.parse('1.3.0')!), false);

      // Major bump (e.g. v2.0.0) is a major upgrade (triggers protocol gate)
      expect(current.isMajorUpgrade(SemVer.parse('2.0.0')!), true);
      expect(current.isMajorUpgrade(SemVer.parse('3.0.0')!), true);
    });
  });
}
