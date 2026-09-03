import 'package:ndk/entities.dart';
import '../core/constants/country_constants.dart';
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
/// travel identity, languages, nomad locations, and cross-platform verifications.
class TravelProfile {
  final String eventId;
  final String authorPubkey;
  final String dTag;
  final String content; // Travel story, philosophy, lifestyle
  final DateTime createdAt;

  // Travel Identity & Demographics (Self-Sovereign & Strictly Optional)
  final String? name; // Traveler nickname / trail name / preferred travel name
  final String? gender;
  final int? birthYear;
  final int? birthMonth; // 1 - 12
  final int? birthDay; // 1 - 31

  // Geographical Background & Mobility
  final String? originCountry; // ISO 3166-1 alpha-2 code (e.g. "DE")
  final String? originCity;
  final String? homeCountry; // ISO 3166-1 alpha-2 code (e.g. "FR")
  final String? homeCity;
  final String? currentCountry; // ISO 3166-1 alpha-2 code (e.g. "MX")
  final String? currentCity;
  final List<String> geohashes; // Cascading geohashes 3-5 chars for active location

  final String? occupation;
  final String? education;

  // Languages Spoken
  final List<LanguageProficiency> languages;

  // Interests / Topics ('hiking', 'cooking', 'cycling', 'nostr', 'meetup')
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
    this.name,
    this.gender,
    this.birthYear,
    this.birthMonth,
    this.birthDay,
    this.originCountry,
    this.originCity,
    this.homeCountry,
    this.homeCity,
    this.currentCountry,
    this.currentCity,
    this.geohashes = const [],
    this.occupation,
    this.education,
    this.languages = const [],
    this.interests = const [],
    this.externalIdentities = const [],
    this.images = const [],
    this.rawTags = const [],
  });

  /// Addressable coordinate "30602:`pubkey`:`dTag`"
  String get addressCoordinate => '${NostrConstants.travelProfileKind}:$authorPubkey:$dTag';

  /// Best traveler display name fallback
  String get bestTravelerName {
    if (name != null && name!.trim().isNotEmpty) {
      return name!.trim();
    }
    return authorPubkey.length >= 8 ? authorPubkey.substring(0, 8) : authorPubkey;
  }

  /// Primary / featured travel photo (first image tag in order)
  String? get primaryImage => images.isNotEmpty ? images.first : null;

  /// Calculates dynamic age based on birth year (and optional birthMonth / birthDay).
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

  /// Whether the profile contains any meaningful data.
  bool get isNotEmpty =>
      content.trim().isNotEmpty ||
      (name != null && name!.trim().isNotEmpty) ||
      languages.isNotEmpty ||
      interests.isNotEmpty ||
      externalIdentities.isNotEmpty ||
      gender != null ||
      birthYear != null ||
      originCountry != null ||
      homeCountry != null ||
      currentCountry != null ||
      currentCity != null ||
      occupation != null;

  /// Formatted origin location (e.g. "Munich, Germany").
  String? get formattedOrigin {
    final countryName = CountryConstants.getCountryName(originCountry);
    if (originCity != null && originCity!.isNotEmpty && countryName.isNotEmpty) {
      return '$originCity, $countryName';
    }
    return originCity ?? (countryName.isNotEmpty ? countryName : null);
  }

  /// Formatted home base location (e.g. "Lyon, France").
  String? get formattedHome {
    final countryName = CountryConstants.getCountryName(homeCountry);
    if (homeCity != null && homeCity!.isNotEmpty && countryName.isNotEmpty) {
      return '$homeCity, $countryName';
    }
    return homeCity ?? (countryName.isNotEmpty ? countryName : null);
  }

  /// Formatted current location (e.g. "Oaxaca, Mexico").
  String? get formattedCurrent {
    final countryName = CountryConstants.getCountryName(currentCountry);
    if (currentCity != null && currentCity!.isNotEmpty && countryName.isNotEmpty) {
      return '$currentCity, $countryName';
    }
    return currentCity ?? (countryName.isNotEmpty ? countryName : null);
  }

  /// Parses a [Nip01Event] of kind 30602 into a [TravelProfile].
  static TravelProfile? fromNip01Event(Nip01Event event) {
    if (event.kind != NostrConstants.travelProfileKind) {
      return null;
    }

    String dTag = 'travel-profile';
    String? name;
    String? gender;
    int? birthYear;
    int? birthMonth;
    int? birthDay;
    String? originCountry;
    String? originCity;
    String? homeCountry;
    String? homeCity;
    String? currentCountry;
    String? currentCity;
    String? occupation;
    String? education;

    final geohashes = <String>[];
    final languages = <LanguageProficiency>[];
    final interests = <String>[];
    final externalIdentities = <ExternalIdentity>[];
    final images = <String>[];

    for (final tag in event.tags) {
      if (tag.isEmpty) continue;
      final key = tag[0];

      if (key == NostrConstants.tagD && tag.length > 1) {
        dTag = tag[1];
      } else if (key == 'name' && tag.length > 1) {
        name = tag[1].trim();
      } else if (key == 'gender' && tag.length > 1) {
        gender = tag[1].trim();
      } else if (key == 'birth_year' && tag.length > 1) {
        birthYear = int.tryParse(tag[1].trim());
      } else if (key == 'birth_month' && tag.length > 1) {
        birthMonth = int.tryParse(tag[1].trim());
      } else if (key == 'birth_day' && tag.length > 1) {
        birthDay = int.tryParse(tag[1].trim());
      } else if (key == 'origin_country' && tag.length > 1) {
        originCountry = tag[1].trim().toUpperCase();
      } else if (key == 'origin_city' && tag.length > 1) {
        originCity = tag[1].trim();
      } else if (key == 'home_country' && tag.length > 1) {
        homeCountry = tag[1].trim().toUpperCase();
      } else if (key == 'home_city' && tag.length > 1) {
        homeCity = tag[1].trim();
      } else if (key == 'current_country' && tag.length > 1) {
        currentCountry = tag[1].trim().toUpperCase();
      } else if (key == 'current_city' && tag.length > 1) {
        currentCity = tag[1].trim();
      } else if (key == 'g' && tag.length > 1) {
        final g = tag[1].trim();
        if (g.isNotEmpty && !geohashes.contains(g)) {
          geohashes.add(g);
        }
      } else if (key == 'occupation' && tag.length > 1) {
        occupation = tag[1].trim();
      } else if (key == 'education' && tag.length > 1) {
        education = tag[1].trim();
      } else if (key == 'language' && tag.length > 1) {
        languages.add(LanguageProficiency(
          code: tag[1].trim().toLowerCase(),
          level: tag.length > 2 ? tag[2].trim().toLowerCase() : null,
        ));
      } else if (key == NostrConstants.tagT && tag.length > 1) {
        interests.add(tag[1].trim());
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
            proof: tag.length > 2 ? tag[2].trim() : null,
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
      name: name,
      gender: gender,
      birthYear: birthYear,
      birthMonth: birthMonth,
      birthDay: birthDay,
      originCountry: originCountry,
      originCity: originCity,
      homeCountry: homeCountry,
      homeCity: homeCity,
      currentCountry: currentCountry,
      currentCity: currentCity,
      geohashes: geohashes,
      occupation: occupation,
      education: education,
      languages: languages,
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

    // 2. Traveler Identity & Demographics
    if (name != null && name!.trim().isNotEmpty) {
      tags.add(['name', name!.trim()]);
    }
    if (gender != null && gender!.trim().isNotEmpty) {
      tags.add(['gender', gender!.trim()]);
    }
    if (birthYear != null) {
      tags.add(['birth_year', birthYear.toString()]);
    }
    if (birthMonth != null) {
      tags.add(['birth_month', birthMonth.toString()]);
    }
    if (birthDay != null) {
      tags.add(['birth_day', birthDay.toString()]);
    }

    // 3. Geographical Locations (Origins, Home, Current)
    if (originCountry != null && originCountry!.trim().isNotEmpty) {
      tags.add(['origin_country', originCountry!.trim().toUpperCase()]);
    }
    if (originCity != null && originCity!.trim().isNotEmpty) {
      tags.add(['origin_city', originCity!.trim()]);
    }
    if (homeCountry != null && homeCountry!.trim().isNotEmpty) {
      tags.add(['home_country', homeCountry!.trim().toUpperCase()]);
    }
    if (homeCity != null && homeCity!.trim().isNotEmpty) {
      tags.add(['home_city', homeCity!.trim()]);
    }
    if (currentCountry != null && currentCountry!.trim().isNotEmpty) {
      tags.add(['current_country', currentCountry!.trim().toUpperCase()]);
    }
    if (currentCity != null && currentCity!.trim().isNotEmpty) {
      tags.add(['current_city', currentCity!.trim()]);
    }

    // 4. Cascading geohash tags (Active Location)
    for (final g in geohashes) {
      if (g.trim().isNotEmpty) {
        tags.add(['g', g.trim()]);
      }
    }

    // 5. Professional & Education background
    if (occupation != null && occupation!.trim().isNotEmpty) {
      tags.add(['occupation', occupation!.trim()]);
    }
    if (education != null && education!.trim().isNotEmpty) {
      tags.add(['education', education!.trim()]);
    }

    // 6. Languages spoken
    for (final lang in languages) {
      if (lang.code.trim().isNotEmpty) {
        if (lang.level != null && lang.level!.trim().isNotEmpty) {
          tags.add(['language', lang.code.trim().toLowerCase(), lang.level!.trim().toLowerCase()]);
        } else {
          tags.add(['language', lang.code.trim().toLowerCase()]);
        }
      }
    }

    // 7. Interests / Topics
    for (final interest in interests) {
      if (interest.trim().isNotEmpty) {
        tags.add([NostrConstants.tagT, interest.trim()]);
      }
    }

    // 8. Travel & Lifestyle Photos
    for (final image in images) {
      if (image.trim().isNotEmpty) {
        tags.add(['image', image.trim()]);
      }
    }

    // 9. Linked Hospitality & Travel Community Networks
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
    String? name,
    String? gender,
    int? birthYear,
    int? birthMonth,
    int? birthDay,
    String? originCountry,
    String? originCity,
    String? homeCountry,
    String? homeCity,
    String? currentCountry,
    String? currentCity,
    List<String>? geohashes,
    String? occupation,
    String? education,
    List<LanguageProficiency>? languages,
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
      name: name ?? this.name,
      gender: gender ?? this.gender,
      birthYear: birthYear ?? this.birthYear,
      birthMonth: birthMonth ?? this.birthMonth,
      birthDay: birthDay ?? this.birthDay,
      originCountry: originCountry ?? this.originCountry,
      originCity: originCity ?? this.originCity,
      homeCountry: homeCountry ?? this.homeCountry,
      homeCity: homeCity ?? this.homeCity,
      currentCountry: currentCountry ?? this.currentCountry,
      currentCity: currentCity ?? this.currentCity,
      geohashes: geohashes ?? this.geohashes,
      occupation: occupation ?? this.occupation,
      education: education ?? this.education,
      languages: languages ?? this.languages,
      interests: interests ?? this.interests,
      externalIdentities: externalIdentities ?? this.externalIdentities,
      images: images ?? this.images,
      rawTags: rawTags ?? this.rawTags,
    );
  }
}
