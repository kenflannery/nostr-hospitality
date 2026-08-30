import 'package:flutter_test/flutter_test.dart';
import 'package:nostr_hospitality/core/constants/nostr_constants.dart';
import 'package:nostr_hospitality/models/interaction_reference.dart';

void main() {
  group('Repository Draft Event Tests', () {
    test('Draft reference creates correct Nip01Event structure', () {
      const author = 'author_pubkey_hex_1234567890abcdef1234567890abcdef1234567890abcdef';
      const subject = 'subject_pubkey_hex_1234567890abcdef1234567890abcdef1234567890abcdef';

      final draft = InteractionReference(
        id: '',
        authorPubkey: author,
        subjectPubkey: subject,
        content: 'Authentic hosting experience',
        createdAt: DateTime.fromMillisecondsSinceEpoch(1700000000 * 1000),
        contexts: [NostrConstants.contextHospitality, NostrConstants.contextTravel],
        role: NostrConstants.roleGuest,
        sentiment: NostrConstants.sentimentPositive,
        associatedAddress: '30402:$subject:hospitality-home',
      );

      final event = draft.toNip01Event(authorPubkey: author);
      expect(event.kind, NostrConstants.interactionReferenceKind);
      expect(event.pubKey, author);
      expect(event.content, 'Authentic hosting experience');

      final tags = event.tags;
      expect(tags.any((t) => t[0] == 'p' && t[1] == subject), true);
      expect(tags.any((t) => t[0] == 'context' && t[1] == 'hospitality'), true);
      expect(tags.any((t) => t[0] == 'context' && t[1] == 'travel'), true);
      expect(tags.any((t) => t[0] == 'role' && t[1] == 'guest'), true);
      expect(tags.any((t) => t[0] == 'sentiment' && t[1] == 'positive'), true);
      expect(tags.any((t) => t[0] == 'a' && t[1] == '30402:$subject:hospitality-home'), true);
    });
  });
}
