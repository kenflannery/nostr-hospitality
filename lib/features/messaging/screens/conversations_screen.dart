import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../models/chat_message.dart';
import '../../../widgets/empty_state_view.dart';
import '../../../widgets/user_avatar.dart';
import '../../auth/screens/login_screen.dart';
import 'chat_screen.dart';

/// Screen listing private NIP-17 conversations.
class ConversationsScreen extends ConsumerWidget {
  const ConversationsScreen({super.key});

  static const String _soapboxSignerUrl =
      'https://chromewebstore.google.com/detail/soapbox-signer/nnodjkgakfpkckcnbacpcjbpmlmbihdd';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider).valueOrNull;

    if (auth == null || !auth.isAuthenticated) {
      return Scaffold(
        appBar: AppBar(title: const Text('Messages')),
        body: EmptyStateView(
          icon: Icons.lock_outline_rounded,
          title: 'Sign In to View Messages',
          message:
              'Private NIP-17 messages require authenticating with your Nostr keys.',
          actionLabel: 'Sign In',
          onAction: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            );
          },
        ),
      );
    }

    final conversationsAsync = ref.watch(conversationsProvider);
    final nip44Supported =
        ref.watch(nip07Nip44SupportedProvider).valueOrNull ?? true;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Conversations',
            onPressed: () => ref.refresh(conversationsProvider),
          ),
        ],
      ),
      body: conversationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: EmptyStateView(
            icon: Icons.error_outline_rounded,
            title: 'Failed to Load Messages',
            message: err.toString(),
            actionLabel: 'Retry',
            onAction: () => ref.refresh(conversationsProvider),
          ),
        ),
        data: (conversations) {
          if (conversations.isEmpty) {
            if (!nip44Supported) {
              return RefreshIndicator(
                onRefresh: () async => ref.refresh(conversationsProvider.future),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.7,
                      child: EmptyStateView(
                        icon: Icons.extension_off_outlined,
                        title: 'Browser Extension Missing NIP-44',
                        message:
                            'Your browser extension does not support modern NIP-44 encryption required for private direct messages (NIP-17).\n\nTo view and send direct messages, we recommend installing Soapbox Signer, or logging in with Amber on mobile / your private key.',
                        actionLabel: 'Get Soapbox Signer',
                        onAction: () {
                          launchUrl(
                            Uri.parse(_soapboxSignerUrl),
                            mode: LaunchMode.externalApplication,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async => ref.refresh(conversationsProvider.future),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: const EmptyStateView(
                      icon: Icons.chat_bubble_outline_rounded,
                      title: 'No Conversations Yet',
                      message:
                          'Direct messages with hosts and travelers will appear here.\nStart a chat from any host profile or accommodation listing!',
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.refresh(conversationsProvider.future),
            child: ListView.separated(
              itemCount: conversations.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final conv = conversations[index];
                return _ConversationTile(
                  conversation: conv,
                  onTap: () {
                    Navigator.of(context)
                        .push(
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          recipientPubkey: conv.otherPubkey,
                        ),
                      ),
                    )
                        .then((_) {
                      ref.invalidate(conversationsProvider);
                    });
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _ConversationTile extends ConsumerWidget {
  final ConversationSummary conversation;
  final VoidCallback onTap;

  const _ConversationTile({
    required this.conversation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profileAsync =
        ref.watch(userProfileProvider(conversation.otherPubkey));
    final profile = profileAsync.valueOrNull;

    final displayName = profile?.bestName ??
        conversation.otherPubkey.substring(0, 8);

    return ListTile(
      onTap: onTap,
      leading: UserAvatar(
        imageUrl: profile?.picture,
        nameOrPubkey: displayName,
        radius: 24,
      ),
      title: Text(
        displayName,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        conversation.lastMessage,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: Text(
        DateFormatter.formatRelative(conversation.lastMessageTime),
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.outline,
        ),
      ),
    );
  }
}
