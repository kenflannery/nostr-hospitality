import 'package:ndk/entities.dart';
import '../core/constants/nostr_constants.dart';
import '../core/utils/geohash_helper.dart';

/// Domain model representing a NIP-99 (Kind 30402) Hospitality Hosting Offer.
///
/// Follows the open Nostr hospitality specification with 4-character
/// privacy-preserving geohash tags and strictly null-preserving hosting preferences.
class HospitalityListing {
  final String eventId;
  final String authorPubkey;
  final String dTag;
  final String title;
  final String summary;
  final String content;
  final String location;
  final String? geohash;
  final double? originLat;
  final double? originLon;
  final String status;
  final DateTime publishedAt;
  final DateTime createdAt;
  final List<String> images;
  final List<String> categories;
  final String price;
  final String currency;

  // --- Hosting Preferences (Nullable - Absence means Unknown / Not Specified) ---
  final int? maxGuests;
  final bool? acceptLastMinute;
  final bool? wheelchairAccessible;
  final bool? tentCampingAvailable;
  final bool? hostsWithChildren;
  final bool? hostsWithPets;
  final bool? okayWithDrinking;
  final String? okayWithSmoking; // 'no', 'outside', 'yes'

  // --- My Home & Environment (Nullable - Absence means Unknown / Not Specified) ---
  final String? sleepingArrangement; // 'private_room', 'shared_room', 'couch', 'common_room', 'tent_space'
  final String? parking; // 'none', 'free_on_premises', 'street', 'paid'
  final String? parkingDetails;
  final bool? hasHousemates;
  final bool? hasKids;
  final bool? hasPets;
  final bool? drinksAtHome;
  final String? smokesAtHome; // 'no', 'outside', 'yes'

  final List<List<String>> rawTags;

  const HospitalityListing({
    required this.eventId,
    required this.authorPubkey,
    required this.dTag,
    required this.title,
    required this.summary,
    required this.content,
    required this.location,
    this.geohash,
    this.originLat,
    this.originLon,
    this.status = NostrConstants.statusActive,
    required this.publishedAt,
    required this.createdAt,
    this.images = const [],
    this.categories = const [
      NostrConstants.topicHospitality,
      'Home',
    ],
    this.price = '0',
    this.currency = 'USD',
    this.maxGuests,
    this.acceptLastMinute,
    this.wheelchairAccessible,
    this.tentCampingAvailable,
    this.hostsWithChildren,
    this.hostsWithPets,
    this.okayWithDrinking,
    this.okayWithSmoking,
    this.sleepingArrangement,
    this.parking,
    this.parkingDetails,
    this.hasHousemates,
    this.hasKids,
    this.hasPets,
    this.drinksAtHome,
    this.smokesAtHome,
    this.rawTags = const [],
  });

  /// Addressable NIP-33 / NIP-99 coordinate: "30402:`pubkey`:`d-tag`"
  String get addressCoordinate => '${NostrConstants.classifiedListingKind}:$authorPubkey:$dTag';

  /// Whether the listing is currently active and open for travelers.
  bool get isActive => status.toLowerCase() == NostrConstants.statusActive;

  /// Effective latitude for map rendering (explicit coordinate or derived from geohash).
  double? get effectiveLatitude {
    if (originLat != null) return originLat;
    if (geohash != null && geohash!.isNotEmpty) {
      final decoded = GeohashHelper.decode(geohash!);
      return decoded?.latitude;
    }
    return null;
  }

  /// Effective longitude for map rendering (explicit coordinate or derived from geohash).
  double? get effectiveLongitude {
    if (originLon != null) return originLon;
    if (geohash != null && geohash!.isNotEmpty) {
      final decoded = GeohashHelper.decode(geohash!);
      return decoded?.longitude;
    }
    return null;
  }

  /// Whether this listing has geographic positioning data for map placement.
  bool get hasLocationCoordinates =>
      effectiveLatitude != null && effectiveLongitude != null;

  /// 4-character privacy-truncated geohash.
  String? get privacyGeohash {
    if (geohash == null || geohash!.isEmpty) return null;
    return geohash!.length > 4 ? geohash!.substring(0, 4) : geohash;
  }

  /// Parses a [Nip01Event] into a [HospitalityListing].
  static HospitalityListing? fromNip01Event(Nip01Event event, {bool requireHospitalityTag = false}) {
    if (event.kind != NostrConstants.classifiedListingKind) {
      return null;
    }

    String? dTag;
    String? title;
    String? summary;
    String location = '';
    String? geohash;
    double? originLat;
    double? originLon;
    String status = NostrConstants.statusActive;
    DateTime? publishedAt;
    final images = <String>[];
    final categories = <String>[];
    String price = '0';
    String currency = 'USD';

    // Strictly null unless tag is present
    int? maxGuests;
    bool? acceptLastMinute;
    bool? wheelchairAccessible;
    bool? tentCampingAvailable;
    bool? hostsWithChildren;
    bool? hostsWithPets;
    bool? okayWithDrinking;
    String? okayWithSmoking;

    String? sleepingArrangement;
    String? parking;
    String? parkingDetails;
    bool? hasHousemates;
    bool? hasKids;
    bool? hasPets;
    bool? drinksAtHome;
    String? smokesAtHome;

    for (final tag in event.tags) {
      if (tag.isEmpty) continue;
      final key = tag[0];

      if (key == NostrConstants.tagD && tag.length > 1) {
        dTag = tag[1];
      } else if (key == NostrConstants.tagTitle && tag.length > 1) {
        title = tag[1];
      } else if (key == NostrConstants.tagSummary && tag.length > 1) {
        summary = tag[1];
      } else if (key == NostrConstants.tagLocation && tag.length > 1) {
        location = tag[1];
      } else if (key == NostrConstants.tagG && tag.length > 1) {
        if (geohash == null || tag[1].length > geohash.length) {
          geohash = tag[1];
        }
      } else if (key == 'origin_lat' && tag.length > 1) {
        originLat = double.tryParse(tag[1]);
      } else if (key == 'origin_lon' && tag.length > 1) {
        originLon = double.tryParse(tag[1]);
      } else if (key == NostrConstants.tagStatus && tag.length > 1) {
        status = tag[1];
      } else if (key == NostrConstants.tagPublishedAt && tag.length > 1) {
        final sec = int.tryParse(tag[1]);
        if (sec != null) {
          publishedAt = DateTime.fromMillisecondsSinceEpoch(sec * 1000);
        }
      } else if (key == NostrConstants.tagImage && tag.length > 1) {
        images.add(tag[1]);
      } else if (key == NostrConstants.tagT && tag.length > 1) {
        categories.add(tag[1]);
      } else if (key == NostrConstants.tagPrice && tag.length > 1) {
        price = tag[1];
        if (tag.length > 2) {
          currency = tag[2];
        }
      } else if (key == 'max_guests' && tag.length > 1) {
        maxGuests = int.tryParse(tag[1]);
      } else if (key == 'last_minute' && tag.length > 1) {
        acceptLastMinute = tag[1].toLowerCase() == 'true';
      } else if (key == 'wheelchair' && tag.length > 1) {
        wheelchairAccessible = tag[1].toLowerCase() == 'true';
      } else if (key == 'tent_camping' && tag.length > 1) {
        tentCampingAvailable = tag[1].toLowerCase() == 'true';
      } else if (key == 'kids_allowed' && tag.length > 1) {
        hostsWithChildren = tag[1].toLowerCase() == 'true';
      } else if (key == 'pets_allowed' && tag.length > 1) {
        hostsWithPets = tag[1].toLowerCase() == 'true';
      } else if (key == 'drinking_allowed' && tag.length > 1) {
        okayWithDrinking = tag[1].toLowerCase() == 'true';
      } else if (key == 'smoking_allowed' && tag.length > 1) {
        okayWithSmoking = tag[1];
      } else if (key == 'sleeping_arrangement' && tag.length > 1) {
        sleepingArrangement = tag[1];
      } else if (key == 'parking' && tag.length > 1) {
        parking = tag[1];
      } else if (key == 'parking_details' && tag.length > 1) {
        parkingDetails = tag[1];
      } else if (key == 'has_housemates' && tag.length > 1) {
        hasHousemates = tag[1].toLowerCase() == 'true';
      } else if (key == 'has_kids' && tag.length > 1) {
        hasKids = tag[1].toLowerCase() == 'true';
      } else if (key == 'has_pets' && tag.length > 1) {
        hasPets = tag[1].toLowerCase() == 'true';
      } else if (key == 'host_drinks' && tag.length > 1) {
        drinksAtHome = tag[1].toLowerCase() == 'true';
      } else if (key == 'host_smokes' && tag.length > 1) {
        smokesAtHome = tag[1];
      }
    }

    if (dTag == null || dTag.isEmpty) {
      return null;
    }

    final lowerCategories = categories.map((c) => c.toLowerCase()).toList();
    final isHospitality = lowerCategories.contains(NostrConstants.topicHospitality.toLowerCase()) ||
        lowerCategories.contains('home');

    if (requireHospitalityTag && !isHospitality) {
      return null;
    }

    final eventCreatedAt = DateTime.fromMillisecondsSinceEpoch(event.createdAt * 1000);

    return HospitalityListing(
      eventId: event.id,
      authorPubkey: event.pubKey,
      dTag: dTag,
      title: title ?? (location.isNotEmpty ? 'Stay in $location' : 'Hospitality Offer'),
      summary: summary ?? (event.content.length > 120 ? '${event.content.substring(0, 120)}...' : event.content),
      content: event.content,
      location: location,
      geohash: geohash,
      originLat: originLat,
      originLon: originLon,
      status: status,
      publishedAt: publishedAt ?? eventCreatedAt,
      createdAt: eventCreatedAt,
      images: images,
      categories: categories.isNotEmpty ? categories : [NostrConstants.topicHospitality, 'Home'],
      price: price,
      currency: currency,
      maxGuests: maxGuests,
      acceptLastMinute: acceptLastMinute,
      wheelchairAccessible: wheelchairAccessible,
      tentCampingAvailable: tentCampingAvailable,
      hostsWithChildren: hostsWithChildren,
      hostsWithPets: hostsWithPets,
      okayWithDrinking: okayWithDrinking,
      okayWithSmoking: okayWithSmoking,
      sleepingArrangement: sleepingArrangement,
      parking: parking,
      parkingDetails: parkingDetails,
      hasHousemates: hasHousemates,
      hasKids: hasKids,
      hasPets: hasPets,
      drinksAtHome: drinksAtHome,
      smokesAtHome: smokesAtHome,
      rawTags: event.tags,
    );
  }

  /// Converts this [HospitalityListing] to a standard [Nip01Event] for publication.
  /// Strictly emits tags only when explicitly set (non-null).
  Nip01Event toNip01Event({required String authorPubkey}) {
    final tags = <List<String>>[];

    // 1. Unique addressable identifier
    tags.add([NostrConstants.tagD, dTag]);

    // 2. Metadata tags
    tags.add([NostrConstants.tagTitle, title]);
    tags.add([NostrConstants.tagSummary, summary]);
    tags.add([NostrConstants.tagPublishedAt, (publishedAt.millisecondsSinceEpoch ~/ 1000).toString()]);

    // 3. Status and pricing
    tags.add([NostrConstants.tagStatus, status]);
    tags.add([NostrConstants.tagPrice, price, currency]);

    // 4. Location display string
    if (location.isNotEmpty) {
      tags.add([NostrConstants.tagLocation, location]);
    }

    // 5. Geohash tag(s) with 4-character privacy bounding and cascading prefixes
    final cleanGeohash = privacyGeohash;
    if (cleanGeohash != null && cleanGeohash.isNotEmpty) {
      final prefixes = GeohashHelper.cascadingPrefixes(cleanGeohash, maxPrecision: 4);
      for (final g in prefixes) {
        tags.add([NostrConstants.tagG, g]);
      }
    }

    // 6. Center coordinates (approximate geohash box center for client rendering convenience)
    if (originLat != null) {
      tags.add(['origin_lat', originLat!.toStringAsFixed(4)]);
    }
    if (originLon != null) {
      tags.add(['origin_lon', originLon!.toStringAsFixed(4)]);
    }

    // 7. Standard classified category topics
    final standardTopics = <String>{
      NostrConstants.topicHospitality,
      'Home',
      ...categories,
    };
    for (final topic in standardTopics) {
      tags.add([NostrConstants.tagT, topic]);
    }

    // 8. Hosting Preferences Tags (Emitted ONLY if non-null)
    if (maxGuests != null) {
      tags.add(['max_guests', maxGuests.toString()]);
    }
    if (acceptLastMinute != null) {
      tags.add(['last_minute', acceptLastMinute.toString()]);
    }
    if (wheelchairAccessible != null) {
      tags.add(['wheelchair', wheelchairAccessible.toString()]);
    }
    if (tentCampingAvailable != null) {
      tags.add(['tent_camping', tentCampingAvailable.toString()]);
    }
    if (hostsWithChildren != null) {
      tags.add(['kids_allowed', hostsWithChildren.toString()]);
    }
    if (hostsWithPets != null) {
      tags.add(['pets_allowed', hostsWithPets.toString()]);
    }
    if (okayWithDrinking != null) {
      tags.add(['drinking_allowed', okayWithDrinking.toString()]);
    }
    if (okayWithSmoking != null && okayWithSmoking!.isNotEmpty) {
      tags.add(['smoking_allowed', okayWithSmoking!]);
    }

    // 9. My Home & Environment Tags (Emitted ONLY if non-null)
    if (sleepingArrangement != null && sleepingArrangement!.isNotEmpty) {
      tags.add(['sleeping_arrangement', sleepingArrangement!]);
    }
    if (parking != null && parking!.isNotEmpty) {
      tags.add(['parking', parking!]);
    }
    if (parkingDetails != null && parkingDetails!.trim().isNotEmpty) {
      tags.add(['parking_details', parkingDetails!.trim()]);
    }
    if (hasHousemates != null) {
      tags.add(['has_housemates', hasHousemates.toString()]);
    }
    if (hasKids != null) {
      tags.add(['has_kids', hasKids.toString()]);
    }
    if (hasPets != null) {
      tags.add(['has_pets', hasPets.toString()]);
    }
    if (drinksAtHome != null) {
      tags.add(['host_drinks', drinksAtHome.toString()]);
    }
    if (smokesAtHome != null && smokesAtHome!.isNotEmpty) {
      tags.add(['host_smokes', smokesAtHome!]);
    }

    // 10. Image attachments
    for (final image in images) {
      if (image.trim().isNotEmpty) {
        tags.add([NostrConstants.tagImage, image.trim()]);
      }
    }

    return Nip01Event(
      pubKey: authorPubkey,
      kind: NostrConstants.classifiedListingKind,
      tags: tags,
      content: content,
      createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );
  }

  /// Helper copyWith
  HospitalityListing copyWith({
    String? eventId,
    String? authorPubkey,
    String? dTag,
    String? title,
    String? summary,
    String? content,
    String? location,
    String? geohash,
    double? originLat,
    double? originLon,
    String? status,
    DateTime? publishedAt,
    DateTime? createdAt,
    List<String>? images,
    List<String>? categories,
    String? price,
    String? currency,
    int? maxGuests,
    bool? acceptLastMinute,
    bool? wheelchairAccessible,
    bool? tentCampingAvailable,
    bool? hostsWithChildren,
    bool? hostsWithPets,
    bool? okayWithDrinking,
    String? okayWithSmoking,
    String? sleepingArrangement,
    String? parking,
    String? parkingDetails,
    bool? hasHousemates,
    bool? hasKids,
    bool? hasPets,
    bool? drinksAtHome,
    String? smokesAtHome,
    List<List<String>>? rawTags,
  }) {
    return HospitalityListing(
      eventId: eventId ?? this.eventId,
      authorPubkey: authorPubkey ?? this.authorPubkey,
      dTag: dTag ?? this.dTag,
      title: title ?? this.title,
      summary: summary ?? this.summary,
      content: content ?? this.content,
      location: location ?? this.location,
      geohash: geohash ?? this.geohash,
      originLat: originLat ?? this.originLat,
      originLon: originLon ?? this.originLon,
      status: status ?? this.status,
      publishedAt: publishedAt ?? this.publishedAt,
      createdAt: createdAt ?? this.createdAt,
      images: images ?? this.images,
      categories: categories ?? this.categories,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      maxGuests: maxGuests ?? this.maxGuests,
      acceptLastMinute: acceptLastMinute ?? this.acceptLastMinute,
      wheelchairAccessible: wheelchairAccessible ?? this.wheelchairAccessible,
      tentCampingAvailable: tentCampingAvailable ?? this.tentCampingAvailable,
      hostsWithChildren: hostsWithChildren ?? this.hostsWithChildren,
      hostsWithPets: hostsWithPets ?? this.hostsWithPets,
      okayWithDrinking: okayWithDrinking ?? this.okayWithDrinking,
      okayWithSmoking: okayWithSmoking ?? this.okayWithSmoking,
      sleepingArrangement: sleepingArrangement ?? this.sleepingArrangement,
      parking: parking ?? this.parking,
      parkingDetails: parkingDetails ?? this.parkingDetails,
      hasHousemates: hasHousemates ?? this.hasHousemates,
      hasKids: hasKids ?? this.hasKids,
      hasPets: hasPets ?? this.hasPets,
      drinksAtHome: drinksAtHome ?? this.drinksAtHome,
      smokesAtHome: smokesAtHome ?? this.smokesAtHome,
      rawTags: rawTags ?? this.rawTags,
    );
  }
}
