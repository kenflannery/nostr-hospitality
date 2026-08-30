import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../models/hospitality_listing.dart';
import '../../../widgets/user_avatar.dart';
import '../../messaging/screens/chat_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../references/screens/reference_composer_screen.dart';
import 'listing_editor_screen.dart';

/// Detailed view of a NIP-99 (Kind 30402) Hospitality Hosting Offer.
class ListingDetailScreen extends ConsumerWidget {
  final HospitalityListing listing;

  const ListingDetailScreen({
    super.key,
    required this.listing,
  });

  String _formatSleepingArrangement(String type) {
    switch (type) {
      case 'private_room':
        return 'Private Room';
      case 'shared_room':
        return 'Shared Room';
      case 'couch':
        return 'Couch / Sofa';
      case 'common_room':
        return 'Common Room';
      case 'tent_space':
        return 'Tent Camping Space';
      default:
        return type;
    }
  }

  String _formatParking(String parking) {
    switch (parking) {
      case 'free_on_premises':
        return 'Free Parking on Premises';
      case 'street':
        return 'Street Parking';
      case 'paid':
        return 'Paid Parking Nearby';
      case 'none':
        return 'No Parking';
      default:
        return parking;
    }
  }

  bool _hasAnyHostingPreferences() {
    return listing.hostsWithChildren != null ||
        listing.hostsWithPets != null ||
        listing.okayWithDrinking != null ||
        listing.okayWithSmoking != null ||
        listing.acceptLastMinute != null ||
        listing.wheelchairAccessible != null ||
        listing.tentCampingAvailable != null;
  }

  bool _hasAnyHomeDetails() {
    return listing.parking != null ||
        (listing.parkingDetails != null && listing.parkingDetails!.isNotEmpty) ||
        listing.hasHousemates != null ||
        listing.hasKids != null ||
        listing.hasPets != null ||
        listing.drinksAtHome != null ||
        listing.smokesAtHome != null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authState = ref.watch(authStateProvider).valueOrNull;
    final isOwnListing = authState?.pubkey == listing.authorPubkey;

    final hostProfileAsync = ref.watch(userProfileProvider(listing.authorPubkey));
    final hostProfile = hostProfileAsync.valueOrNull;
    final hostName = hostProfile?.bestName ?? listing.authorPubkey.substring(0, 8);

    final summaryAsync = ref.watch(userReferenceSummaryProvider(listing.authorPubkey));
    final summary = summaryAsync.valueOrNull;

    // Collect active highlight pills
    final highlightPills = <Widget>[];
    if (listing.sleepingArrangement != null) {
      highlightPills.add(
        _buildHighlightPill(
          theme,
          Icons.bed_rounded,
          _formatSleepingArrangement(listing.sleepingArrangement!),
        ),
      );
    }
    if (listing.maxGuests != null) {
      highlightPills.add(
        _buildHighlightPill(
          theme,
          Icons.people_outline_rounded,
          'Max ${listing.maxGuests} ${listing.maxGuests == 1 ? 'Guest' : 'Guests'}',
        ),
      );
    }
    if (listing.acceptLastMinute == true) {
      highlightPills.add(
        _buildHighlightPill(
          theme,
          Icons.flash_on_rounded,
          'Last-minute OK',
          color: Colors.amber[800],
        ),
      );
    }
    if (listing.wheelchairAccessible == true) {
      highlightPills.add(
        _buildHighlightPill(
          theme,
          Icons.accessible_rounded,
          'Wheelchair Accessible',
          color: Colors.blue[700],
        ),
      );
    }
    if (listing.tentCampingAvailable == true) {
      highlightPills.add(
        _buildHighlightPill(
          theme,
          Icons.terrain_rounded,
          'Tent Camping',
          color: Colors.green[700],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Accommodation Offer'),
        actions: [
          if (isOwnListing)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit Offer',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ListingEditorScreen(initialListing: listing),
                  ),
                );
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Header if present
            if (listing.images.isNotEmpty)
              Image.network(
                listing.images.first,
                width: double.infinity,
                height: 220,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),

            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status & Category Badges
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: listing.isActive
                              ? AppTheme.positiveGreen.withValues(alpha: 0.12)
                              : Colors.grey.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: listing.isActive ? AppTheme.positiveGreen : Colors.grey,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              listing.isActive ? 'Accepting Guests' : 'Inactive',
                              style: TextStyle(
                                color: listing.isActive ? AppTheme.positiveGreen : Colors.grey,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Hospitality Stay',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Title
                  Text(
                    listing.title,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Location and Geohash
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        listing.location,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (listing.privacyGeohash != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'g: ${listing.privacyGeohash}',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                      const Spacer(),
                      Text(
                        'Posted ${DateFormatter.formatShort(listing.createdAt)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ),

                  if (highlightPills.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: highlightPills,
                    ),
                  ],

                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Host Profile Card
                  InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ProfileScreen(pubkey: listing.authorPubkey),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          UserAvatar(
                            imageUrl: hostProfile?.picture,
                            nameOrPubkey: hostName,
                            radius: 28,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hosted by $hostName',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (hostProfile?.nip05 != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    hostProfile!.nip05!,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ],
                                if (summary != null && summary.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    '${summary.totalCount} references • ${summary.positiveCount} positive',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: AppTheme.positiveGreen,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Action Buttons: Message Host & Leave Reference
                  if (!isOwnListing)
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ChatScreen(
                                    recipientPubkey: listing.authorPubkey,
                                    recipientName: hostName,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.mail_outline_rounded),
                            label: const Text('Message Host'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ReferenceComposerScreen(
                                  subjectPubkey: listing.authorPubkey,
                                  subjectName: hostName,
                                  initialListing: listing,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.rate_review_outlined),
                          label: const Text('Reference'),
                        ),
                      ],
                    ),

                  // Hosting Preferences & House Rules Section (Rendered only if tags present)
                  if (_hasAnyHostingPreferences()) ...[
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),
                    Text(
                      'Hosting Preferences',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      margin: EdgeInsets.zero,
                      color: theme.colorScheme.surfaceContainerLow,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            if (listing.acceptLastMinute != null)
                              _buildDetailRow(
                                theme,
                                Icons.flash_on_rounded,
                                'Accepts Last-Minute Requests',
                                listing.acceptLastMinute! ? 'Yes' : 'No',
                                isPositive: listing.acceptLastMinute,
                              ),
                            if (listing.wheelchairAccessible != null) ...[
                              if (listing.acceptLastMinute != null) const Divider(height: 16),
                              _buildDetailRow(
                                theme,
                                Icons.accessible_rounded,
                                'Wheelchair Accessible',
                                listing.wheelchairAccessible! ? 'Yes' : 'No',
                                isPositive: listing.wheelchairAccessible,
                              ),
                            ],
                            if (listing.tentCampingAvailable != null) ...[
                              const Divider(height: 16),
                              _buildDetailRow(
                                theme,
                                Icons.terrain_rounded,
                                'Tent Camping Space',
                                listing.tentCampingAvailable! ? 'Available' : 'No',
                              ),
                            ],
                            if (listing.hostsWithChildren != null) ...[
                              const Divider(height: 16),
                              _buildDetailRow(
                                theme,
                                Icons.child_care_rounded,
                                'Hosts with Children',
                                listing.hostsWithChildren! ? 'Yes' : 'No',
                                isPositive: listing.hostsWithChildren,
                              ),
                            ],
                            if (listing.hostsWithPets != null) ...[
                              const Divider(height: 16),
                              _buildDetailRow(
                                theme,
                                Icons.pets_rounded,
                                'Hosts with Pets',
                                listing.hostsWithPets! ? 'Yes' : 'No',
                                isPositive: listing.hostsWithPets,
                              ),
                            ],
                            if (listing.okayWithDrinking != null) ...[
                              const Divider(height: 16),
                              _buildDetailRow(
                                theme,
                                Icons.local_bar_rounded,
                                'Drinking Allowed',
                                listing.okayWithDrinking! ? 'Yes' : 'No',
                              ),
                            ],
                            if (listing.okayWithSmoking != null) ...[
                              const Divider(height: 16),
                              _buildDetailRow(
                                theme,
                                Icons.smoke_free_rounded,
                                'Smoking Policy',
                                listing.okayWithSmoking == 'no'
                                    ? 'No Smoking'
                                    : listing.okayWithSmoking == 'outside'
                                        ? 'Outside Only'
                                        : 'Allowed',
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],

                  // My Home & Environment Section (Rendered only if tags present)
                  if (_hasAnyHomeDetails()) ...[
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),
                    Text(
                      'My Home & Household',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      margin: EdgeInsets.zero,
                      color: theme.colorScheme.surfaceContainerLow,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            if (listing.parking != null)
                              _buildDetailRow(
                                theme,
                                Icons.local_parking_rounded,
                                'Parking',
                                _formatParking(listing.parking!),
                              ),
                            if (listing.parkingDetails != null && listing.parkingDetails!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'ℹ️ ${listing.parkingDetails}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                            if (listing.hasHousemates != null) ...[
                              if (listing.parking != null) const Divider(height: 16),
                              _buildDetailRow(
                                theme,
                                Icons.group_outlined,
                                'Has Roommates / Housemates',
                                listing.hasHousemates! ? 'Yes' : 'No',
                              ),
                            ],
                            if (listing.hasKids != null) ...[
                              const Divider(height: 16),
                              _buildDetailRow(
                                theme,
                                Icons.family_restroom_rounded,
                                'Kids in Household',
                                listing.hasKids! ? 'Yes' : 'No',
                              ),
                            ],
                            if (listing.hasPets != null) ...[
                              const Divider(height: 16),
                              _buildDetailRow(
                                theme,
                                Icons.cruelty_free_rounded,
                                'Pets in Household',
                                listing.hasPets! ? 'Yes' : 'No',
                              ),
                            ],
                            if (listing.drinksAtHome != null) ...[
                              const Divider(height: 16),
                              _buildDetailRow(
                                theme,
                                Icons.liquor_rounded,
                                'Host Drinks at Home',
                                listing.drinksAtHome! ? 'Yes' : 'No',
                              ),
                            ],
                            if (listing.smokesAtHome != null) ...[
                              const Divider(height: 16),
                              _buildDetailRow(
                                theme,
                                Icons.smoking_rooms_rounded,
                                'Host Smokes at Home',
                                listing.smokesAtHome == 'no'
                                    ? 'No'
                                    : listing.smokesAtHome == 'outside'
                                        ? 'Outside Only'
                                        : 'Yes',
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Content / Description
                  Text(
                    'About This Hospitality Offer',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SelectableText(
                    listing.content,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      height: 1.6,
                      fontSize: 15,
                    ),
                  ),

                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Protocol Coordinate Info
                  Text(
                    'Nostr Protocol Coordinate',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.outline,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  SelectableText(
                    listing.addressCoordinate,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: theme.colorScheme.outline,
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHighlightPill(ThemeData theme, IconData icon, String label, {Color? color}) {
    final effectiveColor = color ?? theme.colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: effectiveColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: effectiveColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: effectiveColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: effectiveColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(ThemeData theme, IconData icon, String title, String value, {bool? isPositive}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 14),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isPositive == true
                ? AppTheme.positiveGreen
                : isPositive == false
                    ? theme.colorScheme.onSurfaceVariant
                    : theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
