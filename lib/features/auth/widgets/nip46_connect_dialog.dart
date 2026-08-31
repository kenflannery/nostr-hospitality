import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ndk/domain_layer/usecases/bunkers/models/bunker_connection.dart';
import 'package:ndk/domain_layer/usecases/bunkers/models/nostr_connect.dart';
import 'package:ndk/entities.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/nostr_constants.dart';
import '../../../core/providers/app_providers.dart';

/// Modal dialog providing both Nostr Connect QR code scanning (Amber) and manual bunker:// input.
class Nip46ConnectDialog extends ConsumerStatefulWidget {
  const Nip46ConnectDialog({super.key});

  @override
  ConsumerState<Nip46ConnectDialog> createState() => _Nip46ConnectDialogState();
}

class _Nip46ConnectDialogState extends ConsumerState<Nip46ConnectDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _bunkerController = TextEditingController();
  StreamSubscription<Nip01Event>? _eventSubscription;
  NostrConnect? _nostrConnect;

  String? _liveRequestId;
  bool _isConnecting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initNostrConnect();
  }

  void _initNostrConnect() {
    final relayConfig = ref.read(relayConfigProvider);
    final relays = {
      if (relayConfig.relays.isNotEmpty) relayConfig.relays.first,
      ...NostrConstants.defaultRelays,
    }.toList();

    _nostrConnect = NostrConnect(
      relays: relays,
      appName: 'Hospitality Libre',
      appUrl: 'https://hospitalitylibre.com',
      perms: ['sign_event:1', 'sign_event:30402', 'sign_event:7654', 'sign_event:30602', 'sign_event:1059', 'nip04_encrypt', 'nip04_decrypt', 'nip44_encrypt', 'nip44_decrypt'],
    );

    _startNostrConnectFlow();
  }

  void _startNostrConnectFlow() async {
    if (_nostrConnect == null) return;

    final nostrService = ref.read(nostrServiceProvider);

    // Continuous real-time subscription across relays for Kind 24133
    final filter = Filter(
      kinds: [24133],
      pTags: [_nostrConnect!.keyPair.publicKey],
      since: (DateTime.now().millisecondsSinceEpoch ~/ 1000) - 60,
    );

    final sub = nostrService.liveSubscription(
      filter: filter,
      explicitRelays: _nostrConnect!.relays,
    );
    _liveRequestId = sub.requestId;

    _eventSubscription = sub.stream.listen((event) {
      if (event.kind == 24133 && event.pubKey.isNotEmpty) {
        _onAmberConnected(event.pubKey);
      }
    });

    // Run NDK's native bunker handshake in parallel
    try {
      final conn = await nostrService.ndk.bunkers.connectWithNostrConnect(_nostrConnect!);
      if (conn != null && mounted) {
        _onAmberConnected(conn.remotePubkey);
      }
    } catch (_) {
      // Handled by event listener
    }
  }

  void _onAmberConnected(String remoteBunkerPubkey) async {
    if (!mounted) return;

    _eventSubscription?.cancel();
    setState(() {
      _isConnecting = true;
      _errorMessage = null;
    });

    final nostrService = ref.read(nostrServiceProvider);
    String realUserPubkey = remoteBunkerPubkey;

    try {
      final conn = BunkerConnection(
        privateKey: _nostrConnect!.keyPair.privateKey!,
        remotePubkey: remoteBunkerPubkey,
        relays: _nostrConnect!.relays,
      );

      final signer = nostrService.ndk.bunkers.createSigner(conn);
      try {
        final fetchedPubkey = await signer.getPublicKeyAsync().timeout(const Duration(seconds: 4));
        if (fetchedPubkey.isNotEmpty) {
          realUserPubkey = fetchedPubkey;
        }
      } catch (_) {}
    } catch (_) {}

    _completeLogin(remoteBunkerPubkey, _nostrConnect!.relays.first, explicitUserPubkey: realUserPubkey);
  }

  void _completeLogin(String userOrRemotePubKey, String relayUrl, {String? explicitUserPubkey}) async {
    if (!mounted) return;

    _eventSubscription?.cancel();
    setState(() {
      _isConnecting = true;
      _errorMessage = null;
    });

    try {
      final user = explicitUserPubkey ?? userOrRemotePubKey;
      final bunkerUri = 'bunker://$userOrRemotePubKey?relay=$relayUrl&user=$user';
      await ref.read(authStateProvider.notifier).loginWithNip46(bunkerUri, explicitUserPubkey: user);
      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Connected to Amber!')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Amber authorization failed: $e';
          _isConnecting = false;
        });
      }
    }
  }

  void _showManualPubkeyInput() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Enter Amber Account (npub)'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enter the public key (npub) shown at the top of your Amber screen:',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Your Amber npub or hex key',
                  hintText: 'npub1...',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final key = controller.text.trim();
                Navigator.of(ctx).pop();
                if (key.isNotEmpty) {
                  final relay = _nostrConnect?.relays.first ?? 'wss://relay.damus.io';
                  _completeLogin(key, relay, explicitUserPubkey: key);
                }
              },
              child: const Text('Connect Account'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    if (_liveRequestId != null) {
      try {
        ref.read(nostrServiceProvider).ndk.requests.closeSubscription(_liveRequestId!);
      } catch (_) {}
    }
    _tabController.dispose();
    _bunkerController.dispose();
    super.dispose();
  }

  void _connectWithUri(String uri) async {
    final clean = uri.trim();
    if (clean.isEmpty) return;

    setState(() {
      _isConnecting = true;
      _errorMessage = null;
    });

    try {
      await ref.read(authStateProvider.notifier).loginWithNip46(clean);
      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Connected to remote signer!')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Connection failed: $e';
          _isConnecting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.cell_tower_rounded, color: theme.colorScheme.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Connect Remote Signer',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Amber / Nostr Connect (NIP-46)',
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(icon: Icon(Icons.qr_code_rounded, size: 18), text: 'Amber QR Scan'),
                  Tab(icon: Icon(Icons.link_rounded, size: 18), text: 'Bunker Link'),
                ],
              ),
              const SizedBox(height: 16),

              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline_rounded, size: 16, color: theme.colorScheme.error),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: theme.colorScheme.error, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),

              SizedBox(
                height: 350,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    SingleChildScrollView(child: _buildQrCodeTab(theme)),
                    SingleChildScrollView(child: _buildBunkerInputTab(theme)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQrCodeTab(ThemeData theme) {
    if (_nostrConnect == null) {
      return const Padding(
        padding: EdgeInsets.all(40.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final connectUrl = _nostrConnect!.nostrConnectURL;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: QrImageView(
            data: connectUrl,
            version: QrVersions.auto,
            size: 140.0,
            backgroundColor: Colors.white,
          ),
        ),
        const SizedBox(height: 10),
        if (_isConnecting) ...[
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 8),
              Text(
                'Amber approved! Logging in...',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
        ] else ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Listening on relay... Scan QR in Amber',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          alignment: WrapAlignment.center,
          children: [
            FilledButton.icon(
              onPressed: () => _openInAmber(connectUrl),
              icon: const Icon(Icons.open_in_new_rounded, size: 16),
              label: const Text('Open in Amber'),
            ),
            OutlinedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: connectUrl));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Link copied! Open Amber -> tap "+" -> "Paste from clipboard"')),
                );
              },
              icon: const Icon(Icons.copy_rounded, size: 16),
              label: const Text('Copy Link'),
            ),
            TextButton(
              onPressed: _showManualPubkeyInput,
              child: const Text('Already approved?'),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _openInAmber(String connectUrl) async {
    Clipboard.setData(ClipboardData(text: connectUrl));
    try {
      final uri = Uri.parse(connectUrl);
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Link copied! Open Amber -> tap "+" -> "Paste from clipboard"')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Link copied! Open Amber -> tap "+" -> "Paste from clipboard"')),
        );
      }
    }
  }

  Widget _buildBunkerInputTab(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Paste a bunker:// URI (e.g. from nsec.app, Alby Hub, or remote daemon):',
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _bunkerController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'bunker://<pubkey>?relay=wss://relay.damus.io&secret=...',
            suffixIcon: IconButton(
              icon: const Icon(Icons.content_paste_rounded, size: 18),
              tooltip: 'Paste from clipboard',
              onPressed: () async {
                final data = await Clipboard.getData(Clipboard.kTextPlain);
                if (data?.text != null) {
                  _bunkerController.text = data!.text!.trim();
                }
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton.icon(
            onPressed: _isConnecting
                ? null
                : () => _connectWithUri(_bunkerController.text),
            icon: _isConnecting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.login_rounded),
            label: const Text('Connect to Bunker'),
          ),
        ),
      ],
    );
  }
}
