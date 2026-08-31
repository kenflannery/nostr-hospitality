import 'package:flutter_test/flutter_test.dart';
import 'package:ndk/entities.dart';
import 'package:nostr_hospitality/core/constants/nostr_constants.dart';
import 'package:nostr_hospitality/models/travel_profile.dart';

void main() {
  group('Kind 30602 TravelProfile Model Tests', () {
    const authorHex = '79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798';

    test('Parses valid Kind 30602 event with all tags correctly', () {
      final nip01Event = Nip01Event(
        pubKey: authorHex,
        kind: NostrConstants.travelProfileKind,
        tags: [
          ['d', 'travel-profile'],
          ['gender', 'female'],
          ['birth_year', '1995'],
          ['origin_country', 'DE'],
          ['origin_city', 'Munich'],
          ['home_country', 'FR'],
          ['home_city', 'Lyon'],
          ['occupation', 'Photographer'],
          ['education', 'Master in Visual Arts'],
          ['language', 'de', 'native'],
          ['language', 'en', 'fluent'],
          ['language', 'fr', 'intermediate'],
          ['mode', 'host'],
          ['mode', 'guest'],
          ['mode', 'meetup'],
          ['t', 'cycling'],
          ['t', 'hiking'],
          ['image', 'https://image.nostr.build/trip1.jpg'],
          ['image', 'https://image.nostr.build/trip2.jpg'],
          ['network', 'triphopping', 'alice_nomad'],
          ['network', 'couchers', 'alice_traveler'],
        ],
        content: 'Slow traveler and photographer passionate about food, cycling, and decentralization.',
        createdAt: 1719234800,
      );

      final profile = TravelProfile.fromNip01Event(nip01Event);
      expect(profile, isNotNull);
      expect(profile!.dTag, 'travel-profile');
      expect(profile.gender, 'female');
      expect(profile.birthYear, 1995);
      expect(profile.calculatedAge, isNotNull);
      expect(profile.originCountry, 'DE');
      expect(profile.originCity, 'Munich');
      expect(profile.formattedOrigin, 'Munich, DE');
      expect(profile.formattedHome, 'Lyon, FR');
      expect(profile.occupation, 'Photographer');
      expect(profile.education, 'Master in Visual Arts');
      expect(profile.languages.length, 3);
      expect(profile.languages[0].code, 'de');
      expect(profile.languages[0].level, 'native');
      expect(profile.modes, ['host', 'guest', 'meetup']);
      expect(profile.isOpenToHosting, true);
      expect(profile.isOpenToTraveling, true);
      expect(profile.isOpenToMeetup, true);
      expect(profile.isOpenToRideshare, false);
      expect(profile.interests, ['cycling', 'hiking']);
      expect(profile.images, ['https://image.nostr.build/trip1.jpg', 'https://image.nostr.build/trip2.jpg']);
      expect(profile.externalIdentities.length, 2);
      expect(profile.externalIdentities[0].platform, 'triphopping');
      expect(profile.externalIdentities[0].username, 'alice_nomad');
      expect(profile.externalIdentities[0].platformName, 'Trip Hopping');
    });

    test('toNip01Event produces correct Kind 30602 tags and structure', () {
      final profile = TravelProfile(
        eventId: '',
        authorPubkey: authorHex,
        dTag: 'travel-profile',
        content: 'Nomadic developer traveling Latin America.',
        createdAt: DateTime.now(),
        gender: 'non-binary',
        birthYear: 1998,
        originCountry: 'USA',
        originCity: 'Seattle',
        homeCountry: 'Mexico',
        homeCity: 'Oaxaca',
        occupation: 'Dart Engineer',
        languages: const [
          LanguageProficiency(code: 'en', level: 'native'),
          LanguageProficiency(code: 'es', level: 'conversational'),
        ],
        modes: const ['host', 'rideshare'],
        interests: const ['nostr', 'open_source'],
        images: const ['https://image.nostr.build/oaxaca_sunset.jpg'],
        externalIdentities: const [
          ExternalIdentity(platform: 'triphopping', username: 'dartdev'),
        ],
      );

      final event = profile.toNip01Event(authorPubkey: authorHex);
      expect(event.kind, 30602);
      expect(event.pubKey, authorHex);

      final dTag = event.tags.firstWhere((t) => t.isNotEmpty && t[0] == 'd');
      expect(dTag[1], 'travel-profile');

      final genderTag = event.tags.firstWhere((t) => t.isNotEmpty && t[0] == 'gender');
      expect(genderTag[1], 'non-binary');

      final imageTag = event.tags.firstWhere((t) => t.isNotEmpty && t[0] == 'image');
      expect(imageTag[1], 'https://image.nostr.build/oaxaca_sunset.jpg');

      final birthYearTag = event.tags.firstWhere((t) => t.isNotEmpty && t[0] == 'birth_year');
      expect(birthYearTag[1], '1998');

      final modeTags = event.tags.where((t) => t.isNotEmpty && t[0] == 'mode').map((t) => t[1]).toList();
      expect(modeTags, ['host', 'rideshare']);

      final networkTags = event.tags.where((t) => t.isNotEmpty && t[0] == 'network').toList();
      expect(networkTags.length, 1);
      expect(networkTags[0][1], 'triphopping');
      expect(networkTags[0][2], 'dartdev');
    });

    test('ExternalIdentity generates correct platform names and URLs', () {
      const tripHopping = ExternalIdentity(platform: 'triphopping', username: 'alice');
      expect(tripHopping.platformName, 'Trip Hopping');
      expect(tripHopping.url, 'https://triphopping.com/profile/alice');

      const couchers = ExternalIdentity(platform: 'couchers', username: 'bob');
      expect(couchers.platformName, 'Couchers');
      expect(couchers.url, 'https://couchers.org/user/bob');

      const trustroots = ExternalIdentity(platform: 'trustroots', username: 'carol');
      expect(trustroots.platformName, 'Trustroots');
      expect(trustroots.url, 'https://www.trustroots.org/profile/carol');

      const couchsurfing = ExternalIdentity(platform: 'couchsurfing', username: 'dave');
      expect(couchsurfing.platformName, 'Couchsurfing');
      expect(couchsurfing.url, 'https://www.couchsurfing.com/people/dave');

      const warmshowers = ExternalIdentity(platform: 'warmshowers', username: 'eve');
      expect(warmshowers.platformName, 'WarmShowers');
      expect(warmshowers.url, 'https://www.warmshowers.org/users/eve');
    });
  });
}
