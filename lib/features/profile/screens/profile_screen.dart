import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/nip19_utils.dart';
import '../../../models/travel_profile.dart';
import '../../../models/user_profile.dart';
import '../../../widgets/profile_banner.dart';
import '../../../widgets/raw_event_viewer_dialog.dart';
import '../../../widgets/user_avatar.dart';
import '../../references/widgets/reference_card.dart';
import '../../../core/navigation/app_router.dart';
import '../widgets/community_label_dialog.dart';
import '../widgets/community_labels_section.dart';
import '../widgets/following_dialog.dart';
import '../../moderation/widgets/report_dialog.dart';

/// User Profile Screen displaying Kind 0 metadata, Kind 30602 Travel Profile,
/// Kind 30402 hosting offer, and Kind 7654 references.
class ProfileScreen extends ConsumerWidget {
  final String? pubkey; // If null, displays current user's profile

  const ProfileScreen({super.key, this.pubkey});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authState = ref.watch(authStateProvider).valueOrNull;
    final resolvedPubkey =
        pubkey != null ? Nip19Helper.decodePubkey(pubkey!) : null;
    final targetPubkey = resolvedPubkey ?? authState?.pubkey;
    final isOwnProfile = pubkey == null ||
        (targetPubkey != null && targetPubkey == authState?.pubkey);
    final isMuted = targetPubkey != null
        ? ref.watch(isPubkeyMutedProvider(targetPubkey))
        : false;
    final isFollowing = targetPubkey != null
        ? ref.watch(isPubkeyFollowedProvider(targetPubkey))
        : false;

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
                  onPressed: () => AppRouter.toLogin(context),
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
    final hostingOffers = allAuthorListings.where((l) => l.isOffer).toList();
    final hostingOffer = hostingOffers.firstOrNull ?? listing;
    final travelRequests = allAuthorListings.where((l) => l.isRequest).toList();
    final summary = summaryAsync.valueOrNull;
    final references = referencesStream.valueOrNull ?? [];
    final contactListAsync = ref.watch(userContactListProvider(targetPubkey));
    final followingCount = isOwnProfile
        ? ref.watch(followingPubkeysProvider).length
        : contactListAsync.valueOrNull?.contacts.length;

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
        leading: !isOwnProfile
            ? BackButton(
                onPressed: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  } else {
                    context.go('/discover');
                  }
                },
              )
            : null,
        actions: [
          if (isOwnProfile)
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              tooltip: 'Settings & Relays',
              onPressed: () => AppRouter.toSettings(context),
            ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share / Copy Profile Link',
            onPressed: () {
              final npub = profile.npub;
              final path = '/p/$npub';
              final fullUrl = Uri.base.hasAuthority && Uri.base.host.isNotEmpty
                  ? '${Uri.base.scheme}://${Uri.base.host}${Uri.base.hasPort ? ':${Uri.base.port}' : ''}$path'
                  : path;
              Clipboard.setData(ClipboardData(text: fullUrl));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Profile link copied: $fullUrl'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            tooltip: 'More options & Developer data',
            onSelected: (value) async {
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
              } else if (value == 'add_label') {
                showAddCommunityLabelDialog(
                  context,
                  subjectPubkey: targetPubkey,
                  subjectName: primaryName,
                );
              } else if (value == 'follow') {
                final followService = ref.read(followServiceProvider);
                await followService.followUser(targetPubkey);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Following $primaryName'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } else if (value == 'unfollow') {
                final followService = ref.read(followServiceProvider);
                await followService.unfollowUser(targetPubkey);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Unfollowed $primaryName'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } else if (value == 'mute') {
                final mod = ref.read(moderationServiceProvider);
                await mod.mutePubkey(targetPubkey);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Muted $primaryName'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } else if (value == 'unmute') {
                final mod = ref.read(moderationServiceProvider);
                await mod.unmutePubkey(targetPubkey);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Unmuted $primaryName'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } else if (value == 'report') {
                showReportDialog(
                  context,
                  targetPubkey: targetPubkey,
                  targetDisplayName: primaryName,
                );
              } else if (value == 'view_following') {
                showFollowingDialog(
                  context,
                  targetPubkey: targetPubkey,
                  targetName: primaryName,
                );
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'view_following',
                child: Row(
                  children: [
                    const Icon(Icons.people_alt_outlined, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        followingCount != null
                            ? 'Following ($followingCount)'
                            : 'Following',
                      ),
                    ),
                  ],
                ),
              ),
              if (!isOwnProfile) ...[
                PopupMenuItem(
                  value: isFollowing ? 'unfollow' : 'follow',
                  child: Row(
                    children: [
                      Icon(
                        isFollowing
                            ? Icons.person_remove_outlined
                            : Icons.person_add_alt_1_outlined,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isFollowing ? 'Unfollow User' : 'Follow User',
                        ),
                      ),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'add_label',
                  child: Row(
                    children: [
                      Icon(Icons.label_outline_rounded, size: 18),
                      SizedBox(width: 8),
                      Expanded(child: Text('Add Label / Endorse')),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: isMuted ? 'unmute' : 'mute',
                  child: Row(
                    children: [
                      Icon(
                        isMuted ? Icons.volume_up_outlined : Icons.block_outlined,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(isMuted ? 'Unmute User' : 'Mute / Block User'),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'report',
                  child: Row(
                    children: [
                      Icon(
                        Icons.flag_outlined,
                        size: 18,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Report Account',
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                      ),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
              ],
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
          ref.invalidate(userLabelsStreamProvider(targetPubkey));
          ref.invalidate(userContactListProvider(targetPubkey));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Banner with pubkey-deterministic fallback & overlapping avatar
              Stack(
                clipBehavior: Clip.none,
                children: [
                  ProfileBanner(
                    bannerUrl: profile.banner,
                    pubkey: targetPubkey,
                    height: 155,
                  ),
                  Positioned(
                    bottom: -38,
                    left: 20,
                    child: UserAvatar(
                      imageUrl: profile.picture,
                      nameOrPubkey: primaryName,
                      pubkey: targetPubkey,
                      radius: 40,
                      borderWidth: 3.5,
                      borderColor: theme.colorScheme.surface,
                      hasShadow: true,
                    ),
                  ),
                ],
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 48), // Space for bottom half of overlapping avatar

                    // User Identity Header
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                primaryName,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.3,
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
                                const SizedBox(height: 4),
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
                                      Clipboard.setData(
                                          ClipboardData(text: profile.npub));
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

                    const SizedBox(height: 12),

                    // Quick-Glance Stat Pills (References, Following, Origin/Current, Languages, Nostr Activity)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        // Reference Count / Reputation Pill
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: summary != null && summary.totalCount > 0
                                ? AppTheme.hearthAmber.withValues(alpha: 0.12)
                                : theme.colorScheme.surfaceContainerHighest
                                    .withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: summary != null && summary.totalCount > 0
                                  ? AppTheme.hearthAmber.withValues(alpha: 0.3)
                                  : theme.colorScheme.outlineVariant
                                      .withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                summary != null && summary.totalCount > 0
                                    ? Icons.star_rounded
                                    : Icons.star_outline_rounded,
                                size: 15,
                                color: summary != null && summary.totalCount > 0
                                    ? AppTheme.hearthAmber
                                    : theme.colorScheme.outline,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                summary != null && summary.totalCount > 0
                                    ? '${summary.totalCount} Ref${summary.totalCount == 1 ? "" : "s"} (${summary.positiveCount} pos)'
                                    : 'No references yet',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: summary != null && summary.totalCount > 0
                                      ? AppTheme.hearthAmber
                                      : theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Following Pill
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => showFollowingDialog(
                              context,
                              targetPubkey: targetPubkey,
                              targetName: primaryName,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer
                                    .withValues(alpha: 0.35),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: theme.colorScheme.primary
                                      .withValues(alpha: 0.25),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.people_alt_outlined,
                                    size: 14,
                                    color: theme.colorScheme.primary,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    followingCount != null
                                        ? '$followingCount Following'
                                        : 'Following...',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Location Pill
                        if (travelProfile != null &&
                            (travelProfile.formattedCurrent != null ||
                                travelProfile.formattedHome != null))
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.secondaryContainer
                                  .withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: theme.colorScheme.secondary
                                    .withValues(alpha: 0.25),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.place_rounded,
                                  size: 14,
                                  color: theme.colorScheme.secondary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  travelProfile.formattedCurrent != null
                                      ? 'In ${travelProfile.formattedCurrent}'
                                      : 'Home: ${travelProfile.formattedHome}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color:
                                        theme.colorScheme.onSecondaryContainer,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Languages Pill
                        if (travelProfile != null &&
                            travelProfile.languages.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHigh
                                  .withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: theme.colorScheme.outlineVariant
                                    .withValues(alpha: 0.4),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.translate_rounded,
                                  size: 13,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  travelProfile.languages
                                      .map((l) => l.code.toUpperCase())
                                      .join(', '),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Active on Nostr Pill
                        if (lastActive != null)
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _showActivityExplanationDialog(
                                context,
                                lastActive,
                                theme,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: theme
                                      .colorScheme.surfaceContainerHighest
                                      .withValues(alpha: 0.4),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: theme.colorScheme.outlineVariant
                                        .withValues(alpha: 0.35),
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
                                      'Active ${DateFormatter.formatRelative(lastActive)}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color:
                                            theme.colorScheme.onSurfaceVariant,
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
                      ],
                    ),

                    if (isMuted && !isOwnProfile) ...[
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: theme.colorScheme.error.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.block_rounded, size: 18, color: theme.colorScheme.error),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'You have muted this account. Their content is hidden from your feeds.',
                                style: TextStyle(fontSize: 12, color: theme.colorScheme.error),
                              ),
                            ),
                            TextButton(
                              onPressed: () async {
                                await ref.read(moderationServiceProvider).unmutePubkey(targetPubkey);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Unmuted $primaryName')),
                                  );
                                }
                              },
                              child: const Text('Unmute'),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // Action Buttons (Edit Profile / Message / Reference / Add Label)
                    Row(
                      children: [
                        if (isOwnProfile) ...[
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => AppRouter.toEditProfile(context, profile),
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              label: const Text('Edit Identity (Kind 0)'),
                            ),
                          ),
                        ] else ...[
                          if (isFollowing)
                            OutlinedButton.icon(
                              onPressed: () async {
                                await ref.read(followServiceProvider).unfollowUser(targetPubkey);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Unfollowed $primaryName'),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              },
                              icon: const Icon(Icons.check_rounded, size: 18),
                              label: const Text('Following'),
                            )
                          else
                            FilledButton.tonalIcon(
                              onPressed: () async {
                                await ref.read(followServiceProvider).followUser(targetPubkey);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Following $primaryName'),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              },
                              icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                              label: const Text('Follow'),
                            ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () => AppRouter.toChat(
                                context,
                                targetPubkey,
                                name: primaryName,
                              ),
                              icon: const Icon(Icons.mail_outline_rounded,
                                  size: 18),
                              label: const Text('Message'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => AppRouter.toNewReference(
                                context,
                                subjectPubkey: targetPubkey,
                                subjectName: primaryName,
                              ),
                              icon: const Icon(Icons.rate_review_outlined,
                                  size: 18),
                              label: const Text('Reference'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.outlined(
                            tooltip: 'Add Community Label',
                            icon: const Icon(Icons.label_outline_rounded),
                            onPressed: () => showAddCommunityLabelDialog(
                              context,
                              subjectPubkey: targetPubkey,
                              subjectName: primaryName,
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
                            onPressed: () =>
                                AppRouter.toEditTravelProfile(context, travelProfile),
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
                                onPressed: () =>
                                    AppRouter.toEditTravelProfile(context, travelProfile),
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

                    // --- SECTION: Hosting Offers ---
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
                          hostingOffers.length > 1
                              ? 'Hosting Spaces (${hostingOffers.length})'
                              : 'Hosting Offer',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        if (isOwnProfile)
                          TextButton.icon(
                            onPressed: () => AppRouter.toNewOffer(context),
                            icon: const Icon(Icons.add_rounded, size: 16),
                            label: Text(hostingOffers.isEmpty
                                ? 'Create Offer'
                                : 'Add Space'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Multi-location clarification notice if author has 2+ hosting offers
                    if (hostingOffers.length > 1) ...[
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 12.0),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer
                              .withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: theme.colorScheme.primary
                                .withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.pin_drop_rounded,
                              size: 20,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'This member hosts in multiple locations (${hostingOffers.length} spaces)',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Check each space below for its specific neighborhood, available dates, and accommodation type.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: theme.colorScheme.onSurfaceVariant,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    if (hostingOffers.isNotEmpty) ...[
                      ...hostingOffers.map((offer) => Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: Card(
                              margin: EdgeInsets.zero,
                              color: theme.colorScheme.surfaceContainerLow,
                              child: InkWell(
                                onTap: () => AppRouter.toListing(context, offer),
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
                                              color: offer.isActive
                                                  ? AppTheme.positiveGreen
                                                      .withValues(alpha: 0.12)
                                                  : Colors.grey
                                                      .withValues(alpha: 0.12),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              offer.isActive
                                                  ? 'Accepting Guests'
                                                  : 'Inactive',
                                              style: TextStyle(
                                                color: offer.isActive
                                                    ? AppTheme.positiveGreen
                                                    : Colors.grey,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ),
                                          if (offer.sleepingArrangement != null) ...[
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: theme.colorScheme.surfaceContainerHighest,
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                offer.sleepingArrangement!
                                                    .replaceAll('_', ' ')
                                                    .toUpperCase(),
                                                style: TextStyle(
                                                  color: theme.colorScheme.onSurfaceVariant,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 10,
                                                ),
                                              ),
                                            ),
                                          ],
                                          const Spacer(),
                                          Icon(
                                            Icons.location_on_outlined,
                                            size: 14,
                                            color: theme.colorScheme.primary,
                                          ),
                                          const SizedBox(width: 4),
                                          Flexible(
                                            child: Text(
                                              offer.location,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: theme.colorScheme
                                                    .onSurfaceVariant,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                          if (isOwnProfile) ...[
                                            const SizedBox(width: 4),
                                            IconButton(
                                              icon: const Icon(Icons.edit_outlined, size: 16),
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                              tooltip: 'Edit Space',
                                              onPressed: () => AppRouter.toEditListing(context, offer),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        offer.title,
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (offer.isDateConstrained) ...[
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(Icons.calendar_today_rounded,
                                                size: 12,
                                                color:
                                                    theme.colorScheme.primary),
                                            const SizedBox(width: 4),
                                            Text(
                                              DateFormatter.formatDateRange(
                                                  offer.startDate,
                                                  offer.endDate),
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color:
                                                    theme.colorScheme.primary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                      const SizedBox(height: 4),
                                      Text(
                                        offer.summary,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                          color: theme
                                              .colorScheme.onSurfaceVariant,
                                        ),
                                      ),
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
                            onPressed: () => AppRouter.toNewRequest(context),
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
                                onTap: () => AppRouter.toListing(context, req),
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

                    // --- SECTION: Community Labels (NIP-32) ---
                    CommunityLabelsSection(
                      subjectPubkey: targetPubkey,
                      subjectName: primaryName,
                      isOwnProfile: isOwnProfile,
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
                            onPressed: () => AppRouter.toNewReference(
                              context,
                              subjectPubkey: targetPubkey,
                              subjectName: primaryName,
                              initialListing: listing,
                            ),
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
