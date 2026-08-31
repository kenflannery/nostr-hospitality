import 'package:flutter_test/flutter_test.dart';
import 'package:nostr_hospitality/models/interaction_reference.dart';
import 'package:nostr_hospitality/models/reference_summary.dart';

void main() {
  group('ReferenceSummary Aggregation Tests', () {
    const subjectHex = 'c6047f9441ed7d6d3045406e95c07cd85c778e4b8cef3ca7abac09b95c709ee5';

    test('Computes factual aggregation accurately and handles missing sentiment correctly', () {
      final references = [
        InteractionReference(
          id: '1',
          authorPubkey: 'author1',
          subjectPubkey: subjectHex,
          content: 'Great host!',
          createdAt: DateTime.now(),
          sentiment: 'positive',
          role: 'guest',
        ),
        InteractionReference(
          id: '2',
          authorPubkey: 'author2',
          subjectPubkey: subjectHex,
          content: 'Very accommodating',
          createdAt: DateTime.now(),
          sentiment: 'positive',
          role: 'guest',
        ),
        InteractionReference(
          id: '3',
          authorPubkey: 'author3',
          subjectPubkey: subjectHex,
          content: 'Average stay',
          createdAt: DateTime.now(),
          sentiment: 'neutral',
          role: 'guest',
        ),
        InteractionReference(
          id: '4',
          authorPubkey: 'author4',
          subjectPubkey: subjectHex,
          content: 'Host was unavailable',
          createdAt: DateTime.now(),
          sentiment: 'negative',
          role: 'guest',
        ),
        InteractionReference(
          id: '5',
          authorPubkey: 'author5',
          subjectPubkey: subjectHex,
          content: 'Met while traveling, no sentiment specified',
          createdAt: DateTime.now(),
          sentiment: null, // missing sentiment
          contexts: ['meeting'],
        ),
        InteractionReference(
          id: '6',
          authorPubkey: 'author6',
          subjectPubkey: subjectHex,
          content: 'Alice was a wonderful guest to host',
          createdAt: DateTime.now(),
          sentiment: 'positive',
          role: 'host',
        ),
      ];

      final summary = ReferenceSummary.fromReferences(references);

      expect(summary.totalCount, 6);
      expect(summary.positiveCount, 3);
      expect(summary.neutralCount, 1);
      expect(summary.negativeCount, 1);
      expect(summary.missingSentimentCount, 1); // strictly counted as missing, NOT neutral

      // Role aggregation
      expect(summary.hostedCount, 4); // 4 guests stayed with this host
      expect(summary.asHostCount, 4);
      expect(summary.guestCount, 1); // 1 host hosted this user
      expect(summary.asGuestCount, 1);
      expect(summary.metCount, 1); // 1 meeting context
    });
  });
}
