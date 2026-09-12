import 'dart:convert';
import 'package:ndk/entities.dart';
import '../core/constants/nostr_constants.dart';
import '../core/utils/nip19_utils.dart';

/// Represents a Nostr user profile based on Kind 0 user metadata (NIP-01).
///
/// Preserves any unmanaged raw JSON fields to avoid destructive updates.
class UserProfile {
  final String pubkey;
  final String? name;
  final String? displayName;
  final String? picture;
  final String? banner;
  final String? about;
  final String? nip05;
  final String? website;
  final String? lud16; // lightning address if present
  final int? birthYear; // NIP-24 birthday { year, month, day }
  final int? birthMonth;
  final int? birthDay;
  final Map<String, dynamic> rawJson;
  final DateTime? updatedAt;

  const UserProfile({
    required this.pubkey,
    this.name,
    this.displayName,
    this.picture,
    this.banner,
    this.about,
    this.nip05,
    this.website,
    this.lud16,
    this.birthYear,
    this.birthMonth,
    this.birthDay,
    this.rawJson = const {},
    this.updatedAt,
  });

  /// Bech32 npub identifier
  String get npub => Nip19Helper.pubkeyToNpub(pubkey);

  /// Dynamic age calculated from NIP-24 birthday (if birthYear is present)
  int? get calculatedAge {
    if (birthYear == null) return null;
    final now = DateTime.now();
    int age = now.year - birthYear!;
    if (birthMonth != null) {
      final day = birthDay ?? 1;
      if (now.month < birthMonth! || (now.month == birthMonth! && now.day < day)) {
        age -= 1;
      }
    }
    return age;
  }

  /// Best display name: displayName -> name -> shortened pubkey
  String get bestName {
    if (displayName != null && displayName!.trim().isNotEmpty) {
      return displayName!.trim();
    }
    if (name != null && name!.trim().isNotEmpty) {
      return name!.trim();
    }
    if (pubkey.length > 12) {
      return '${pubkey.substring(0, 6)}...${pubkey.substring(pubkey.length - 4)}';
    }
    return pubkey;
  }

  /// Parses a [Nip01Event] of Kind 0 into a [UserProfile].
  static UserProfile? fromNip01Event(Nip01Event event) {
    if (event.kind != NostrConstants.metadataKind) {
      return null;
    }

    Map<String, dynamic> json = {};
    try {
      if (event.content.isNotEmpty) {
        final decoded = jsonDecode(event.content);
        if (decoded is Map<String, dynamic>) {
          json = decoded;
        }
      }
    } catch (_) {
      // Malformed content JSON
    }

    int? birthYear;
    int? birthMonth;
    int? birthDay;
    final birthdayRaw = json['birthday'];
    if (birthdayRaw is Map) {
      if (birthdayRaw['year'] != null) {
        birthYear = int.tryParse(birthdayRaw['year'].toString());
      }
      if (birthdayRaw['month'] != null) {
        birthMonth = int.tryParse(birthdayRaw['month'].toString());
      }
      if (birthdayRaw['day'] != null) {
        birthDay = int.tryParse(birthdayRaw['day'].toString());
      }
    }

    return UserProfile(
      pubkey: event.pubKey,
      name: json['name'] as String?,
      displayName: (json['display_name'] ?? json['displayName']) as String?,
      picture: json['picture'] as String?,
      banner: json['banner'] as String?,
      about: json['about'] as String?,
      nip05: json['nip05'] as String?,
      website: json['website'] as String?,
      lud16: json['lud16'] as String?,
      birthYear: birthYear,
      birthMonth: birthMonth,
      birthDay: birthDay,
      rawJson: json,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(event.createdAt * 1000),
    );
  }

  /// Converts this profile into an updated unsigned [Nip01Event] while preserving all unmanaged fields.
  Nip01Event toNip01Event() {
    final mergedJson = Map<String, dynamic>.from(rawJson);

    if (name != null) mergedJson['name'] = name;
    if (displayName != null) mergedJson['display_name'] = displayName;
    if (picture != null) mergedJson['picture'] = picture;
    if (banner != null) mergedJson['banner'] = banner;
    if (about != null) mergedJson['about'] = about;
    if (nip05 != null) mergedJson['nip05'] = nip05;
    if (website != null) mergedJson['website'] = website;
    if (lud16 != null) mergedJson['lud16'] = lud16;

    if (birthYear != null || birthMonth != null || birthDay != null) {
      final bMap = <String, dynamic>{};
      if (birthYear != null) bMap['year'] = birthYear;
      if (birthMonth != null) bMap['month'] = birthMonth;
      if (birthDay != null) bMap['day'] = birthDay;
      mergedJson['birthday'] = bMap;
    } else {
      mergedJson.remove('birthday');
    }

    return Nip01Event(
      pubKey: pubkey,
      kind: NostrConstants.metadataKind,
      tags: [],
      content: jsonEncode(mergedJson),
      createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );
  }

  UserProfile copyWith({
    String? pubkey,
    String? name,
    String? displayName,
    String? picture,
    String? banner,
    String? about,
    String? nip05,
    String? website,
    String? lud16,
    int? birthYear,
    int? birthMonth,
    int? birthDay,
    Map<String, dynamic>? rawJson,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      pubkey: pubkey ?? this.pubkey,
      name: name ?? this.name,
      displayName: displayName ?? this.displayName,
      picture: picture ?? this.picture,
      banner: banner ?? this.banner,
      about: about ?? this.about,
      nip05: nip05 ?? this.nip05,
      website: website ?? this.website,
      lud16: lud16 ?? this.lud16,
      birthYear: birthYear ?? this.birthYear,
      birthMonth: birthMonth ?? this.birthMonth,
      birthDay: birthDay ?? this.birthDay,
      rawJson: rawJson ?? this.rawJson,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
