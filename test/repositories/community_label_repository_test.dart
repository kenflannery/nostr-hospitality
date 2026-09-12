import 'package:flutter_test/flutter_test.dart';
import 'package:nostr_hospitality/core/constants/nostr_constants.dart';
import 'package:nostr_hospitality/models/community_label.dart';

void main() {
  group('CommunityLabel Repository Draft & Serialization Tests', () {
    test('Draft community label creates compliant Kind 1985 Nip01Event', () {
      const author = 'author_pubkey_hex_1234567890abcdef1234567890abcdef1234567890abcdef';
      const subject = 'subject_pubkey_hex_1234567890abcdef1234567890abcdef1234567890abcdef';

      final draft = CommunityLabel(
        id: '',
        authorPubkey: author,
        targetPubkey: subject,
        tag: 'great_cook',
        namespace: '#t',
        comment: 'Cooked amazing handmade noodles',
        createdAt: DateTime.now(),
      );

      final event = draft.toNip01Event(authorPubkey: author);
      expect(event.kind, NostrConstants.labelKind);
      expect(event.pubKey, author);
      expect(event.content, 'Cooked amazing handmade noodles');

      final tags = event.tags;
      expect(tags.any((t) => t[0] == 'L' && t[1] == '#t'), true);
      expect(tags.any((t) => t[0] == 'l' && t[1] == 'great_cook' && t[2] == '#t'), true);
      expect(tags.any((t) => t[0] == 'p' && t[1] == subject), true);
    });

    test('Draft label targeting an event includes e tag', () {
      const author = 'author_pubkey_hex_1234567890abcdef1234567890abcdef1234567890abcdef';
      const subject = 'subject_pubkey_hex_1234567890abcdef1234567890abcdef1234567890abcdef';
      const eventId = 'listing_event_id_12345';

      final draft = CommunityLabel(
        id: '',
        authorPubkey: author,
        targetPubkey: subject,
        targetEventId: eventId,
        tag: 'creepy',
        namespace: '#t',
        comment: 'Uncomfortable late night comments',
        createdAt: DateTime.now(),
      );

      final event = draft.toNip01Event(authorPubkey: author);
      expect(event.tags.any((t) => t[0] == 'e' && t[1] == eventId), true);
      expect(event.tags.any((t) => t[0] == 'l' && t[1] == 'creepy'), true);
    });
  });
}
