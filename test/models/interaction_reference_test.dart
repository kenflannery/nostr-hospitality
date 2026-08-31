import 'package:flutter_test/flutter_test.dart';
import 'package:ndk/entities.dart';
import 'package:nostr_hospitality/core/constants/nostr_constants.dart';
import 'package:nostr_hospitality/models/interaction_reference.dart';

void main() {
  group('Kind 7654 InteractionReference Model Tests', () {
    const authorHex = '79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798';
    const subjectHex = 'c6047f9441ed7d6d3045406e95c07cd85c778e4b8cef3ca7abac09b95c709ee5';
    const listingCoord = '30402:$subjectHex:hospitality-home';

    test('Parses valid Kind 7654 event with all tags correctly', () {
      final nip01Event = Nip01Event(
        pubKey: authorHex,
        kind: NostrConstants.interactionReferenceKind,
        tags: [
          ['p', subjectHex],
          ['context', 'hospitality'],
          ['role', 'guest'],
          ['sentiment', 'positive'],
          ['t', 'communicative'],
          ['t', 'clean'],
          ['t', 'inspiring'],
          ['a', listingCoord],
          ['e', 'e0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef'],
        ],
        content: 'Bob was a fantastic host. He made me feel completely at home.',
        createdAt: 1719234800,
      );

      final ref = InteractionReference.fromNip01Event(nip01Event);
      expect(ref, isNotNull);
      expect(ref!.id, nip01Event.id);
      expect(ref.authorPubkey, authorHex);
      expect(ref.subjectPubkey, subjectHex);
      expect(ref.content, 'Bob was a fantastic host. He made me feel completely at home.');
      expect(ref.contexts, ['hospitality']);
      expect(ref.role, 'guest');
      expect(ref.sentiment, 'positive');
      expect(ref.tags, ['communicative', 'clean', 'inspiring']);
      expect(ref.isPositive, true);
      expect(ref.isNeutral, false);
      expect(ref.isNegative, false);
      expect(ref.associatedAddress, listingCoord);
      expect(ref.associatedEventId, 'e0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef');
      expect(ref.isAuthorGuest, true);
      expect(ref.isAuthorHost, false);
    });

    test('Ensures unknown context and role values survive parsing without error', () {
      final nip01Event = Nip01Event(
        pubKey: authorHex,
        kind: 7654,
        tags: [
          ['p', subjectHex],
          ['context', 'space_exploration_future_context'],
          ['role', 'co_pilot_role'],
        ],
        content: 'Traveled through the asteroid belt together.',
        createdAt: 1719234800,
      );

      final ref = InteractionReference.fromNip01Event(nip01Event);
      expect(ref, isNotNull);
      expect(ref!.contexts, ['space_exploration_future_context']);
      expect(ref.role, 'co_pilot_role');
      expect(ref.sentiment, isNull);
    });

    test('Absence of sentiment MUST be null and NOT neutral', () {
      final nip01Event = Nip01Event(
        pubKey: authorHex,
        kind: 7654,
        tags: [
          ['p', subjectHex],
          ['context', 'hospitality'],
          ['role', 'guest'],
        ],
        content: 'Stayed for two nights during the conference.',
        createdAt: 1719234800,
      );

      final ref = InteractionReference.fromNip01Event(nip01Event);
      expect(ref, isNotNull);
      expect(ref!.sentiment, isNull);
      expect(ref.isPositive, false);
      expect(ref.isNeutral, false);
      expect(ref.isNegative, false);
    });

    test('Parses valid reference missing optional values (role, context, a, e)', () {
      final nip01Event = Nip01Event(
        pubKey: authorHex,
        kind: 7654,
        tags: [
          ['p', subjectHex],
        ],
        content: 'Met Alice while traveling.',
        createdAt: 1719234800,
      );

      final ref = InteractionReference.fromNip01Event(nip01Event);
      expect(ref, isNotNull);
      expect(ref!.subjectPubkey, subjectHex);
      expect(ref.contexts, isEmpty);
      expect(ref.role, isNull);
      expect(ref.sentiment, isNull);
      expect(ref.associatedAddress, isNull);
      expect(ref.associatedEventId, isNull);
    });

    test('Returns null if missing required p tag or wrong event kind', () {
      final noPTagEvent = Nip01Event(
        pubKey: authorHex,
        kind: 7654,
        tags: [
          ['context', 'hospitality'],
        ],
        content: 'No subject specified',
        createdAt: 1719234800,
      );
      expect(InteractionReference.fromNip01Event(noPTagEvent), isNull);

      final wrongKindEvent = Nip01Event(
        pubKey: authorHex,
        kind: 1,
        tags: [
          ['p', subjectHex],
        ],
        content: 'Normal note',
        createdAt: 1719234800,
      );
      expect(InteractionReference.fromNip01Event(wrongKindEvent), isNull);
    });

    test('toNip01Event generates event with kind 7654 and exactly one subject p tag', () {
      final ref = InteractionReference(
        id: '',
        authorPubkey: authorHex,
        subjectPubkey: subjectHex,
        content: 'Had a wonderful time staying with Bob.',
        createdAt: DateTime.fromMillisecondsSinceEpoch(1719234800 * 1000),
        contexts: ['hospitality'],
        role: 'guest',
        sentiment: 'positive',
        associatedAddress: listingCoord,
        tags: const ['communicative', 'clean'],
      );

      final event = ref.toNip01Event(authorPubkey: authorHex);
      expect(event.kind, 7654);
      expect(event.pubKey, authorHex);
      expect(event.content, 'Had a wonderful time staying with Bob.');

      final pTags = event.tags.where((t) => t.isNotEmpty && t[0] == 'p').toList();
      expect(pTags.length, 1);
      expect(pTags.first[1], subjectHex);

      final aTags = event.tags.where((t) => t.isNotEmpty && t[0] == 'a').toList();
      expect(aTags.length, 1);
      expect(aTags.first[1], listingCoord);

      final tTags = event.tags.where((t) => t.isNotEmpty && t[0] == 't').map((t) => t[1]).toList();
      expect(tTags, ['communicative', 'clean']);
    });

    test('Human-readable relationship direction format', () {
      final guestRef = InteractionReference(
        id: '1',
        authorPubkey: authorHex,
        subjectPubkey: subjectHex,
        content: 'Good host',
        createdAt: DateTime.now(),
        role: 'guest',
      );
      expect(
        guestRef.getRelationshipDescription(authorName: 'Alex', subjectName: 'Jordan'),
        'Alex stayed with Jordan',
      );

      final hostRef = InteractionReference(
        id: '2',
        authorPubkey: authorHex,
        subjectPubkey: subjectHex,
        content: 'Good guest',
        createdAt: DateTime.now(),
        role: 'host',
      );
      expect(
        hostRef.getRelationshipDescription(authorName: 'Jordan', subjectName: 'Alex'),
        'Jordan hosted Alex',
      );
    });

    test('Parses start and end date tags and formats interaction period', () {
      final startTimestamp = 1718064000; // June 11, 2024
      final endTimestamp = 1718496000;   // June 16, 2024

      final event = Nip01Event(
        pubKey: authorHex,
        kind: 7654,
        tags: [
          ['p', subjectHex],
          ['start', '$startTimestamp'],
          ['end', '$endTimestamp'],
        ],
        content: 'Stayed together for five days.',
        createdAt: 1719234800,
      );

      final ref = InteractionReference.fromNip01Event(event);
      expect(ref, isNotNull);
      expect(ref!.startDate, DateTime.fromMillisecondsSinceEpoch(startTimestamp * 1000));
      expect(ref.endDate, DateTime.fromMillisecondsSinceEpoch(endTimestamp * 1000));
      expect(ref.formattedInteractionPeriod, isNotNull);

      // Serialize back to Nip01Event
      final serialized = ref.toNip01Event(authorPubkey: authorHex);
      final startTag = serialized.tags.firstWhere((t) => t[0] == 'start');
      final endTag = serialized.tags.firstWhere((t) => t[0] == 'end');
      expect(startTag[1], '$startTimestamp');
      expect(endTag[1], '$endTimestamp');
    });

    test('Parses single start date tag and formats as month-year', () {
      final startTimestamp = 1686830400; // June 15, 2023

      final event = Nip01Event(
        pubKey: authorHex,
        kind: 7654,
        tags: [
          ['p', subjectHex],
          ['start', '$startTimestamp'],
        ],
        content: 'Met for coffee in June 2023.',
        createdAt: 1719234800,
      );

      final ref = InteractionReference.fromNip01Event(event);
      expect(ref, isNotNull);
      expect(ref!.startDate, DateTime.fromMillisecondsSinceEpoch(startTimestamp * 1000));
      expect(ref.endDate, isNull);
      expect(ref.formattedInteractionPeriod, 'Jun 2023');
    });
  });
}
