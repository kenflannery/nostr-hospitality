import 'package:flutter_test/flutter_test.dart';
import 'package:nostr_hospitality/core/nostr/signer_service.dart';
import 'package:nostr_hospitality/core/nostr/signers/nip46_signer.dart';

void main() {
  group('NIP-46 BunkerConnectionParams Tests', () {
    const validHexPubkey = '79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798';

    test('Parses valid bunker:// URI correctly', () {
      final uri = 'bunker://$validHexPubkey?relay=wss://relay.damus.io&secret=123456';
      final params = BunkerConnectionParams.parse(uri);

      expect(params.remotePubkey, validHexPubkey);
      expect(params.relayUrl, 'wss://relay.damus.io');
      expect(params.secret, '123456');
      expect(params.toUriString(), uri);
    });

    test('Parses valid nostrconnect:// URI correctly', () {
      final uri = 'nostrconnect://$validHexPubkey?relay=wss://relay.nsec.app';
      final params = BunkerConnectionParams.parse(uri);

      expect(params.remotePubkey, validHexPubkey);
      expect(params.relayUrl, 'wss://relay.nsec.app');
      expect(params.secret, isNull);
    });

    test('Throws FormatException on invalid bunker URI', () {
      expect(() => BunkerConnectionParams.parse('https://example.com'), throwsFormatException);
      expect(() => BunkerConnectionParams.parse('bunker://invalid-pubkey?relay=wss://relay.damus.io'), throwsFormatException);
      expect(() => BunkerConnectionParams.parse('bunker://$validHexPubkey'), throwsFormatException);
    });
  });

  group('SignerType and Nip46BunkerSigner Tests', () {
    const validHexPubkey = '79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798';
    final bunkerUri = 'bunker://$validHexPubkey?relay=wss://relay.damus.io';

    test('Nip46BunkerSigner instantiates from cached connection', () {
      final signer = Nip46BunkerSigner.fromCached(bunkerUri, validHexPubkey);
      expect(signer.getPublicKey(), validHexPubkey);
      expect(signer.canSign(), true);
      expect(signer.requiresInteractiveSigning, true);
      expect(signer.requiresSignerNetwork, true);
      expect(signer.signerTransportRelayUrls, ['wss://relay.damus.io']);
    });

    test('SignerType enum values match expected identifiers', () {
      expect(SignerType.localKey.name, 'localKey');
      expect(SignerType.nip07.name, 'nip07');
      expect(SignerType.nip46.name, 'nip46');
    });
  });
}
