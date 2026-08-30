import 'package:ndk/shared/nips/nip19/nip19.dart';

/// Helper utilities for Nostr NIP-19 bech32 identifiers (npub, nsec, naddr, etc.).
class Nip19Helper {
  Nip19Helper._();

  /// Converts a hex public key to an npub string.
  static String pubkeyToNpub(String hexPubkey) {
    try {
      if (hexPubkey.startsWith('npub1')) return hexPubkey;
      return Nip19.encodePubKey(hexPubkey);
    } catch (_) {
      return hexPubkey;
    }
  }

  /// Converts a hex private key to an nsec string.
  static String privkeyToNsec(String hexPrivkey) {
    try {
      if (hexPrivkey.startsWith('nsec1')) return hexPrivkey;
      return Nip19.encodePrivateKey(hexPrivkey);
    } catch (_) {
      return hexPrivkey;
    }
  }

  /// Decodes an npub or returns the 64-character hex public key.
  static String decodePubkey(String input) {
    final trimmed = input.trim();
    if (trimmed.startsWith('npub1')) {
      try {
        return Nip19.decode(trimmed);
      } catch (_) {
        return trimmed;
      }
    }
    return trimmed;
  }

  /// Decodes an nsec or returns the 64-character hex private key.
  static String decodePrivateKey(String input) {
    final trimmed = input.trim();
    if (trimmed.startsWith('nsec1')) {
      try {
        return Nip19.decode(trimmed);
      } catch (_) {
        return trimmed;
      }
    }
    return trimmed;
  }

  /// Shortens a hex or npub key for compact display (e.g. `npub1...abcd`).
  static String shortenKey(String key, {int prefixLen = 6, int suffixLen = 4}) {
    if (key.length <= prefixLen + suffixLen) return key;
    return '${key.substring(0, prefixLen)}...${key.substring(key.length - suffixLen)}';
  }

  /// Validates if a hex pubkey is 64 hex characters.
  static bool isValidHexKey(String key) {
    final hexRegExp = RegExp(r'^[0-9a-fA-F]{64}$');
    return hexRegExp.hasMatch(key.trim());
  }

  /// Parses address coordinate "30402:`pubkey`:`d-tag`"
  static Map<String, String>? parseAddressCoordinate(String coordinate) {
    final parts = coordinate.split(':');
    if (parts.length >= 3) {
      return {
        'kind': parts[0],
        'pubkey': parts[1],
        'dTag': parts.sublist(2).join(':'),
      };
    }
    return null;
  }
}
