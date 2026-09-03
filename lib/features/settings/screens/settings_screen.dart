import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/nip19_utils.dart';
import '../../about/screens/about_page.dart';
import '../../auth/screens/login_screen.dart';

/// Settings and relay management screen.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _relayController = TextEditingController();

  @override
  void dispose() {
    _relayController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authStateProvider).valueOrNull;
    final relayConfig = ref.watch(relayConfigProvider);
    final relays = relayConfig.relays;

    final pubkey = authState?.pubkey;
    final npub = authState?.npub ?? (pubkey != null ? Nip19Helper.pubkeyToNpub(pubkey) : null);
    final authRepo = ref.read(authRepositoryProvider);
    final nsec = authRepo.activeNsec;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & Relays'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20.0),
        children: [
          // Account & Identity Section
          Text(
            'Nostr Identity',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),

          if (authState?.isAuthenticated ?? false) ...[
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Public Key (npub)',
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: SelectableText(
                            npub ?? '',
                            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy_rounded, size: 18),
                          tooltip: 'Copy npub',
                          onPressed: () {
                            if (npub != null) {
                              Clipboard.setData(ClipboardData(text: npub));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Public key copied to clipboard!')),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 12),

                    // Backup Secret Key
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Private Key (nsec)',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'Your secret signing key. Never share this with anyone.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => _showBackupDialog(context, nsec),
                          icon: const Icon(Icons.visibility_outlined, size: 16),
                          label: const Text('View'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () async {
                await ref.read(authStateProvider.notifier).logout();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Logged out')),
                  );
                  Navigator.of(context).pop();
                }
              },
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Sign Out'),
            ),
          ] else ...[
            FilledButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
              icon: const Icon(Icons.login_rounded),
              label: const Text('Sign In or Generate Keypair'),
            ),
          ],

          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 20),

          // Relay Configuration Section
          Row(
            children: [
              Text(
                'Connected Relays (${relays.length})',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () async {
                  await relayConfig.resetToDefaults();
                  setState(() {});
                  ref.read(nostrServiceProvider).init();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Relays reset to default')),
                    );
                  }
                },
                child: const Text('Reset Defaults'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'nostr-hospitality connects to general-purpose open Nostr relays to discover listings, sync references, and deliver private messages.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),

          // Add Relay Input
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _relayController,
                  decoration: const InputDecoration(
                    hintText: 'wss://relay.example.com',
                    prefixIcon: Icon(Icons.add_link_rounded),
                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () async {
                  final url = _relayController.text.trim();
                  if (url.startsWith('wss://') || url.startsWith('ws://')) {
                    await relayConfig.addRelay(url);
                    _relayController.clear();
                    setState(() {});
                    ref.read(nostrServiceProvider).init();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Added relay $url')),
                      );
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Relay URL must begin with wss://')),
                    );
                  }
                },
                child: const Text('Add'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Relay List Card
          Card(
            margin: EdgeInsets.zero,
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: relays.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final relayUrl = relays[index];
                return ListTile(
                  leading: Icon(Icons.cloud_done_outlined, color: AppTheme.positiveGreen),
                  title: Text(
                    relayUrl,
                    style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    onPressed: relays.length <= 1
                        ? null
                        : () async {
                            await relayConfig.removeRelay(relayUrl);
                            setState(() {});
                          },
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 20),

          // About & Protocol Links
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.menu_book_rounded, color: theme.colorScheme.primary),
            title: const Text('Protocol Specifications & About'),
            subtitle: const Text('Documentation for Kind 7654 references, NIP-99, and NIP-17'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AboutPage()),
              );
            },
          ),
          const SizedBox(height: 24),
          const _AppVersionSection(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  void _showBackupDialog(BuildContext context, String? nsec) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Your Private Key (nsec)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '⚠️ Keep this secret! Anyone with your private key has complete control over your Nostr identity.',
              style: TextStyle(color: AppTheme.negativeRed, fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                nsec ?? 'Not available',
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (nsec != null) {
                Clipboard.setData(ClipboardData(text: nsec));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Private key copied to clipboard!')),
                );
              }
              Navigator.of(ctx).pop();
            },
            child: const Text('Copy Key'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}

class _AppVersionSection extends ConsumerWidget {
  const _AppVersionSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final updateAsync = ref.watch(appUpdateInfoProvider);

    return Card(
      margin: EdgeInsets.zero,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: updateAsync.when(
          data: (info) {
            final isUpdate = info.isUpdateAvailable;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isUpdate
                            ? theme.colorScheme.primaryContainer
                            : theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isUpdate
                            ? Icons.system_update_alt_rounded
                            : Icons.check_circle_outline_rounded,
                        color: isUpdate
                            ? theme.colorScheme.primary
                            : AppTheme.positiveGreen,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hospitality Libre v${info.currentVersion}',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isUpdate
                                ? 'Version v${info.latestVersion} is available'
                                : 'You are on the latest version',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isUpdate
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.outline,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isUpdate)
                      FilledButton(
                        style: FilledButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                        ),
                        onPressed: () {
                          if (info.apkDownloadUrl != null) {
                            launchUrl(
                              Uri.parse(info.apkDownloadUrl!),
                              mode: LaunchMode.externalApplication,
                            );
                          }
                        },
                        child: const Text('Update'),
                      )
                    else
                      IconButton(
                        icon: const Icon(Icons.refresh_rounded, size: 20),
                        tooltip: 'Check for updates',
                        onPressed: () {
                          ref.invalidate(appUpdateInfoProvider);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Checking for app updates...'),
                              duration: Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ],
            );
          },
          loading: () => Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 12),
              Text(
                'Checking for updates...',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
          ),
          error: (_, __) => Row(
            children: [
              Icon(Icons.info_outline_rounded,
                  size: 18, color: theme.colorScheme.outline),
              const SizedBox(width: 8),
              Text(
                'Hospitality Libre (Offline / Unverified)',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
