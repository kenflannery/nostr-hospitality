import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:ndk/entities.dart';
import 'package:nostr_hospitality/core/constants/nostr_constants.dart';
import 'package:nostr_hospitality/models/user_profile.dart';

void main() {
  group('UserProfile Model Tests (Kind 0 & NIP-24 Birthday)', () {
    const authorHex = '79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798';

    test('Parses Kind 0 metadata including NIP-24 birthday object', () {
      final content = jsonEncode({
        'name': 'alice',
        'display_name': 'Alice Traveler',
        'about': 'Slow nomad and couch host.',
        'picture': 'https://example.com/alice.jpg',
        'banner': 'https://example.com/banner.jpg',
        'nip05': 'alice@example.com',
        'website': 'https://alicetravels.org',
        'lud16': 'alice@getalby.com',
        'birthday': {
          'year': 1995,
          'month': 4,
          'day': 12,
        },
        'custom_unmanaged_field': 'preserve_me',
      });

      final event = Nip01Event(
        pubKey: authorHex,
        kind: NostrConstants.metadataKind,
        tags: [],
        content: content,
        createdAt: 1719234800,
      );

      final profile = UserProfile.fromNip01Event(event);
      expect(profile, isNotNull);
      expect(profile!.pubkey, authorHex);
      expect(profile.name, 'alice');
      expect(profile.displayName, 'Alice Traveler');
      expect(profile.bestName, 'Alice Traveler');
      expect(profile.about, 'Slow nomad and couch host.');
      expect(profile.picture, 'https://example.com/alice.jpg');
      expect(profile.banner, 'https://example.com/banner.jpg');
      expect(profile.nip05, 'alice@example.com');
      expect(profile.website, 'https://alicetravels.org');
      expect(profile.lud16, 'alice@getalby.com');
      expect(profile.birthYear, 1995);
      expect(profile.birthMonth, 4);
      expect(profile.birthDay, 12);
      expect(profile.calculatedAge, isNotNull);
      expect(profile.rawJson['custom_unmanaged_field'], 'preserve_me');
    });

    test('Serializes Kind 0 event preserving NIP-24 birthday and custom fields', () {
      final profile = UserProfile(
        pubkey: authorHex,
        name: 'bob',
        displayName: 'Bob Hiker',
        about: 'Backpacker in the Alps',
        birthYear: 1990,
        birthMonth: 10,
        birthDay: 5,
        rawJson: {'unmanaged_key': 'safe'},
      );

      final event = profile.toNip01Event();
      expect(event.kind, NostrConstants.metadataKind);
      expect(event.pubKey, authorHex);

      final decoded = jsonDecode(event.content) as Map<String, dynamic>;
      expect(decoded['name'], 'bob');
      expect(decoded['display_name'], 'Bob Hiker');
      expect(decoded['about'], 'Backpacker in the Alps');
      expect(decoded['unmanaged_key'], 'safe');
      expect(decoded['birthday'], isA<Map>());
      expect(decoded['birthday']['year'], 1990);
      expect(decoded['birthday']['month'], 10);
      expect(decoded['birthday']['day'], 5);
    });

    test('Handles partial NIP-24 birthday (year only)', () {
      final content = jsonEncode({
        'name': 'charlie',
        'birthday': {
          'year': 2000,
        },
      });

      final event = Nip01Event(
        pubKey: authorHex,
        kind: NostrConstants.metadataKind,
        tags: [],
        content: content,
        createdAt: 1719234800,
      );

      final profile = UserProfile.fromNip01Event(event);
      expect(profile, isNotNull);
      expect(profile!.birthYear, 2000);
      expect(profile.birthMonth, isNull);
      expect(profile.birthDay, isNull);
      expect(profile.calculatedAge, isNotNull);

      final exported = profile.toNip01Event();
      final decoded = jsonDecode(exported.content) as Map<String, dynamic>;
      expect(decoded['birthday']['year'], 2000);
      expect(decoded['birthday']['month'], isNull);
    });
  });
}
