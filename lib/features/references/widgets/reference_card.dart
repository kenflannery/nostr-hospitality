import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../models/interaction_reference.dart';
import '../../../widgets/role_badge.dart';
import '../../../widgets/sentiment_badge.dart';
import '../../../widgets/user_avatar.dart';
import '../../listings/screens/listing_detail_screen.dart';
import '../../profile/screens/profile_screen.dart';

/// Renders a human-readable card for an [InteractionReference] (Kind 7654).
class ReferenceCard extends ConsumerWidget {
  final InteractionReference reference;
  final String? subjectName;

  const ReferenceCard({
    super.key,
    required this.reference,
    this.subjectName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authorProfileAsync = ref.watch(userProfileProvider(reference.authorPubkey));
    final authorProfile = authorProfileAsync.valueOrNull;
    final authorName = authorProfile?.bestName ?? 'Traveler';

    final relationshipDesc = reference.getRelationshipDescription(
      authorName: authorName,
      subjectName: subjectName ?? 'Host',
    );

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: Author avatar, name, relationship direction, date
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                UserAvatar(
                  imageUrl: authorProfile?.picture,
                  nameOrPubkey: authorName,
                  radius: 20,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ProfileScreen(pubkey: reference.authorPubkey),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ProfileScreen(pubkey: reference.authorPubkey),
                            ),
                          );
                        },
                        child: Text(
                          authorName,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        relationshipDesc,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  DateFormatter.formatRelative(reference.createdAt),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Badges row: Sentiment, Role, Context
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                if (reference.sentiment != null)
                  SentimentBadge(sentiment: reference.sentiment, compact: true),
                if (reference.role != null)
                  RoleBadge(role: reference.role),
                if (reference.contexts.isNotEmpty && !reference.isHospitality)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      reference.primaryContext,
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // Content text
            SelectableText(
              reference.content,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.45,
              ),
            ),

            // Interaction trait tags (t tags)
            if (reference.tags.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: reference.tags.map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.tag_rounded,
                          size: 12,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          tag,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],

            // Associated NIP-99 listing chip if present
            if (reference.associatedAddress != null &&
                reference.associatedAddress!.isNotEmpty) ...[
              const SizedBox(height: 12),
              InkWell(
                onTap: () => _openAssociatedListing(context, ref, reference.associatedAddress!),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.home_work_outlined,
                        size: 14,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Associated Hosting Offer',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 14,
                        color: theme.colorScheme.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _openAssociatedListing(BuildContext context, WidgetRef ref, String coordinate) async {
    final repo = ref.read(listingRepositoryProvider);
    final listing = await repo.getListingByCoordinate(coordinate);
    if (context.mounted) {
      if (listing != null) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ListingDetailScreen(listing: listing),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Listing is no longer available on relays')),
        );
      }
    }
  }
}
