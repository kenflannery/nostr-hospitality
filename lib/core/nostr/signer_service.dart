import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import '../utils/nip19_utils.dart';

/// Abstract signer service representing authenticated identity.
abstract class SignerService {
  String? get activePublicKey;
  String? get activeNpub;
  EventSigner? get eventSigner;
  bool get isAuthenticated;

  Future<void> initialize();
  Future<void> generateNewKey();
  Future<void> loginWithPrivateKey(String privateKeyHexOrNsec);
  Future<void> logout();
}

/// Secure storage implementation of [SignerService] using [FlutterSecureStorage] and [Bip340EventSigner].
class SecureLocalSignerService implements SignerService {
  static const String _privKeyKey = 'nostr_active_privkey';
  static const String _pubKeyKey = 'nostr_active_pubkey';

  final FlutterSecureStorage _storage;
  String? _publicKey;
  String? _privateKey;
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

  String? get activeNsec => _privateKey != null ? Nip19Helper.privkeyToNsec(_privateKey!) : null;

  @override
  EventSigner? get eventSigner => _signer;

  @override
  bool get isAuthenticated => _publicKey != null && _signer != null;

  @override
  Future<void> initialize() async {
    try {
      final savedPrivKey = await _storage.read(key: _privKeyKey);
      final savedPubKey = await _storage.read(key: _pubKeyKey);

      if (savedPrivKey != null && savedPubKey != null) {
        _privateKey = savedPrivKey;
        _publicKey = savedPubKey;
        _signer = Bip340EventSigner(
          privateKey: _privateKey,
          publicKey: _publicKey!,
        );
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

    _signer = Bip340EventSigner(
      privateKey: _privateKey,
      publicKey: _publicKey!,
    );

    await _storage.write(key: _privKeyKey, value: _privateKey);
    await _storage.write(key: _pubKeyKey, value: _publicKey);
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

    _signer = Bip340EventSigner(
      privateKey: _privateKey,
      publicKey: _publicKey!,
    );

    await _storage.write(key: _privKeyKey, value: _privateKey);
    await _storage.write(key: _pubKeyKey, value: _publicKey);
  }

  @override
  Future<void> logout() async {
    _privateKey = null;
    _publicKey = null;
    _signer = null;
    await _storage.delete(key: _privKeyKey);
    await _storage.delete(key: _pubKeyKey);
  }
}
