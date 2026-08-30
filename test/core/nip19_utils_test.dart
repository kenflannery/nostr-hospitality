import 'package:flutter_test/flutter_test.dart';
import 'package:nostr_hospitality/core/utils/nip19_utils.dart';

void main() {
  group('Nip19Helper Tests', () {
    const hexPubkey = '79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798';
    const hexPrivkey = '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef';

    test('Encodes and decodes npub', () {
      final npub = Nip19Helper.pubkeyToNpub(hexPubkey);
      expect(npub.startsWith('npub1'), true);
      final decoded = Nip19Helper.decodePubkey(npub);
      expect(decoded, hexPubkey);
    });

    test('Encodes and decodes nsec', () {
      final nsec = Nip19Helper.privkeyToNsec(hexPrivkey);
      expect(nsec.startsWith('nsec1'), true);
      final decoded = Nip19Helper.decodePrivateKey(nsec);
      expect(decoded, hexPrivkey);
    });

    test('Validates 64-char hex key', () {
      expect(Nip19Helper.isValidHexKey(hexPubkey), true);
      expect(Nip19Helper.isValidHexKey('invalid_key'), false);
    });

    test('Shortens key properly', () {
      final shortened = Nip19Helper.shortenKey(hexPubkey, prefixLen: 6, suffixLen: 4);
      expect(shortened, '79be66...1798');
    });

    test('Parses addressable coordinate', () {
      final parsed = Nip19Helper.parseAddressCoordinate('30402:pubkey123:hospitality-home');
      expect(parsed, isNotNull);
      expect(parsed!['kind'], '30402');
      expect(parsed['pubkey'], 'pubkey123');
      expect(parsed['dTag'], 'hospitality-home');
    });
  });
}
