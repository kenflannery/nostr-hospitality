import 'interaction_reference.dart';
import '../core/constants/nostr_constants.dart';

/// Aggregated factual statistics for references received by a user.
///
/// NOTE: Star ratings, numeric scores, and weighted averages are intentionally NOT used.
/// Missing sentiments are strictly omitted from sentiment totals and NOT counted as neutral.
class ReferenceSummary {
  final int totalCount;
  final int positiveCount;
  final int neutralCount;
  final int negativeCount;
  final int missingSentimentCount;

  final int hostedCount; // Author was guest, subject was host
  final int guestCount; // Author was host, subject was guest
  final int metCount; // Context was meeting / other
  final Map<String, int> roleCounts;

  const ReferenceSummary({
    this.totalCount = 0,
    this.positiveCount = 0,
    this.neutralCount = 0,
    this.negativeCount = 0,
    this.missingSentimentCount = 0,
    this.hostedCount = 0,
    this.guestCount = 0,
    this.metCount = 0,
    this.roleCounts = const {},
  });

  /// Computes a [ReferenceSummary] from a list of [InteractionReference]s received by a user.
  factory ReferenceSummary.fromReferences(List<InteractionReference> references) {
    int positive = 0;
    int neutral = 0;
    int negative = 0;
    int missing = 0;

    int hosted = 0;
    int guest = 0;
    int met = 0;
    final roles = <String, int>{};

    for (final ref in references) {
      // Sentiment aggregation
      if (ref.sentiment == NostrConstants.sentimentPositive) {
        positive++;
      } else if (ref.sentiment == NostrConstants.sentimentNeutral) {
        neutral++;
      } else if (ref.sentiment == NostrConstants.sentimentNegative) {
        negative++;
      } else {
        missing++; // Missing sentiment MUST NOT be counted as neutral
      }

      // Role & context aggregation
      final role = ref.role;
      if (role != null && role.isNotEmpty) {
        roles[role] = (roles[role] ?? 0) + 1;
        if (role == NostrConstants.roleGuest) {
          // The author was guest -> the subject was host
          hosted++;
        } else if (role == NostrConstants.roleHost) {
          // The author was host -> the subject was guest
          guest++;
        }
      } else if (ref.contexts.contains(NostrConstants.contextMeeting)) {
        met++;
      }
    }

    return ReferenceSummary(
      totalCount: references.length,
      positiveCount: positive,
      neutralCount: neutral,
      negativeCount: negative,
      missingSentimentCount: missing,
      hostedCount: hosted,
      guestCount: guest,
      metCount: met,
      roleCounts: roles,
    );
  }

  bool get isEmpty => totalCount == 0;
  bool get isNotEmpty => totalCount > 0;
}
