import 'dart:async';
import 'package:ndk/ndk.dart';
import 'package:ndk/entities.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'relay_config.dart';
import 'signer_service.dart';
import 'signers/nip46_signer.dart';

/// Core Nostr protocol coordinator wrapping the NDK engine.
class NostrService {
  final RelayConfig relayConfig;
  final SignerService signerService;

  final CacheManager _cache = MemCacheManager();
  late Ndk _ndk;
  bool _initialized = false;

  NostrService({
    required this.relayConfig,
    required this.signerService,
  }) {
    _ensureInitialized();
  }

  Ndk get ndk {
    _ensureInitialized();
    return _ndk;
  }

  CacheManager get cache => _cache;
  bool get isInitialized => _initialized;

  void _ensureInitialized() {
    if (_initialized) return;

    _ndk = Ndk(
      NdkConfig(
        eventVerifier: Bip340EventVerifier(),
        cache: _cache,
        bootstrapRelays: relayConfig.relays,
      ),
    );

    _initialized = true;
  }

  /// Initializes NDK instance and attaches active signer if authenticated.
  Future<void> init() async {
    _ensureInitialized();
    updateSigner();
  }

  /// Ensures a user (sender or recipient) has fallback relay routing in cache.
  Future<void> ensureUserRelayListInCache(String pubkey) async {
    final existing = await _cache.loadUserRelayList(pubkey);
    if (existing == null || existing.relays.isEmpty) {
      final fallbackMap = <String, ReadWriteMarker>{};
      for (final r in relayConfig.relays) {
        fallbackMap[r] = ReadWriteMarker.readWrite;
      }
      final userRelayList = UserRelayList(
        pubKey: pubkey,
        relays: fallbackMap,
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        refreshedTimestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      );
      await _cache.saveUserRelayList(userRelayList);
    }
  }

  /// Updates NDK login state when user signs in or logs out.
  void updateSigner() {
    _ensureInitialized();

    if (signerService.isAuthenticated && signerService.eventSigner != null) {
      final signer = signerService.eventSigner!;
      if (signer is Nip46BunkerSigner && signer.delegateSigner == null) {
        final clientPriv = signer.connectionParams.clientPrivateKey ??
            Bip340.generatePrivateKey().privateKey!;
        final conn = BunkerConnection(
          privateKey: clientPriv,
          remotePubkey: signer.connectionParams.remotePubkey,
          relays: [signer.connectionParams.relayUrl],
        );
        final delegate = _ndk.bunkers.createSigner(conn);
        delegate.cachedPublicKey = signer.getPublicKey();
        signer.attachDelegateSigner(delegate);
      }
      _ndk.accounts.loginExternalSigner(signer: signer);
    } else {
      _ndk.accounts.logout();
    }
  }

  /// Queries events matching filters from the network and relay cache (closes on EOSE).
  Stream<Nip01Event> queryEvents({
    required List<Filter> filters,
    List<String>? explicitRelays,
  }) {
    _ensureInitialized();

    final relays = explicitRelays ?? relayConfig.relays;
    final response = _ndk.requests.query(
      filter: filters.isNotEmpty ? filters.first : Filter(),
      explicitRelays: relays,
    );

    return response.stream;
  }

  /// Creates a live, persistent real-time subscription that stays open for new incoming events.
  NdkResponse liveSubscription({
    required Filter filter,
    List<String>? explicitRelays,
  }) {
    _ensureInitialized();

    final relays = explicitRelays ?? relayConfig.relays;
    return _ndk.requests.subscription(
      filter: filter,
      explicitRelays: relays,
    );
  }

  /// Signs an unsigned event with the active signer reliably.
  Future<Nip01Event> signEvent(Nip01Event event) async {
    _ensureInitialized();

    // If memory state was cleared during refresh, reload from secure storage
    if (!signerService.isAuthenticated || signerService.eventSigner == null) {
      await signerService.initialize();
    }

    if (!signerService.isAuthenticated || signerService.eventSigner == null) {
      throw StateError('Cannot sign event: user is not authenticated.');
    }

    // Keep NDK accounts synchronized
    try {
      _ndk.accounts.loginExternalSigner(signer: signerService.eventSigner!);
    } catch (_) {}

    // Directly sign using active eventSigner (Bip340EventSigner)
    return await signerService.eventSigner!.sign(event);
  }

  /// Signs (if unsigned) and broadcasts an event to the configured relays.
  Future<NdkBroadcastResponse> broadcastEvent(
    Nip01Event event, {
    List<String>? explicitRelays,
  }) async {
    _ensureInitialized();

    final signedEvent = (event.sig == null || event.sig!.isEmpty)
        ? await signEvent(event)
        : event;

    final relays = explicitRelays ?? relayConfig.relays;
    return _ndk.broadcast.broadcast(
      nostrEvent: signedEvent,
      specificRelays: relays,
    );
  }

  /// Fetches Kind 0 metadata for a pubkey from NDK cache or relays.
  Future<Metadata?> loadMetadata(String pubkey) async {
    _ensureInitialized();
    try {
      return await _ndk.metadata.loadMetadata(pubkey);
    } catch (_) {
      return null;
    }
  }

  /// Cleanly closes connections.
  void dispose() {
    if (_initialized) {
      _ndk.destroy();
      _initialized = false;
    }
  }
}
