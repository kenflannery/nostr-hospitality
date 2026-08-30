import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/nip19_utils.dart';
import '../../../models/travel_profile.dart';
import '../../../models/user_profile.dart';
import '../../../widgets/user_avatar.dart';
import '../../auth/screens/login_screen.dart';
import '../../listings/screens/listing_detail_screen.dart';
import '../../listings/screens/listing_editor_screen.dart';
import '../../messaging/screens/chat_screen.dart';
import '../../references/screens/reference_composer_screen.dart';
import '../../references/widgets/reference_card.dart';
import '../../settings/screens/settings_screen.dart';
import 'edit_profile_screen.dart';
import 'travel_profile_editor_screen.dart';

/// User Profile Screen displaying Kind 0 metadata, Kind 30602 Travel Profile,
/// Kind 30402 hosting offer, and Kind 7654 references.
class ProfileScreen extends ConsumerWidget {
  final String? pubkey; // If null, displays current user's profile

  const ProfileScreen({super.key, this.pubkey});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authState = ref.watch(authStateProvider).valueOrNull;
    final isOwnProfile = pubkey == null || pubkey == authState?.pubkey;
    final targetPubkey = pubkey ?? authState?.pubkey;

    if (targetPubkey == null || (isOwnProfile && !(authState?.isAuthenticated ?? false))) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Profile')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.account_circle_outlined,
                  size: 64,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Not Authenticated',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in with your Nostr keys to manage your profile and hosting offer.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  },
                  child: const Text('Sign In / Generate Keys'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final profileAsync = ref.watch(userProfileProvider(targetPubkey));
    final travelProfileAsync = ref.watch(userTravelProfileProvider(targetPubkey));
    final listingAsync = ref.watch(authorListingProvider(targetPubkey));
    final summaryAsync = ref.watch(userReferenceSummaryProvider(targetPubkey));
    final referencesStream = ref.watch(userReferencesStreamProvider(targetPubkey));

    final profile = profileAsync.valueOrNull ?? UserProfile(pubkey: targetPubkey);
    final travelProfile = travelProfileAsync.valueOrNull;
    final listing = listingAsync.valueOrNull;
    final summary = summaryAsync.valueOrNull;
    final references = referencesStream.valueOrNull ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(isOwnProfile ? 'My Profile' : profile.bestName),
        actions: [
          if (isOwnProfile) ...[
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              tooltip: 'Settings & Relays',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
            ),
          ],
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(userProfileProvider(targetPubkey));
          ref.invalidate(userTravelProfileProvider(targetPubkey));
          ref.invalidate(authorListingProvider(targetPubkey));
          ref.invalidate(userReferenceSummaryProvider(targetPubkey));
          ref.invalidate(userReferencesStreamProvider(targetPubkey));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Banner Image if present
              if (profile.banner != null && profile.banner!.isNotEmpty)
                Image.network(
                  profile.banner!,
                  width: double.infinity,
                  height: 140,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),

              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header: Avatar, Name, NIP-05, Key
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        UserAvatar(
                          imageUrl: profile.picture,
                          nameOrPubkey: profile.bestName,
                          radius: 36,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                profile.bestName,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (profile.nip05 != null && profile.nip05!.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.verified_rounded,
                                      size: 16,
                                      color: theme.colorScheme.primary,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        profile.nip05!,
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: theme.colorScheme.primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    Nip19Helper.shortenKey(profile.npub),
                                    style: TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 12,
                                      color: theme.colorScheme.outline,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  IconButton(
                                    icon: const Icon(Icons.copy_rounded, size: 14),
                                    tooltip: 'Copy npub',
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () {
                                      Nip19Helper.shortenKey(profile.npub);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('npub copied to clipboard!')),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Active Interaction Modes (Kind 30602)
                    if (travelProfile != null && travelProfile.modes.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: travelProfile.modes.map((m) => _buildModePill(theme, m)).toList(),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // Action Buttons (Edit Profile / Message / Reference)
                    Row(
                      children: [
                        if (isOwnProfile) ...[
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => EditProfileScreen(currentProfile: profile),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              label: const Text('Edit Identity (Kind 0)'),
                            ),
                          ),
                        ] else ...[
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => ChatScreen(
                                      recipientPubkey: targetPubkey,
                                      recipientName: profile.bestName,
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.mail_outline_rounded, size: 18),
                              label: const Text('Message'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => ReferenceComposerScreen(
                                      subjectPubkey: targetPubkey,
                                      subjectName: profile.bestName,
                                      initialListing: listing,
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.rate_review_outlined, size: 18),
                              label: const Text('Leave Reference'),
                            ),
                          ),
                        ],
                      ],
                    ),

                    if (profile.about != null && profile.about!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      SelectableText(
                        profile.about!,
                        style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                      ),
                    ],

                    if (profile.website != null && profile.website!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.language_rounded, size: 14, color: theme.colorScheme.outline),
                          const SizedBox(width: 6),
                          Text(
                            profile.website!,
                            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary),
                          ),
                        ],
                      ),
                    ],

                    // --- SECTION: Kind 30602 Travel & Community Profile ---
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Icon(Icons.travel_explore_rounded, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Travel & Community Profile',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        if (isOwnProfile)
                          TextButton.icon(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => TravelProfileEditorScreen(initialProfile: travelProfile),
                                ),
                              );
                            },
                            icon: Icon(travelProfile == null ? Icons.add_rounded : Icons.edit_outlined, size: 16),
                            label: Text(travelProfile == null ? 'Set Up' : 'Edit'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    if (travelProfile != null && travelProfile.isNotEmpty)
                      _buildTravelProfileCard(context, theme, travelProfile)
                    else if (isOwnProfile)
                      Card(
                        margin: EdgeInsets.zero,
                        color: theme.colorScheme.surfaceContainerLow,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Set Up Your Travel & Community Profile (Kind 30602)',
                                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Share your languages, travel philosophy, home base, and link your Couchsurfing/Trustroots accounts without clobbering your global Nostr profile.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 12),
                              FilledButton.tonalIcon(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const TravelProfileEditorScreen(),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.badge_outlined, size: 16),
                                label: const Text('Complete Travel Profile'),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          'This traveler has not published a Kind 30602 travel profile yet.',
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                        ),
                      ),

                    // --- SECTION: Hosting Offer ---
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Icon(
                          Icons.roofing_rounded,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Hosting Offer',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        if (isOwnProfile)
                          TextButton.icon(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ListingEditorScreen(initialListing: listing),
                                ),
                              );
                            },
                            icon: Icon(listing == null ? Icons.add : Icons.edit, size: 16),
                            label: Text(listing == null ? 'Create Offer' : 'Edit'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    if (listing != null)
                      Card(
                        margin: EdgeInsets.zero,
                        color: theme.colorScheme.surfaceContainerLow,
                        child: InkWell(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ListingDetailScreen(listing: listing),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: listing.isActive
                                            ? AppTheme.positiveGreen.withValues(alpha: 0.12)
                                            : Colors.grey.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        listing.isActive ? 'Accepting Guests' : 'Inactive',
                                        style: TextStyle(
                                          color: listing.isActive ? AppTheme.positiveGreen : Colors.grey,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    Icon(
                                      Icons.location_on_outlined,
                                      size: 14,
                                      color: theme.colorScheme.primary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      listing.location,
                                      style: TextStyle(
                                        color: theme.colorScheme.onSurfaceVariant,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  listing.title,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  listing.summary,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          isOwnProfile
                              ? 'You have not published a hosting offer yet. Tap "Create Offer" to open your home to travelers.'
                              : 'This user does not currently have an active hosting offer.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ),

                    const SizedBox(height: 28),
                    const Divider(),
                    const SizedBox(height: 16),

                    // References & Reputation Section (Kind 7654)
                    Row(
                      children: [
                        Icon(
                          Icons.rate_review_outlined,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Interaction References',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        if (!isOwnProfile)
                          TextButton.icon(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ReferenceComposerScreen(
                                    subjectPubkey: targetPubkey,
                                    subjectName: profile.bestName,
                                    initialListing: listing,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Add Reference'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Factual Reference Summary
                    if (summary != null && summary.isNotEmpty)
                      _buildSummaryCard(theme, summary),

                    const SizedBox(height: 16),

                    // References Stream List
                    if (references.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24.0),
                          child: Text(
                            'No references published yet for this user.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: references.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          return ReferenceCard(reference: references[index]);
                        },
                      ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModePill(ThemeData theme, String mode) {
    String label;
    IconData icon;
    Color color = theme.colorScheme.primary;

    switch (mode) {
      case 'host':
        label = 'Host';
        icon = Icons.home_rounded;
        break;
      case 'guest':
        label = 'Traveler';
        icon = Icons.backpack_rounded;
        break;
      case 'meetup':
        label = 'Meetups';
        icon = Icons.coffee_rounded;
        break;
      case 'rideshare':
        label = 'Rideshare';
        icon = Icons.directions_car_rounded;
        break;
      case 'language_exchange':
        label = 'Language Exchange';
        icon = Icons.forum_rounded;
        break;
      default:
        label = mode;
        icon = Icons.star_outline_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTravelProfileCard(BuildContext context, ThemeData theme, TravelProfile travelProfile) {
    return Card(
      margin: EdgeInsets.zero,
      color: theme.colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Travel story/content
            if (travelProfile.content.trim().isNotEmpty) ...[
              Text(
                travelProfile.content,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
              ),
              const SizedBox(height: 16),
            ],

            // Demographics & Origins
            if (travelProfile.formattedOrigin != null ||
                travelProfile.formattedHome != null ||
                travelProfile.gender != null ||
                travelProfile.calculatedAge != null ||
                travelProfile.occupation != null) ...[
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  if (travelProfile.formattedHome != null)
                    _buildInfoBadge(theme, Icons.place_outlined, 'Lives in ${travelProfile.formattedHome}'),
                  if (travelProfile.formattedOrigin != null)
                    _buildInfoBadge(theme, Icons.flight_takeoff_rounded, 'From ${travelProfile.formattedOrigin}'),
                  if (travelProfile.gender != null)
                    _buildInfoBadge(theme, Icons.person_outline_rounded, travelProfile.gender![0].toUpperCase() + travelProfile.gender!.substring(1)),
                  if (travelProfile.calculatedAge != null)
                    _buildInfoBadge(theme, Icons.cake_outlined, '~${travelProfile.calculatedAge} yrs old'),
                  if (travelProfile.occupation != null)
                    _buildInfoBadge(theme, Icons.work_outline_rounded, travelProfile.occupation!),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Languages
            if (travelProfile.languages.isNotEmpty) ...[
              Text('Languages', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: travelProfile.languages.map((l) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      l.displayName,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
            ],

            // Interests
            if (travelProfile.interests.isNotEmpty) ...[
              Text('Interests', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: travelProfile.interests.map((t) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '#$t',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
            ],

            // Linked Verifications (NIP-39)
            if (travelProfile.externalIdentities.isNotEmpty) ...[
              Text('Verified & Linked Networks', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: travelProfile.externalIdentities.map((id) {
                  return InkWell(
                    onTap: id.url.isNotEmpty
                        ? () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Profile link: ${id.url}')),
                            );
                          }
                        : null,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: theme.colorScheme.outlineVariant),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.link_rounded, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            '${id.platformName}: @${id.username}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBadge(ThemeData theme, IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(ThemeData theme, dynamic summary) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem(
            theme,
            count: summary.totalCount,
            label: 'Total References',
            color: theme.colorScheme.primary,
          ),
          _buildSummaryItem(
            theme,
            count: summary.positiveCount,
            label: 'Positive',
            color: AppTheme.positiveGreen,
          ),
          _buildSummaryItem(
            theme,
            count: summary.asHostCount,
            label: 'As Host',
            color: theme.colorScheme.secondary,
          ),
          _buildSummaryItem(
            theme,
            count: summary.asGuestCount,
            label: 'As Guest',
            color: theme.colorScheme.tertiary,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
    ThemeData theme, {
    required int count,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
