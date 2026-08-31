import 'package:ndk/entities.dart';
import '../core/constants/nostr_constants.dart';

/// Language proficiency representation (ISO 639-1 code + level).
class LanguageProficiency {
  final String code; // e.g. "en", "es", "de", "fr", "ja"
  final String? level; // e.g. "native", "fluent", "intermediate", "learning"

  const LanguageProficiency({
    required this.code,
    this.level,
  });

  String get displayName {
    final name = _languageNames[code.toLowerCase()] ?? code.toUpperCase();
    if (level != null && level!.isNotEmpty) {
      final formattedLevel = level![0].toUpperCase() + level!.substring(1);
      return '$name ($formattedLevel)';
    }
    return name;
  }

  static const Map<String, String> _languageNames = {
    'en': 'English',
    'es': 'Spanish',
    'fr': 'French',
    'de': 'German',
    'it': 'Italian',
    'pt': 'Portuguese',
    'ru': 'Russian',
    'zh': 'Chinese',
    'ja': 'Japanese',
    'ko': 'Korean',
    'ar': 'Arabic',
    'hi': 'Hindi',
    'nl': 'Dutch',
    'pl': 'Polish',
    'tr': 'Turkish',
    'sv': 'Swedish',
    'el': 'Greek',
    'he': 'Hebrew',
    'vi': 'Vietnamese',
    'th': 'Thai',
    'id': 'Indonesian',
    'cs': 'Czech',
    'uk': 'Ukrainian',
  };
}

/// NIP-39 style external identity link.
class ExternalIdentity {
  final String platform; // e.g. "trustroots", "couchsurfing", "warmshowers", "github"
  final String username;
  final String? proof;

  const ExternalIdentity({
    required this.platform,
    required this.username,
    this.proof,
  });

  String get platformName {
    switch (platform.toLowerCase()) {
      case 'triphopping':
        return 'Trip Hopping';
      case 'couchers':
        return 'Couchers';
      case 'trustroots':
        return 'Trustroots';
      case 'couchsurfing':
        return 'Couchsurfing';
      case 'warmshowers':
        return 'WarmShowers';
      case 'bewelcome':
        return 'BeWelcome';
      case 'github':
        return 'GitHub';
      case 'twitter':
      case 'x':
        return 'X (Twitter)';
      default:
        return platform[0].toUpperCase() + platform.substring(1);
    }
  }

  String get url {
    switch (platform.toLowerCase()) {
      case 'triphopping':
        return 'https://triphopping.com/profile/$username';
      case 'couchers':
        return 'https://couchers.org/user/$username';
      case 'trustroots':
        return 'https://www.trustroots.org/profile/$username';
      case 'couchsurfing':
        return 'https://www.couchsurfing.com/people/$username';
      case 'warmshowers':
        return 'https://www.warmshowers.org/users/$username';
      case 'bewelcome':
        return 'https://www.bewelcome.org/members/$username';
      case 'github':
        return 'https://github.com/$username';
      default:
        return username.startsWith('http') ? username : '';
    }
  }
}

/// Domain model representing a NIP-XX (Kind 30602) Travel & Community Profile.
///
/// Decentralized, parameterizable profile event extending Kind 0 with real-world
/// travel identity, languages, interaction modes, and cross-platform verifications.
class TravelProfile {
  final String eventId;
  final String authorPubkey;
  final String dTag;
  final String content; // Travel story, philosophy, lifestyle
  final DateTime createdAt;

  // Personal Demographics (Self-Sovereign & Strictly Optional)
  final String? gender;
  final int? birthYear;
  final String? originCountry;
  final String? originCity;
  final String? homeCountry;
  final String? homeCity;
  final String? occupation;
  final String? education;

  // Languages Spoken
  final List<LanguageProficiency> languages;

  // Active Interaction Modes ('host', 'guest', 'meetup', 'rideshare', 'language_exchange')
  final List<String> modes;

  // Interests / Topics ('hiking', 'cooking', 'cycling', 'nostr')
  final List<String> interests;

  // NIP-39 External Verifications & Cross-Platform Identities
  final List<ExternalIdentity> externalIdentities;

  // Travel & Lifestyle Photos (NIP-96 / standard image tags)
  final List<String> images;

  final List<List<String>> rawTags;

  const TravelProfile({
    required this.eventId,
    required this.authorPubkey,
    this.dTag = 'travel-profile',
    this.content = '',
    required this.createdAt,
    this.gender,
    this.birthYear,
    this.originCountry,
    this.originCity,
    this.homeCountry,
    this.homeCity,
    this.occupation,
    this.education,
    this.languages = const [],
    this.modes = const [],
    this.interests = const [],
    this.externalIdentities = const [],
    this.images = const [],
    this.rawTags = const [],
  });

  /// Addressable coordinate "30602:`pubkey`:`dTag`"
  String get addressCoordinate => '${NostrConstants.travelProfileKind}:$authorPubkey:$dTag';

  /// Calculates dynamic age based on birth year without storing a stale integer.
  int? get calculatedAge {
    if (birthYear == null) return null;
    final currentYear = DateTime.now().year;
    return currentYear - birthYear!;
  }

  /// Whether the user has specified hosting as an active mode.
  bool get isOpenToHosting => modes.contains('host');

  /// Whether the user has specified traveling / guest as an active mode.
  bool get isOpenToTraveling => modes.contains('guest');

  /// Whether the user is open for coffee, city tours, or local meetups.
  bool get isOpenToMeetup => modes.contains('meetup');

  /// Whether the user is open to ridesharing / carpooling.
  bool get isOpenToRideshare => modes.contains('rideshare');

  /// Whether the profile contains any meaningful data.
  bool get isNotEmpty =>
      content.trim().isNotEmpty ||
      languages.isNotEmpty ||
      modes.isNotEmpty ||
      interests.isNotEmpty ||
      externalIdentities.isNotEmpty ||
      gender != null ||
      birthYear != null ||
      originCountry != null ||
      homeCountry != null ||
      occupation != null;

  /// Formatted origin location (e.g. "Munich, Germany").
  String? get formattedOrigin {
    if (originCity != null && originCountry != null) {
      return '$originCity, $originCountry';
    }
    return originCity ?? originCountry;
  }

  /// Formatted home base location (e.g. "Lyon, France").
  String? get formattedHome {
    if (homeCity != null && homeCountry != null) {
      return '$homeCity, $homeCountry';
    }
    return homeCity ?? homeCountry;
  }

  /// Parses a [Nip01Event] of kind 30602 into a [TravelProfile].
  static TravelProfile? fromNip01Event(Nip01Event event) {
    if (event.kind != NostrConstants.travelProfileKind) {
      return null;
    }

    String dTag = 'travel-profile';
    String? gender;
    int? birthYear;
    String? originCountry;
    String? originCity;
    String? homeCountry;
    String? homeCity;
    String? occupation;
    String? education;

    final languages = <LanguageProficiency>[];
    final modes = <String>[];
    final interests = <String>[];
    final externalIdentities = <ExternalIdentity>[];
    final images = <String>[];

    for (final tag in event.tags) {
      if (tag.isEmpty) continue;
      final key = tag[0];

      if (key == NostrConstants.tagD && tag.length > 1) {
        dTag = tag[1];
      } else if (key == 'gender' && tag.length > 1) {
        gender = tag[1];
      } else if (key == 'birth_year' && tag.length > 1) {
        birthYear = int.tryParse(tag[1]);
      } else if (key == 'origin_country' && tag.length > 1) {
        originCountry = tag[1];
      } else if (key == 'origin_city' && tag.length > 1) {
        originCity = tag[1];
      } else if (key == 'home_country' && tag.length > 1) {
        homeCountry = tag[1];
      } else if (key == 'home_city' && tag.length > 1) {
        homeCity = tag[1];
      } else if (key == 'occupation' && tag.length > 1) {
        occupation = tag[1];
      } else if (key == 'education' && tag.length > 1) {
        education = tag[1];
      } else if (key == 'language' && tag.length > 1) {
        languages.add(LanguageProficiency(
          code: tag[1],
          level: tag.length > 2 ? tag[2] : null,
        ));
      } else if (key == 'mode' && tag.length > 1) {
        modes.add(tag[1].toLowerCase());
      } else if (key == NostrConstants.tagT && tag.length > 1) {
        interests.add(tag[1]);
      } else if (key == 'image' && tag.length > 1 && tag[1].trim().isNotEmpty) {
        images.add(tag[1].trim());
      } else if (key == 'network' && tag.length > 2) {
        externalIdentities.add(ExternalIdentity(
          platform: tag[1].trim(),
          username: tag[2].trim(),
          proof: tag.length > 3 ? tag[3].trim() : null,
        ));
      } else if (key == 'i' && tag.length > 1) {
        final parts = tag[1].split(':');
        if (parts.length >= 2) {
          externalIdentities.add(ExternalIdentity(
            platform: parts[0],
            username: parts.sublist(1).join(':'),
            proof: tag.length > 2 ? tag[2] : null,
          ));
        }
      }
    }

    final createdAt = DateTime.fromMillisecondsSinceEpoch(event.createdAt * 1000);

    return TravelProfile(
      eventId: event.id,
      authorPubkey: event.pubKey,
      dTag: dTag,
      content: event.content,
      createdAt: createdAt,
      gender: gender,
      birthYear: birthYear,
      originCountry: originCountry,
      originCity: originCity,
      homeCountry: homeCountry,
      homeCity: homeCity,
      occupation: occupation,
      education: education,
      languages: languages,
      modes: modes,
      interests: interests,
      externalIdentities: externalIdentities,
      images: images,
      rawTags: event.tags,
    );
  }

  /// Converts this [TravelProfile] to a standard [Nip01Event] for publication.
  Nip01Event toNip01Event({required String authorPubkey}) {
    final tags = <List<String>>[];

    // 1. Parameterized addressable d-tag
    tags.add([NostrConstants.tagD, dTag]);

    // 2. Demographics & Origin/Home
    if (gender != null && gender!.trim().isNotEmpty) {
      tags.add(['gender', gender!.trim()]);
    }
    if (birthYear != null) {
      tags.add(['birth_year', birthYear.toString()]);
    }
    if (originCountry != null && originCountry!.trim().isNotEmpty) {
      tags.add(['origin_country', originCountry!.trim()]);
    }
    if (originCity != null && originCity!.trim().isNotEmpty) {
      tags.add(['origin_city', originCity!.trim()]);
    }
    if (homeCountry != null && homeCountry!.trim().isNotEmpty) {
      tags.add(['home_country', homeCountry!.trim()]);
    }
    if (homeCity != null && homeCity!.trim().isNotEmpty) {
      tags.add(['home_city', homeCity!.trim()]);
    }
    if (occupation != null && occupation!.trim().isNotEmpty) {
      tags.add(['occupation', occupation!.trim()]);
    }
    if (education != null && education!.trim().isNotEmpty) {
      tags.add(['education', education!.trim()]);
    }

    // 3. Languages spoken
    for (final lang in languages) {
      if (lang.code.trim().isNotEmpty) {
        if (lang.level != null && lang.level!.trim().isNotEmpty) {
          tags.add(['language', lang.code.trim().toLowerCase(), lang.level!.trim().toLowerCase()]);
        } else {
          tags.add(['language', lang.code.trim().toLowerCase()]);
        }
      }
    }

    // 4. Interaction Modes
    for (final mode in modes) {
      if (mode.trim().isNotEmpty) {
        tags.add(['mode', mode.trim().toLowerCase()]);
      }
    }

    // 5. Interests / Topics
    for (final interest in interests) {
      if (interest.trim().isNotEmpty) {
        tags.add([NostrConstants.tagT, interest.trim()]);
      }
    }

    // 6. Travel & Lifestyle Photos
    for (final image in images) {
      if (image.trim().isNotEmpty) {
        tags.add(['image', image.trim()]);
      }
    }

    // 7. Linked Hospitality & Travel Community Networks
    for (final id in externalIdentities) {
      if (id.platform.trim().isNotEmpty && id.username.trim().isNotEmpty) {
        if (id.proof != null && id.proof!.trim().isNotEmpty) {
          tags.add(['network', id.platform.trim().toLowerCase(), id.username.trim(), id.proof!.trim()]);
        } else {
          tags.add(['network', id.platform.trim().toLowerCase(), id.username.trim()]);
        }
      }
    }

    return Nip01Event(
      pubKey: authorPubkey,
      kind: NostrConstants.travelProfileKind,
      tags: tags,
      content: content,
      createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );
  }

  /// Helper copyWith
  TravelProfile copyWith({
    String? eventId,
    String? authorPubkey,
    String? dTag,
    String? content,
    DateTime? createdAt,
    String? gender,
    int? birthYear,
    String? originCountry,
    String? originCity,
    String? homeCountry,
    String? homeCity,
    String? occupation,
    String? education,
    List<LanguageProficiency>? languages,
    List<String>? modes,
    List<String>? interests,
    List<ExternalIdentity>? externalIdentities,
    List<String>? images,
    List<List<String>>? rawTags,
  }) {
    return TravelProfile(
      eventId: eventId ?? this.eventId,
      authorPubkey: authorPubkey ?? this.authorPubkey,
      dTag: dTag ?? this.dTag,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      gender: gender ?? this.gender,
      birthYear: birthYear ?? this.birthYear,
      originCountry: originCountry ?? this.originCountry,
      originCity: originCity ?? this.originCity,
      homeCountry: homeCountry ?? this.homeCountry,
      homeCity: homeCity ?? this.homeCity,
      occupation: occupation ?? this.occupation,
      education: education ?? this.education,
      languages: languages ?? this.languages,
      modes: modes ?? this.modes,
      interests: interests ?? this.interests,
      externalIdentities: externalIdentities ?? this.externalIdentities,
      images: images ?? this.images,
      rawTags: rawTags ?? this.rawTags,
    );
  }
}
