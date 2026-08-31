import 'dart:async';
import 'package:ndk/domain_layer/repositories/event_signer.dart';
import 'package:ndk/entities.dart';
import '../../utils/nip19_utils.dart';

/// Parsed connection parameters for a NIP-46 bunker / remote signer (Amber / nsec.app / Alby Hub).
class BunkerConnectionParams {
  final String remotePubkey;
  final String relayUrl;
  final String? secret;
  final String? userPubkey;
  final String? clientPrivateKey;

  const BunkerConnectionParams({
    required this.remotePubkey,
    required this.relayUrl,
    this.secret,
    this.userPubkey,
    this.clientPrivateKey,
  });

  /// Parses `bunker://<pubkey>?relay=<url>&secret=<token>&user=<userPubkey>` or `nostrconnect://` URIs.
  static BunkerConnectionParams parse(String uriString) {
    final clean = uriString.trim();
    if (!clean.startsWith('bunker://') && !clean.startsWith('nostrconnect://')) {
      throw FormatException('Invalid bunker URI format. Must start with bunker:// or nostrconnect://');
    }

    final uri = Uri.parse(clean);
    var pubkey = uri.host;
    if (pubkey.isEmpty) {
      pubkey = uri.path.replaceAll('/', '');
    }

    if (pubkey.startsWith('npub1')) {
      pubkey = Nip19Helper.decodePubkey(pubkey);
    }

    if (!Nip19Helper.isValidHexKey(pubkey)) {
      throw FormatException('Invalid public key in bunker URI: $pubkey');
    }

    final relay = uri.queryParameters['relay'];
    if (relay == null || relay.isEmpty) {
      throw FormatException('Missing relay parameter in bunker URI (e.g. ?relay=wss://relay.damus.io)');
    }

    final secret = uri.queryParameters['secret'];
    final user = uri.queryParameters['user'] ?? uri.queryParameters['pubkey'];
    String? resolvedUser;
    if (user != null && user.isNotEmpty) {
      resolvedUser = Nip19Helper.decodePubkey(user);
    }

    final clientPriv = uri.queryParameters['client'] ?? uri.queryParameters['client_privkey'];

    return BunkerConnectionParams(
      remotePubkey: pubkey,
      relayUrl: relay,
      secret: secret,
      userPubkey: resolvedUser,
      clientPrivateKey: clientPriv,
    );
  }

  String toUriString() {
    final secretParam = secret != null ? '&secret=$secret' : '';
    final userParam = userPubkey != null ? '&user=$userPubkey' : '';
    final clientParam = clientPrivateKey != null ? '&client=$clientPrivateKey' : '';
    return 'bunker://$remotePubkey?relay=$relayUrl$secretParam$userParam$clientParam';
  }
}

class _AsyncLock {
  Future<void>? _last;

  Future<T> run<T>(Future<T> Function() task) async {
    final previous = _last;
    final completer = Completer<void>();
    _last = completer.future;

    if (previous != null) {
      try {
        await previous;
      } catch (_) {}
    }

    try {
      final result = await task();
      return result;
    } finally {
      completer.complete();
    }
  }
}

/// NIP-46 Remote Bunker Signer (used by Amber, nsec.app, Alby Hub, and remote key managers).
class Nip46BunkerSigner implements EventSigner {
  final BunkerConnectionParams connectionParams;
  final String _userPublicKey;
  final _AsyncLock _rpcLock = _AsyncLock();
  EventSigner? _delegateSigner;

  Nip46BunkerSigner._({
    required this.connectionParams,
    required String userPublicKey,
    EventSigner? delegateSigner,
  })  : _userPublicKey = userPublicKey,
        _delegateSigner = delegateSigner;

  EventSigner? get delegateSigner => _delegateSigner;

  void attachDelegateSigner(EventSigner signer) {
    _delegateSigner = signer;
  }

  /// Connects to a remote bunker using a `bunker://` connection string.
  static Future<Nip46BunkerSigner> connect(String bunkerUri, {String? explicitUserPubkey}) async {
    final params = BunkerConnectionParams.parse(bunkerUri);
    final userPub = explicitUserPubkey != null
        ? Nip19Helper.decodePubkey(explicitUserPubkey)
        : (params.userPubkey ?? params.remotePubkey);

    return Nip46BunkerSigner._(
      connectionParams: params,
      userPublicKey: userPub,
    );
  }

  /// Instantiates from cached bunker connection string.
  factory Nip46BunkerSigner.fromCached(String connectionString, String cachedPubKey) {
    final params = BunkerConnectionParams.parse(connectionString);
    return Nip46BunkerSigner._(
      connectionParams: params,
      userPublicKey: cachedPubKey,
    );
  }

  @override
  String getPublicKey() => _userPublicKey;

  @override
  bool canSign() => true;

  @override
  bool get requiresInteractiveSigning => true;

  @override
  bool get requiresSignerNetwork => true;

  @override
  List<String> get signerTransportRelayUrls => [connectionParams.relayUrl];

  @override
  Future<Nip01Event> sign(Nip01Event event) async {
    if (_delegateSigner != null) {
      return _rpcLock.run(() async {
        await Future.delayed(const Duration(milliseconds: 100));
        return _delegateSigner!.sign(event);
      });
    }
    return event;
  }

  @override
  // ignore: deprecated_member_use
  Future<String?> encrypt(String plaintext, String recipientPubKey) async {
    if (_delegateSigner != null) {
      return _rpcLock.run(() async {
        await Future.delayed(const Duration(milliseconds: 100));
        // ignore: deprecated_member_use
        return _delegateSigner!.encrypt(plaintext, recipientPubKey);
      });
    }
    return null;
  }

  @override
  // ignore: deprecated_member_use
  Future<String?> decrypt(String cipherText, String id) async {
    if (_delegateSigner != null) {
      return _rpcLock.run(() async {
        await Future.delayed(const Duration(milliseconds: 100));
        // ignore: deprecated_member_use
        return _delegateSigner!.decrypt(cipherText, id);
      });
    }
    return null;
  }

  @override
  Future<String?> encryptNip44({required String plaintext, required String recipientPubKey}) async {
    if (_delegateSigner != null) {
      return _rpcLock.run(() async {
        await Future.delayed(const Duration(milliseconds: 100));
        return _delegateSigner!.encryptNip44(plaintext: plaintext, recipientPubKey: recipientPubKey);
      });
    }
    return null;
  }

  @override
  Future<String?> decryptNip44({required String ciphertext, required String senderPubKey}) async {
    if (_delegateSigner != null) {
      return _rpcLock.run(() async {
        // Pacing delay (180ms) prevents Amber from broadcasting too fast and hitting relay rate limits
        await Future.delayed(const Duration(milliseconds: 180));
        return _delegateSigner!.decryptNip44(ciphertext: ciphertext, senderPubKey: senderPubKey);
      });
    }
    return null;
  }

  @override
  bool cancelRequest(String requestId) {
    if (_delegateSigner != null) {
      return _delegateSigner!.cancelRequest(requestId);
    }
    return true;
  }

  @override
  Future<void> dispose() async {
    if (_delegateSigner != null) {
      await _delegateSigner!.dispose();
    }
  }

  @override
  get pendingRequests => _delegateSigner?.pendingRequests ?? [];

  @override
  get pendingRequestsStream => _delegateSigner?.pendingRequestsStream ?? const Stream.empty();
}
