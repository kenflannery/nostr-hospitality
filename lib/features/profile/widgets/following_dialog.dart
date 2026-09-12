import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/navigation/app_router.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/utils/nip19_utils.dart';
import '../../../models/follow_list.dart';
import '../../../widgets/user_avatar.dart';

/// Opens a dialog displaying the list of people a user is following.
void showFollowingDialog(
  BuildContext context, {
  required String targetPubkey,
  required String targetName,
}) {
  showDialog(
    context: context,
    builder: (ctx) => FollowingDialog(
      targetPubkey: targetPubkey,
      targetName: targetName,
    ),
  );
}

class FollowingDialog extends ConsumerStatefulWidget {
  final String targetPubkey;
  final String targetName;

  const FollowingDialog({
    super.key,
    required this.targetPubkey,
    required this.targetName,
  });

  @override
  ConsumerState<FollowingDialog> createState() => _FollowingDialogState();
}

class _FollowingDialogState extends ConsumerState<FollowingDialog> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authStateProvider).valueOrNull;
    final isOwnProfile = authState?.pubkey != null &&
        authState!.pubkey!.toLowerCase() == widget.targetPubkey.toLowerCase();

    final contactListAsync =
        ref.watch(userContactListProvider(widget.targetPubkey));

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 520,
          maxHeight: 620,
        ),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
              child: Row(
                children: [
                  Icon(
                    Icons.people_alt_outlined,
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: contactListAsync.when(
                      data: (contacts) {
                        final count = isOwnProfile
                            ? ref.watch(followingPubkeysProvider).length
                            : (contacts?.contacts.length ?? 0);
                        return Text(
                          isOwnProfile
                              ? 'Following ($count)'
                              : '${widget.targetName} is Following ($count)',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        );
                      },
                      loading: () => Text(
                        'Following',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      error: (_, __) => Text(
                        'Following',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Search Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search people followed...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () => _searchController.clear(),
                        )
                      : null,
                  isDense: true,
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.45),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
              ),
            ),

            // List of Followed Users
            Expanded(
              child: contactListAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (error, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          size: 36,
                          color: theme.colorScheme.error,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Failed to load contacts: $error',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (contactList) {
                  // Build list of contact entries
                  List<ContactEntry> contacts;
                  if (isOwnProfile) {
                    final ownFollows = ref.watch(followingPubkeysProvider);
                    contacts = ownFollows
                        .map((pk) => ContactEntry(pubkey: pk))
                        .toList();
                  } else {
                    contacts = contactList?.contacts ?? [];
                  }

                  if (contacts.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.person_off_outlined,
                              size: 48,
                              color: theme.colorScheme.outline,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              isOwnProfile
                                  ? 'You are not following anyone yet.'
                                  : '${widget.targetName} is not following anyone yet.',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  // Filter by search query if any
                  final filteredContacts = contacts.where((contact) {
                    if (_searchQuery.isEmpty) return true;
                    final pk = contact.pubkey.toLowerCase();
                    final petname = contact.petname?.toLowerCase() ?? '';
                    final npub = Nip19Helper.pubkeyToNpub(contact.pubkey).toLowerCase();
                    return pk.contains(_searchQuery) ||
                        petname.contains(_searchQuery) ||
                        npub.contains(_searchQuery);
                  }).toList();

                  if (filteredContacts.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Text(
                          'No contacts match "$_searchQuery"',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8.0, vertical: 8.0),
                    itemCount: filteredContacts.length,
                    separatorBuilder: (_, __) => const Divider(
                      height: 1,
                      indent: 68,
                      endIndent: 16,
                    ),
                    itemBuilder: (context, index) {
                      final contact = filteredContacts[index];
                      return _FollowedUserTile(
                        pubkey: contact.pubkey,
                        petname: contact.petname,
                        relayUrl: contact.relayUrl,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FollowedUserTile extends ConsumerWidget {
  final String pubkey;
  final String? petname;
  final String? relayUrl;

  const _FollowedUserTile({
    required this.pubkey,
    this.petname,
    this.relayUrl,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profileAsync = ref.watch(userProfileProvider(pubkey));
    final travelProfileAsync = ref.watch(userTravelProfileProvider(pubkey));
    final isFollowing = ref.watch(isPubkeyFollowedProvider(pubkey));
    final authState = ref.watch(authStateProvider).valueOrNull;

    final profile = profileAsync.valueOrNull;
    final travelProfile = travelProfileAsync.valueOrNull;

    final primaryName = travelProfile?.name?.trim().isNotEmpty == true
        ? travelProfile!.name!.trim()
        : profile?.bestName.trim().isNotEmpty == true
            ? profile!.bestName.trim()
            : petname?.trim().isNotEmpty == true
                ? petname!.trim()
                : Nip19Helper.shortenKey(Nip19Helper.pubkeyToNpub(pubkey));

    final npubShort =
        Nip19Helper.shortenKey(Nip19Helper.pubkeyToNpub(pubkey));
    final location = travelProfile?.formattedCurrent ??
        travelProfile?.formattedHome ??
        profile?.nip05;

    final isOwnAccount = authState?.pubkey != null &&
        authState!.pubkey!.toLowerCase() == pubkey.toLowerCase();

    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      leading: UserAvatar(
        imageUrl: profile?.picture,
        nameOrPubkey: primaryName,
        radius: 22,
      ),
      title: Text(
        primaryName,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        location != null && location.isNotEmpty
            ? '$location • $npubShort'
            : npubShort,
        style: TextStyle(
          fontSize: 12,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (authState?.isAuthenticated == true && !isOwnAccount) ...[
            if (isFollowing)
              OutlinedButton(
                onPressed: () async {
                  await ref.read(followServiceProvider).unfollowUser(pubkey);
                },
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                  textStyle: const TextStyle(fontSize: 12),
                ),
                child: const Text('Following'),
              )
            else
              FilledButton.tonal(
                onPressed: () async {
                  await ref.read(followServiceProvider).followUser(pubkey);
                },
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                  textStyle: const TextStyle(fontSize: 12),
                ),
                child: const Text('Follow'),
              ),
            const SizedBox(width: 4),
          ],
          Icon(
            Icons.chevron_right_rounded,
            size: 20,
            color: theme.colorScheme.outline,
          ),
        ],
      ),
      onTap: () {
        Navigator.of(context).pop();
        AppRouter.toProfile(context, pubkey);
      },
    );
  }
}
