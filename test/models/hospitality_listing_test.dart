import 'package:flutter_test/flutter_test.dart';
import 'package:ndk/entities.dart';
import 'package:nostr_hospitality/core/constants/nostr_constants.dart';
import 'package:nostr_hospitality/models/hospitality_listing.dart';

void main() {
  group('NIP-99 HospitalityListing Model Tests', () {
    const authorHex = '79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798';

    test('Parses valid NIP-99 hospitality classified event with 4-char geohash and preferences', () {
      final nip01Event = Nip01Event(
        pubKey: authorHex,
        kind: NostrConstants.classifiedListingKind,
        tags: [
          ['d', 'hospitality-seattle-room'],
          ['title', 'Spare room in Seattle, WA'],
          ['summary', 'Cozy room near downtown Seattle'],
          ['location', 'Seattle, WA, USA'],
          ['g', 'c'],
          ['g', 'c2'],
          ['g', 'c23'],
          ['g', 'c23n'],
          ['status', 'active'],
          ['published_at', '1719234800'],
          ['t', 'hospitality'],
          ['t', 'Home'],
          ['price', '0', 'USD'],
          ['image', 'https://example.com/room.jpg'],
          ['max_guests', '3'],
          ['last_minute', 'true'],
          ['wheelchair', 'true'],
          ['tent_camping', 'false'],
          ['kids_allowed', 'true'],
          ['pets_allowed', 'false'],
          ['drinking_allowed', 'true'],
          ['smoking_allowed', 'outside'],
          ['sleeping_arrangement', 'private_room'],
          ['parking', 'free_on_premises'],
          ['parking_details', 'Driveway parking'],
          ['has_housemates', 'false'],
          ['has_kids', 'false'],
          ['has_pets', 'true'],
          ['host_drinks', 'true'],
          ['host_smokes', 'no'],
        ],
        content: 'I have a spare room with queen bed and private bathroom.',
        createdAt: 1719234800,
      );

      final listing = HospitalityListing.fromNip01Event(nip01Event);
      expect(listing, isNotNull);
      expect(listing!.dTag, 'hospitality-seattle-room');
      expect(listing.title, 'Spare room in Seattle, WA');
      expect(listing.summary, 'Cozy room near downtown Seattle');
      expect(listing.location, 'Seattle, WA, USA');
      expect(listing.geohash, 'c23n');
      expect(listing.privacyGeohash, 'c23n');
      expect(listing.effectiveLatitude, closeTo(47.6, 0.2));
      expect(listing.effectiveLongitude, closeTo(-122.3, 0.2));
      expect(listing.status, 'active');
      expect(listing.isActive, true);
      expect(listing.images, ['https://example.com/room.jpg']);
      expect(listing.maxGuests, 3);
      expect(listing.acceptLastMinute, true);
      expect(listing.wheelchairAccessible, true);
      expect(listing.hostsWithChildren, true);
      expect(listing.hostsWithPets, false);
      expect(listing.okayWithDrinking, true);
      expect(listing.okayWithSmoking, 'outside');
      expect(listing.sleepingArrangement, 'private_room');
      expect(listing.parking, 'free_on_premises');
      expect(listing.parkingDetails, 'Driveway parking');
      expect(listing.hasPets, true);
      expect(listing.drinksAtHome, true);
      expect(listing.smokesAtHome, 'no');
    });

    test('Status sold translates to isActive = false', () {
      final nip01Event = Nip01Event(
        pubKey: authorHex,
        kind: 30402,
        tags: [
          ['d', 'hospitality-home'],
          ['title', 'Couch in Tucson'],
          ['status', 'sold'],
          ['t', 'hospitality'],
          ['t', 'Home'],
        ],
        content: 'Not accepting guests currently.',
        createdAt: 1719234800,
      );

      final listing = HospitalityListing.fromNip01Event(nip01Event);
      expect(listing, isNotNull);
      expect(listing!.status, 'sold');
      expect(listing.isActive, false);
    });

    test('toNip01Event produces correct NIP-99 tags with cascading g geohash tags and preferences', () {
      final listing = HospitalityListing(
        eventId: '',
        authorPubkey: authorHex,
        dTag: 'hospitality-berlin-apt',
        title: 'Couch in Berlin',
        summary: 'Stay in Kreuzberg',
        content: 'Cozy living room sofa in heart of Berlin.',
        location: 'Berlin, Germany',
        geohash: 'u33d',
        status: NostrConstants.statusActive,
        publishedAt: DateTime.fromMillisecondsSinceEpoch(1719234800 * 1000),
        createdAt: DateTime.fromMillisecondsSinceEpoch(1719234800 * 1000),
        images: ['https://example.com/couch.jpg'],
        maxGuests: 2,
        acceptLastMinute: true,
        wheelchairAccessible: false,
        sleepingArrangement: 'couch',
        parking: 'street',
        okayWithSmoking: 'outside',
      );

      final event = listing.toNip01Event(authorPubkey: authorHex);
      expect(event.kind, 30402);
      expect(event.pubKey, authorHex);

      final dTag = event.tags.firstWhere((t) => t.isNotEmpty && t[0] == 'd');
      expect(dTag[1], 'hospitality-berlin-apt');

      // Check cascading geohash tags
      final gTags = event.tags.where((t) => t.isNotEmpty && t[0] == 'g').map((t) => t[1]).toList();
      expect(gTags, ['u', 'u3', 'u33', 'u33d']);

      // Check standard topics
      final tTags = event.tags.where((t) => t.isNotEmpty && t[0] == 't').map((t) => t[1]).toList();
      expect(tTags.contains('hospitality'), true);
      expect(tTags.contains('Home'), true);
      expect(tTags.contains('homeshare'), false);
      expect(tTags.contains('triphopping-host'), false);

      // Check preferences tags
      final maxGuestsTag = event.tags.firstWhere((t) => t.isNotEmpty && t[0] == 'max_guests');
      expect(maxGuestsTag[1], '2');

      final lastMinuteTag = event.tags.firstWhere((t) => t.isNotEmpty && t[0] == 'last_minute');
      expect(lastMinuteTag[1], 'true');

      final sleepingTag = event.tags.firstWhere((t) => t.isNotEmpty && t[0] == 'sleeping_arrangement');
      expect(sleepingTag[1], 'couch');
    });

    test('Absence Fallback: Missing offer/request category tag defaults to isOffer = true, isRequest = false', () {
      final nip01Event = Nip01Event(
        pubKey: authorHex,
        kind: NostrConstants.classifiedListingKind,
        tags: [
          ['d', 'legacy-listing'],
          ['title', 'Legacy host listing without explicit offer tag'],
          ['status', 'active'],
          ['t', 'hospitality'],
          ['location', 'Madrid, Spain'],
        ],
        content: 'I host travelers in Madrid.',
        createdAt: 1719234800,
      );

      final listing = HospitalityListing.fromNip01Event(nip01Event);
      expect(listing, isNotNull);
      expect(listing!.isOffer, true, reason: 'Absence of tag must default to isOffer = true');
      expect(listing.isRequest, false, reason: 'Absence of tag must never be a request');
      expect(listing.isDateConstrained, false);
      expect(listing.startDate, isNull);
      expect(listing.endDate, isNull);
    });

    test('Parses Stay Request with start/end dates and guests', () {
      final nip01Event = Nip01Event(
        pubKey: authorHex,
        kind: NostrConstants.classifiedListingKind,
        tags: [
          ['d', 'trip-chicago-1730505600'],
          ['title', 'Seeking host in Chicago for Architecture Biennial'],
          ['summary', 'Solo traveler visiting Chicago'],
          ['location', 'Chicago, IL, USA'],
          ['g', 'dp3w'],
          ['status', 'active'],
          ['published_at', '1730000000'],
          ['t', 'hospitality'],
          ['t', 'hospitality-request'],
          ['type', 'request'],
          ['start', '1730505600'], // Nov 2, 2024
          ['end', '1730764800'],   // Nov 5, 2024
          ['guests', '2'],
        ],
        content: 'Looking forward to meeting locals in Chicago!',
        createdAt: 1730000000,
      );

      final listing = HospitalityListing.fromNip01Event(nip01Event);
      expect(listing, isNotNull);
      expect(listing!.isRequest, true);
      expect(listing.isOffer, false);
      expect(listing.isDateConstrained, true);
      expect(listing.startDate, DateTime.fromMillisecondsSinceEpoch(1730505600 * 1000));
      expect(listing.endDate, DateTime.fromMillisecondsSinceEpoch(1730764800 * 1000));
      expect(listing.maxGuests, 2);
    });

    test('Serializes Stay Request to Nip01Event with start, end, and type tags', () {
      final startDate = DateTime.fromMillisecondsSinceEpoch(1730505600 * 1000);
      final endDate = DateTime.fromMillisecondsSinceEpoch(1730764800 * 1000);

      final request = HospitalityListing(
        eventId: '',
        authorPubkey: authorHex,
        dTag: 'trip-tokyo-2025',
        title: 'Visiting Tokyo in April',
        summary: 'Solo backpacker',
        content: 'Exploring Japanese cuisine and culture.',
        location: 'Tokyo, Japan',
        geohash: 'xn77',
        status: NostrConstants.statusActive,
        publishedAt: DateTime.now(),
        createdAt: DateTime.now(),
        startDate: startDate,
        endDate: endDate,
        categories: [NostrConstants.topicHospitality, NostrConstants.topicHospitalityRequest],
        maxGuests: 1,
      );

      expect(request.isRequest, true);
      expect(request.isOffer, false);

      final event = request.toNip01Event(authorPubkey: authorHex);
      final tTags = event.tags.where((t) => t.isNotEmpty && t[0] == 't').map((t) => t[1]).toList();
      expect(tTags.contains('hospitality'), true);
      expect(tTags.contains('hospitality-request'), true);
      expect(tTags.contains('Home'), false);

      final typeTag = event.tags.firstWhere((t) => t.isNotEmpty && t[0] == 'type');
      expect(typeTag[1], 'request');

      final startTag = event.tags.firstWhere((t) => t.isNotEmpty && t[0] == 'start');
      expect(startTag[1], '1730505600');

      final endTag = event.tags.firstWhere((t) => t.isNotEmpty && t[0] == 'end');
      expect(endTag[1], '1730764800');
    });

    test('Geohash Privacy: 5-char geohashes emit 5 cascading g tags, and >5 char geohashes truncate to 5', () {
      final listing5 = HospitalityListing(
        eventId: '',
        authorPubkey: authorHex,
        dTag: 'trip-seattle',
        title: 'Trip to Seattle',
        summary: 'Visiting Capitol Hill',
        content: 'Exploring Seattle neighborhoods.',
        location: 'Seattle, WA, USA',
        geohash: 'c23nb',
        status: NostrConstants.statusActive,
        publishedAt: DateTime.now(),
        createdAt: DateTime.now(),
      );

      expect(listing5.privacyGeohash, 'c23nb');
      final event5 = listing5.toNip01Event(authorPubkey: authorHex);
      final gTags5 = event5.tags.where((t) => t.isNotEmpty && t[0] == 'g').map((t) => t[1]).toList();
      expect(gTags5, ['c', 'c2', 'c23', 'c23n', 'c23nb']);

      // Excessive precision (e.g. 7 characters) must truncate to 5 for neighborhood privacy
      final listing7 = HospitalityListing(
        eventId: '',
        authorPubkey: authorHex,
        dTag: 'listing-too-precise',
        title: 'Listing',
        summary: 'Summary',
        content: 'Content',
        location: 'Seattle, WA, USA',
        geohash: 'c23nb78',
        status: NostrConstants.statusActive,
        publishedAt: DateTime.now(),
        createdAt: DateTime.now(),
      );

      expect(listing7.privacyGeohash, 'c23nb');
      final event7 = listing7.toNip01Event(authorPubkey: authorHex);
      final gTags7 = event7.tags.where((t) => t.isNotEmpty && t[0] == 'g').map((t) => t[1]).toList();
      expect(gTags7, ['c', 'c2', 'c23', 'c23n', 'c23nb']);
    });
  });
}
