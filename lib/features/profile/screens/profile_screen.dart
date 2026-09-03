import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/nip19_utils.dart';
import '../../../models/travel_profile.dart';
import '../../../models/user_profile.dart';
import '../../../widgets/raw_event_viewer_dialog.dart';
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

    if (targetPubkey == null ||
        (isOwnProfile && !(authState?.isAuthenticated ?? false))) {
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
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
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
    final travelProfileAsync =
        ref.watch(userTravelProfileProvider(targetPubkey));
    final lastActiveAsync = ref.watch(userLastActiveProvider(targetPubkey));
    final listingAsync = ref.watch(authorListingProvider(targetPubkey));
    final authorListingsAsync =
        ref.watch(authorListingsStreamProvider(targetPubkey));
    final summaryAsync = ref.watch(userReferenceSummaryProvider(targetPubkey));
    final referencesStream =
        ref.watch(userReferencesStreamProvider(targetPubkey));

    final profile =
        profileAsync.valueOrNull ?? UserProfile(pubkey: targetPubkey);
    final travelProfile = travelProfileAsync.valueOrNull;
    final lastActive = lastActiveAsync.valueOrNull;
    final listing = listingAsync.valueOrNull;
    final allAuthorListings =
        authorListingsAsync.valueOrNull ?? (listing != null ? [listing] : []);
    final hostingOffer =
        allAuthorListings.where((l) => l.isOffer).firstOrNull ?? listing;
    final travelRequests = allAuthorListings.where((l) => l.isRequest).toList();
    final summary = summaryAsync.valueOrNull;
    final references = referencesStream.valueOrNull ?? [];

    final hasTravelName =
        travelProfile?.name != null && travelProfile!.name!.trim().isNotEmpty;
    final primaryName =
        hasTravelName ? travelProfile.name!.trim() : profile.bestName;
    final kind0Name = profile.bestName;
    final showKind0Subtitle = hasTravelName &&
        kind0Name.trim().isNotEmpty &&
        kind0Name.trim().toLowerCase() != primaryName.toLowerCase();

    return Scaffold(
      appBar: AppBar(
        title: Text(isOwnProfile ? 'My Profile' : primaryName),
        actions: [
          if (isOwnProfile)
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              tooltip: 'Settings & Relays',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
            ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            tooltip: 'More options & Developer data',
            onSelected: (value) {
              if (value == 'raw_kind0') {
                showRawEventDialog(
                  context,
                  title: 'Kind 0 Metadata ($primaryName)',
                  event: profile,
                  description: 'NIP-01 User Metadata Event',
                );
              } else if (value == 'raw_kind30602' && travelProfile != null) {
                showRawEventDialog(
                  context,
                  title: 'Kind 30602 Travel Profile',
                  event: travelProfile,
                  description: 'Travel & Community Profile Event',
                );
              } else if (value == 'raw_kind30402' && hostingOffer != null) {
                showRawEventDialog(
                  context,
                  title: 'Kind 30402 Hosting Offer',
                  event: hostingOffer,
                  description: 'NIP-99 Classified Listing Event',
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'raw_kind0',
                child: Row(
                  children: [
                    Icon(Icons.code_rounded, size: 18),
                    SizedBox(width: 8),
                    Expanded(child: Text('Raw Profile (Kind 0)')),
                  ],
                ),
              ),
              if (travelProfile != null)
                const PopupMenuItem(
                  value: 'raw_kind30602',
                  child: Row(
                    children: [
                      Icon(Icons.code_rounded, size: 18),
                      SizedBox(width: 8),
                      Expanded(child: Text('Raw Travel Profile (30602)')),
                    ],
                  ),
                ),
              if (hostingOffer != null)
                const PopupMenuItem(
                  value: 'raw_kind30402',
                  child: Row(
                    children: [
                      Icon(Icons.code_rounded, size: 18),
                      SizedBox(width: 8),
                      Expanded(child: Text('Raw Hosting Offer (30402)')),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(userProfileProvider(targetPubkey));
          ref.invalidate(userTravelProfileProvider(targetPubkey));
          ref.invalidate(userLastActiveProvider(targetPubkey));
          ref.invalidate(authorListingProvider(targetPubkey));
          ref.invalidate(authorListingsStreamProvider(targetPubkey));
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
                          nameOrPubkey: primaryName,
                          radius: 36,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                primaryName,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (showKind0Subtitle) ...[
                                const SizedBox(height: 2),
                                Text(
                                  kind0Name,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                              if (profile.nip05 != null &&
                                  profile.nip05!.isNotEmpty) ...[
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
                                        style:
                                            theme.textTheme.bodySmall?.copyWith(
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
                                    icon: const Icon(Icons.copy_rounded,
                                        size: 14),
                                    tooltip: 'Copy npub',
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () {
                                      Nip19Helper.shortenKey(profile.npub);
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'npub copied to clipboard!')),
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

                    // Badges: Active on Nostr, Traveler Nickname & Current Location
                    if (lastActive != null ||
                        (travelProfile != null &&
                            (travelProfile.name != null ||
                                travelProfile.formattedCurrent != null))) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          if (lastActive != null)
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => _showActivityExplanationDialog(
                                  context,
                                  lastActive,
                                  theme,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: theme
                                        .colorScheme.surfaceContainerHighest
                                        .withValues(alpha: 0.6),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: theme.colorScheme.outlineVariant
                                          .withValues(alpha: 0.5),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.bolt_rounded,
                                        size: 14,
                                        color: theme.colorScheme.primary,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Active on Nostr ${DateFormatter.formatRelative(lastActive)}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: theme
                                              .colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(
                                        Icons.info_outline_rounded,
                                        size: 12,
                                        color: theme.colorScheme.outline,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          if (travelProfile != null &&
                              travelProfile.name != null &&
                              travelProfile.name!.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer
                                    .withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                    color: theme.colorScheme.primary
                                        .withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.badge_outlined,
                                      size: 14,
                                      color: theme.colorScheme.primary),
                                  const SizedBox(width: 4),
                                  Text(
                                    travelProfile.name!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (travelProfile != null &&
                              travelProfile.formattedCurrent != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.secondaryContainer
                                    .withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                    color: theme.colorScheme.secondary
                                        .withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.explore_outlined,
                                      size: 14,
                                      color: theme.colorScheme.secondary),
                                  const SizedBox(width: 4),
                                  Text(
                                    'In ${travelProfile.formattedCurrent}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: theme
                                          .colorScheme.onSecondaryContainer,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
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
                                    builder: (_) => EditProfileScreen(
                                        currentProfile: profile),
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
                                      recipientName: primaryName,
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.mail_outline_rounded,
                                  size: 18),
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
                                      subjectName: primaryName,
                                      initialListing: listing,
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.rate_review_outlined,
                                  size: 18),
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
                        style:
                            theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                      ),
                    ],

                    if (profile.website != null &&
                        profile.website!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () async {
                          final rawUrl = profile.website!.trim();
                          final formattedUrl = rawUrl.startsWith('http')
                              ? rawUrl
                              : 'https://$rawUrl';
                          final uri = Uri.tryParse(formattedUrl);
                          if (uri != null) {
                            try {
                              await launchUrl(uri,
                                  mode: LaunchMode.externalApplication);
                            } catch (_) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content:
                                          Text('Could not open: $formattedUrl')),
                                );
                              }
                            }
                          }
                        },
                        borderRadius: BorderRadius.circular(6),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.language_rounded,
                                  size: 14, color: theme.colorScheme.primary),
                              const SizedBox(width: 6),
                              Text(
                                profile.website!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    // --- SECTION: Kind 30602 Travel & Community Profile ---
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Icon(Icons.travel_explore_rounded,
                            color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Travel & Community Profile',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        if (isOwnProfile)
                          TextButton.icon(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => TravelProfileEditorScreen(
                                      initialProfile: travelProfile),
                                ),
                              );
                            },
                            icon: Icon(
                                travelProfile == null
                                    ? Icons.add_rounded
                                    : Icons.edit_outlined,
                                size: 16),
                            label:
                                Text(travelProfile == null ? 'Set Up' : 'Edit'),
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
                                style: theme.textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Share your travel bio & photo(s), languages spoken, home base, and link your other travel networks like Couchsurfing, Trustroots, Trip Hopping, etc.',
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
                                      builder: (_) =>
                                          const TravelProfileEditorScreen(),
                                    ),
                                  );
                                },
                                icon:
                                    const Icon(Icons.badge_outlined, size: 16),
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
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: theme.colorScheme.outline),
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
                                  builder: (_) => ListingEditorScreen(
                                      initialListing: hostingOffer,
                                      initialIsRequest: false),
                                ),
                              );
                            },
                            icon: Icon(
                                hostingOffer == null ? Icons.add : Icons.edit,
                                size: 16),
                            label: Text(
                                hostingOffer == null ? 'Create Offer' : 'Edit'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    if (hostingOffer != null)
                      Card(
                        margin: EdgeInsets.zero,
                        color: theme.colorScheme.surfaceContainerLow,
                        child: InkWell(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    ListingDetailScreen(listing: hostingOffer),
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
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: hostingOffer.isActive
                                            ? AppTheme.positiveGreen
                                                .withValues(alpha: 0.12)
                                            : Colors.grey
                                                .withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        hostingOffer.isActive
                                            ? 'Accepting Guests'
                                            : 'Inactive',
                                        style: TextStyle(
                                          color: hostingOffer.isActive
                                              ? AppTheme.positiveGreen
                                              : Colors.grey,
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
                                      hostingOffer.location,
                                      style: TextStyle(
                                        color:
                                            theme.colorScheme.onSurfaceVariant,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  hostingOffer.title,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (hostingOffer.isDateConstrained) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.calendar_today_rounded,
                                          size: 12,
                                          color: theme.colorScheme.primary),
                                      const SizedBox(width: 4),
                                      Text(
                                        DateFormatter.formatDateRange(
                                            hostingOffer.startDate,
                                            hostingOffer.endDate),
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                const SizedBox(height: 4),
                                Text(
                                  hostingOffer.summary,
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

                    // --- SECTION: Travel Requests / Public Trips ---
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        const Icon(
                          Icons.luggage_rounded,
                          color: Colors.teal,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Travel Requests & Trips',
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
                                  builder: (_) => const ListingEditorScreen(
                                      initialIsRequest: true),
                                ),
                              );
                            },
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Post Request'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    if (travelRequests.isNotEmpty) ...[
                      ...travelRequests.map((req) => Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Card(
                              margin: EdgeInsets.zero,
                              color: theme.colorScheme.surfaceContainerLow,
                              child: InkWell(
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          ListingDetailScreen(listing: req),
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: req.isActive
                                                  ? Colors.teal
                                                      .withValues(alpha: 0.15)
                                                  : Colors.grey
                                                      .withValues(alpha: 0.12),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              req.isActive
                                                  ? 'Active Trip'
                                                  : 'Closed',
                                              style: TextStyle(
                                                color: req.isActive
                                                    ? Colors.teal
                                                    : Colors.grey,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ),
                                          const Spacer(),
                                          const Icon(
                                            Icons.location_on_outlined,
                                            size: 14,
                                            color: Colors.teal,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            req.location,
                                            style: TextStyle(
                                              color: theme
                                                  .colorScheme.onSurfaceVariant,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        req.title,
                                        style: theme.textTheme.titleSmall
                                            ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (req.isDateConstrained) ...[
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(Icons.calendar_today_rounded,
                                                size: 12,
                                                color: Colors.teal[700]),
                                            const SizedBox(width: 4),
                                            Text(
                                              DateFormatter.formatDateRange(
                                                  req.startDate, req.endDate),
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.teal[700],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                      if (req.summary.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          req.summary,
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                            color: theme
                                                .colorScheme.onSurfaceVariant,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          )),
                    ] else
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          isOwnProfile
                              ? 'You have not posted any travel requests yet. Tap "Post Request" when visiting a new city!'
                              : 'This user has no active travel stay requests.',
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
                                    subjectName: primaryName,
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

  Widget _buildTravelProfileCard(
      BuildContext context, ThemeData theme, TravelProfile travelProfile) {
    return Card(
      margin: EdgeInsets.zero,
      color: theme.colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Demographics, Nickname, Locations
            if (travelProfile.name != null ||
                travelProfile.formattedCurrent != null ||
                travelProfile.formattedHome != null ||
                travelProfile.formattedOrigin != null ||
                travelProfile.gender != null ||
                travelProfile.calculatedAge != null ||
                travelProfile.occupation != null ||
                travelProfile.education != null) ...[
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  if (travelProfile.name != null &&
                      travelProfile.name!.isNotEmpty)
                    _buildInfoBadge(
                        theme, Icons.badge_outlined, travelProfile.name!),
                  if (travelProfile.formattedCurrent != null)
                    _buildInfoBadge(theme, Icons.explore_outlined,
                        'Currently in ${travelProfile.formattedCurrent}'),
                  if (travelProfile.formattedHome != null)
                    _buildInfoBadge(theme, Icons.place_outlined,
                        'Lives in ${travelProfile.formattedHome}'),
                  if (travelProfile.formattedOrigin != null)
                    _buildInfoBadge(theme, Icons.flight_takeoff_rounded,
                        'From ${travelProfile.formattedOrigin}'),
                  if (travelProfile.gender != null)
                    _buildInfoBadge(
                        theme,
                        Icons.person_outline_rounded,
                        travelProfile.gender![0].toUpperCase() +
                            travelProfile.gender!.substring(1)),
                  if (travelProfile.calculatedAge != null)
                    _buildInfoBadge(theme, Icons.cake_outlined,
                        '${travelProfile.calculatedAge} yrs old'),
                  if (travelProfile.occupation != null)
                    _buildInfoBadge(theme, Icons.work_outline_rounded,
                        travelProfile.occupation!),
                  if (travelProfile.education != null)
                    _buildInfoBadge(
                        theme, Icons.school_outlined, travelProfile.education!),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Travel & Lifestyle Photos
            if (travelProfile.images.isNotEmpty) ...[
              Text('Photos',
                  style: theme.textTheme.labelMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SizedBox(
                height: 110,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: travelProfile.images.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (ctx, i) {
                    final imgUrl = travelProfile.images[i];
                    return GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (dCtx) => Dialog(
                            backgroundColor:
                                Colors.black.withValues(alpha: 0.85),
                            insetPadding: const EdgeInsets.all(12),
                            child: Stack(
                              alignment: Alignment.topRight,
                              children: [
                                Center(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Image.network(imgUrl,
                                        fit: BoxFit.contain),
                                  ),
                                ),
                                Positioned(
                                  top: 10,
                                  right: 10,
                                  child: IconButton(
                                    icon: const Icon(Icons.close_rounded,
                                        color: Colors.white, size: 28),
                                    onPressed: () => Navigator.of(dCtx).pop(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          imgUrl,
                          width: 110,
                          height: 110,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 110,
                            height: 110,
                            color: Colors.grey[800],
                            child: const Icon(Icons.broken_image_rounded,
                                color: Colors.white54),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Travel story/content
            if (travelProfile.content.trim().isNotEmpty) ...[
              Text(
                travelProfile.content,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
              ),
              const SizedBox(height: 16),
            ],

            // Languages
            if (travelProfile.languages.isNotEmpty) ...[
              Text('Languages',
                  style: theme.textTheme.labelMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: travelProfile.languages.map((l) {
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      l.displayName,
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
            ],

            // Interests
            if (travelProfile.interests.isNotEmpty) ...[
              Text('Interests',
                  style: theme.textTheme.labelMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: travelProfile.interests.map((t) {
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer
                          .withValues(alpha: 0.3),
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
              Text('Verified & Linked Networks',
                  style: theme.textTheme.labelMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: travelProfile.externalIdentities.map((id) {
                  return InkWell(
                    onTap: id.url.isNotEmpty
                        ? () async {
                            final uri = Uri.tryParse(id.url);
                            if (uri != null) {
                              try {
                                final launched = await launchUrl(uri,
                                    mode: LaunchMode.externalApplication);
                                if (!launched && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content:
                                            Text('Could not open: ${id.url}')),
                                  );
                                }
                              } catch (_) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content:
                                            Text('Could not open: ${id.url}')),
                                  );
                                }
                              }
                            }
                          }
                        : null,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        border:
                            Border.all(color: theme.colorScheme.outlineVariant),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.link_rounded, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            '${id.platformName}: @${id.username}',
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w500),
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

  void _showActivityExplanationDialog(
      BuildContext context, DateTime lastActive, ThemeData theme) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.bolt_rounded, size: 36, color: theme.colorScheme.primary),
        title: const Text(
          'Active on Nostr',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Last Public Event',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${DateFormatter.formatShort(lastActive)} at ${DateFormatter.formatTime(lastActive)} (${DateFormatter.formatRelative(lastActive)})',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'How is this determined?',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Unlike traditional platforms that log private logins to a centralized server, Nostr has no central server or login database. Reading feeds and messages is completely passive and private.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This activity indicator reflects the timestamp of the latest public event published by this user across the Nostr network (such as listing updates, profile edits, public notes, references, or reactions).',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}
