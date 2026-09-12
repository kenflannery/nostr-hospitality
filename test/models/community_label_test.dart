import 'package:flutter_test/flutter_test.dart';
import 'package:ndk/entities.dart';
import 'package:nostr_hospitality/core/constants/nostr_constants.dart';
import 'package:nostr_hospitality/models/community_label.dart';

void main() {
  group('Kind 1985 CommunityLabel Model Tests', () {
    const authorHex = '79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798';
    const targetHex = 'c6047f9441ed7d6d3045406e95c07cd85c778e4b8cef3ca7abac09b95c709ee5';
    const eventId = 'e0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef';

    test('Parses valid Kind 1985 label event correctly', () {
      final nip01 = Nip01Event(
        pubKey: authorHex,
        kind: NostrConstants.labelKind,
        tags: [
          ['L', '#t'],
          ['l', 'great_cook', '#t'],
          ['p', targetHex],
        ],
        content: 'Made a wonderful sourdough and pasta dinner!',
        createdAt: 1719234800,
      );

      final label = CommunityLabel.fromNip01Event(nip01);
      expect(label, isNotNull);
      expect(label!.authorPubkey, authorHex);
      expect(label.targetPubkey, targetHex);
      expect(label.tag, 'great_cook');
      expect(label.namespace, '#t');
      expect(label.comment, 'Made a wonderful sourdough and pasta dinner!');
      expect(label.targetEventId, isNull);
    });

    test('Parses label with event target correctly', () {
      final nip01 = Nip01Event(
        pubKey: authorHex,
        kind: NostrConstants.labelKind,
        tags: [
          ['L', '#t'],
          ['l', 'creepy', '#t'],
          ['p', targetHex],
          ['e', eventId],
        ],
        content: 'Felt uncomfortable with personal boundaries on the couch.',
        createdAt: 1719234800,
      );

      final label = CommunityLabel.fromNip01Event(nip01);
      expect(label, isNotNull);
      expect(label!.tag, 'creepy');
      expect(label.targetEventId, eventId);
      expect(label.comment, 'Felt uncomfortable with personal boundaries on the couch.');
    });

    test('Converts label draft to Nip01Event and preserves fields', () {
      final label = CommunityLabel(
        id: '',
        authorPubkey: authorHex,
        targetPubkey: targetHex,
        tag: 'Night_Owl',
        namespace: '#t',
        comment: 'Stays up making music until 2am',
        createdAt: DateTime.now(),
      );

      final event = label.toNip01Event(authorPubkey: authorHex);
      expect(event.kind, NostrConstants.labelKind);
      expect(event.pubKey, authorHex);
      expect(event.content, 'Stays up making music until 2am');

      final roundTrip = CommunityLabel.fromNip01Event(event);
      expect(roundTrip, isNotNull);
      expect(roundTrip!.tag, 'night_owl');
      expect(roundTrip.targetPubkey, targetHex);
      expect(roundTrip.comment, 'Stays up making music until 2am');
    });

    test('Returns null if missing p tag or tag name', () {
      final noPTag = Nip01Event(
        pubKey: authorHex,
        kind: NostrConstants.labelKind,
        tags: [
          ['L', '#t'],
          ['l', 'clean', '#t'],
        ],
        content: '',
        createdAt: 1719234800,
      );
      expect(CommunityLabel.fromNip01Event(noPTag), isNull);

      final noLTag = Nip01Event(
        pubKey: authorHex,
        kind: NostrConstants.labelKind,
        tags: [
          ['p', targetHex],
        ],
        content: '',
        createdAt: 1719234800,
      );
      expect(CommunityLabel.fromNip01Event(noLTag), isNull);
    });
  });
}
