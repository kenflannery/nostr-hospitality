import '../core/nostr/nostr_service.dart';
import '../core/nostr/signer_service.dart';
import 'package:ndk/entities.dart';

/// Authentication state model.
class AuthState {
  final String? pubkey;
  final String? npub;
  final SignerType? signerType;
  final bool isAuthenticated;

  const AuthState({
    this.pubkey,
    this.npub,
    this.signerType,
    this.isAuthenticated = false,
  });
}

/// Repository managing user authentication and key management.
class AuthRepository {
  final SignerService _signerService;
  final NostrService _nostrService;

  AuthRepository({
    required SignerService signerService,
    required NostrService nostrService,
  })  : _signerService = signerService,
        _nostrService = nostrService;

  AuthState get currentState => AuthState(
        pubkey: _signerService.activePublicKey,
        npub: _signerService.activeNpub,
        signerType: _signerService.activeSignerType,
        isAuthenticated: _signerService.isAuthenticated,
      );

  String? get activeNsec {
    final signer = _signerService;
    if (signer is SecureLocalSignerService) {
      return signer.activeNsec;
    }
    return null;
  }

  SignerType? get activeSignerType => _signerService.activeSignerType;

  Future<AuthState> initialize() async {
    await _signerService.initialize();
    await _nostrService.init();
    return currentState;
  }

  Future<AuthState> generateNewAccount() async {
    await _signerService.generateNewKey();
    _nostrService.updateSigner();
    await publishRelayLists();
    return currentState;
  }

  Future<AuthState> loginWithPrivateKey(String privateKeyHexOrNsec) async {
    await _signerService.loginWithPrivateKey(privateKeyHexOrNsec);
    _nostrService.updateSigner();
    await publishRelayLists();
    return currentState;
  }

  Future<AuthState> loginWithNip07() async {
    await _signerService.loginWithNip07();
    _nostrService.updateSigner();
    await publishRelayLists();
    return currentState;
  }

  Future<AuthState> loginWithNip46(String bunkerUri, {String? explicitUserPubkey}) async {
    await _signerService.loginWithNip46(bunkerUri, explicitUserPubkey: explicitUserPubkey);
    _nostrService.updateSigner();
    await publishRelayLists();
    return currentState;
  }

  /// Broadcasts Kind 10050 (NIP-17 DM Relays) and Kind 10002 (NIP-65 Relays) to ensure DM capability.
  Future<void> publishRelayLists() async {
    final pubkey = _signerService.activePublicKey;
    if (pubkey == null) return;

    final relays = _nostrService.relayConfig.relays;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    final nip17RelayEvent = Nip01Event(
      pubKey: pubkey,
      kind: 10050,
      tags: relays.map((r) => ['relay', r]).toList(),
      content: '',
      createdAt: now,
    );

    final nip65RelayEvent = Nip01Event(
      pubKey: pubkey,
      kind: 10002,
      tags: relays.map((r) => ['r', r]).toList(),
      content: '',
      createdAt: now,
    );

    try {
      await _nostrService.broadcastEvent(nip17RelayEvent);
      await _nostrService.broadcastEvent(nip65RelayEvent);
    } catch (_) {}
  }

  Future<AuthState> logout() async {
    await _signerService.logout();
    _nostrService.updateSigner();
    return currentState;
  }
}
