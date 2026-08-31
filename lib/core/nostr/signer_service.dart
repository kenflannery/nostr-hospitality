import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import '../utils/nip19_utils.dart';
import 'signers/nip07_signer.dart';
import 'signers/nip46_signer.dart';

/// Type of signer currently authenticating the user.
enum SignerType {
  localKey,
  nip07,
  nip46,
}

/// Abstract signer service representing authenticated identity.
abstract class SignerService {
  String? get activePublicKey;
  String? get activeNpub;
  String? get activeNsec;
  SignerType? get activeSignerType;
  EventSigner? get eventSigner;
  bool get isAuthenticated;

  Future<void> initialize();
  Future<void> generateNewKey();
  Future<void> loginWithPrivateKey(String privateKeyHexOrNsec);
  Future<void> loginWithNip07();
  Future<void> loginWithNip46(String bunkerUri, {String? explicitUserPubkey});
  Future<void> logout();
}

/// Secure storage implementation of [SignerService] supporting local keys, NIP-07, and NIP-46.
class SecureLocalSignerService implements SignerService {
  static const String _privKeyKey = 'nostr_active_privkey';
  static const String _pubKeyKey = 'nostr_active_pubkey';
  static const String _signerTypeKey = 'nostr_active_signer_type';
  static const String _bunkerUriKey = 'nostr_active_bunker_uri';

  final FlutterSecureStorage _storage;
  String? _publicKey;
  String? _privateKey;
  SignerType? _signerType;
  EventSigner? _signer;

  SecureLocalSignerService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              webOptions: WebOptions(
                dbName: 'nostr_hospitality_sec',
                publicKey: 'nostr_hospitality_sec_key',
              ),
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  @override
  String? get activePublicKey => _publicKey;

  @override
  String? get activeNpub => _publicKey != null ? Nip19Helper.pubkeyToNpub(_publicKey!) : null;

  @override
  String? get activeNsec => _privateKey != null ? Nip19Helper.privkeyToNsec(_privateKey!) : null;

  @override
  SignerType? get activeSignerType => _signerType;

  @override
  EventSigner? get eventSigner => _signer;

  @override
  bool get isAuthenticated => _publicKey != null && _signer != null;

  @override
  Future<void> initialize() async {
    try {
      final savedType = await _storage.read(key: _signerTypeKey);
      final savedPubKey = await _storage.read(key: _pubKeyKey);

      if (savedType == SignerType.nip07.name && savedPubKey != null) {
        _signerType = SignerType.nip07;
        _publicKey = savedPubKey;
        _signer = Nip07Signer.fromCachedPublicKey(savedPubKey);
      } else if (savedType == SignerType.nip46.name && savedPubKey != null) {
        final bunkerUri = await _storage.read(key: _bunkerUriKey);
        if (bunkerUri != null) {
          _signerType = SignerType.nip46;
          _publicKey = savedPubKey;
          _signer = Nip46BunkerSigner.fromCached(bunkerUri, savedPubKey);
        }
      } else {
        // Local private key fallback
        final savedPrivKey = await _storage.read(key: _privKeyKey);
        if (savedPrivKey != null && savedPubKey != null) {
          _signerType = SignerType.localKey;
          _privateKey = savedPrivKey;
          _publicKey = savedPubKey;
          _signer = Bip340EventSigner(
            privateKey: _privateKey,
            publicKey: _publicKey!,
          );
        }
      }
    } catch (_) {
      // Secure storage read error or empty
    }
  }

  @override
  Future<void> generateNewKey() async {
    final keyPair = Bip340.generatePrivateKey();
    _privateKey = keyPair.privateKey!;
    _publicKey = keyPair.publicKey;
    _signerType = SignerType.localKey;

    _signer = Bip340EventSigner(
      privateKey: _privateKey,
      publicKey: _publicKey!,
    );

    await _storage.write(key: _signerTypeKey, value: SignerType.localKey.name);
    await _storage.write(key: _privKeyKey, value: _privateKey);
    await _storage.write(key: _pubKeyKey, value: _publicKey);
    await _storage.delete(key: _bunkerUriKey);
  }

  @override
  Future<void> loginWithPrivateKey(String privateKeyHexOrNsec) async {
    final hexPrivKey = Nip19Helper.decodePrivateKey(privateKeyHexOrNsec);
    if (!Nip19Helper.isValidHexKey(hexPrivKey)) {
      throw ArgumentError('Invalid 64-character hex or nsec private key');
    }

    final hexPubKey = Bip340.getPublicKey(hexPrivKey);
    _privateKey = hexPrivKey;
    _publicKey = hexPubKey;
    _signerType = SignerType.localKey;

    _signer = Bip340EventSigner(
      privateKey: _privateKey,
      publicKey: _publicKey!,
    );

    await _storage.write(key: _signerTypeKey, value: SignerType.localKey.name);
    await _storage.write(key: _privKeyKey, value: _privateKey);
    await _storage.write(key: _pubKeyKey, value: _publicKey);
    await _storage.delete(key: _bunkerUriKey);
  }

  @override
  Future<void> loginWithNip07() async {
    final nip07Signer = await Nip07Signer.connect();
    _publicKey = nip07Signer.getPublicKey();
    _privateKey = null;
    _signerType = SignerType.nip07;
    _signer = nip07Signer;

    await _storage.write(key: _signerTypeKey, value: SignerType.nip07.name);
    await _storage.write(key: _pubKeyKey, value: _publicKey);
    await _storage.delete(key: _privKeyKey);
    await _storage.delete(key: _bunkerUriKey);
  }

  @override
  Future<void> loginWithNip46(String bunkerUri, {String? explicitUserPubkey}) async {
    final nip46Signer = await Nip46BunkerSigner.connect(bunkerUri, explicitUserPubkey: explicitUserPubkey);
    _publicKey = nip46Signer.getPublicKey();
    _privateKey = null;
    _signerType = SignerType.nip46;
    _signer = nip46Signer;

    await _storage.write(key: _signerTypeKey, value: SignerType.nip46.name);
    await _storage.write(key: _pubKeyKey, value: _publicKey);
    await _storage.write(key: _bunkerUriKey, value: nip46Signer.connectionParams.toUriString());
    await _storage.delete(key: _privKeyKey);
  }

  @override
  Future<void> logout() async {
    _privateKey = null;
    _publicKey = null;
    _signerType = null;
    _signer = null;
    await _storage.delete(key: _privKeyKey);
    await _storage.delete(key: _pubKeyKey);
    await _storage.delete(key: _signerTypeKey);
    await _storage.delete(key: _bunkerUriKey);
  }
}
