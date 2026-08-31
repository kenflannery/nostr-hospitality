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

  const BunkerConnectionParams({
    required this.remotePubkey,
    required this.relayUrl,
    this.secret,
    this.userPubkey,
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

    return BunkerConnectionParams(
      remotePubkey: pubkey,
      relayUrl: relay,
      secret: secret,
      userPubkey: resolvedUser,
    );
  }

  String toUriString() {
    final secretParam = secret != null ? '&secret=$secret' : '';
    final userParam = userPubkey != null ? '&user=$userPubkey' : '';
    return 'bunker://$remotePubkey?relay=$relayUrl$secretParam$userParam';
  }
}

/// NIP-46 Remote Bunker Signer (used by Amber, nsec.app, Alby Hub, and remote key managers).
class Nip46BunkerSigner implements EventSigner {
  final BunkerConnectionParams connectionParams;
  final String _userPublicKey;

  Nip46BunkerSigner._({
    required this.connectionParams,
    required String userPublicKey,
  }) : _userPublicKey = userPublicKey;

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
    return Nip01Event(
      id: event.id,
      pubKey: _userPublicKey,
      kind: event.kind,
      tags: event.tags,
      content: event.content,
      createdAt: event.createdAt,
      sig: event.sig,
    );
  }

  @override
  Future<String?> encrypt(String plaintext, String recipientPubKey) async {
    return null;
  }

  @override
  Future<String?> decrypt(String cipherText, String id) async {
    return null;
  }

  @override
  Future<String?> encryptNip44({required String plaintext, required String recipientPubKey}) async {
    return null;
  }

  @override
  Future<String?> decryptNip44({required String ciphertext, required String senderPubKey}) async {
    return null;
  }

  @override
  bool cancelRequest(String requestId) => true;

  @override
  Future<void> dispose() async {}

  @override
  get pendingRequests => [];

  @override
  get pendingRequestsStream => const Stream.empty();
}
