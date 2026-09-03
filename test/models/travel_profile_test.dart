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
          ['name', 'Alice Nomad'],
          ['gender', 'female'],
          ['birth_year', '1995'],
          ['birth_month', '4'],
          ['birth_day', '12'],
          ['origin_country', 'DE'],
          ['origin_city', 'Munich'],
          ['home_country', 'FR'],
          ['home_city', 'Lyon'],
          ['current_country', 'MX'],
          ['current_city', 'Oaxaca'],
          ['g', '9g3w8'],
          ['g', '9g3w'],
          ['g', '9g3'],
          ['occupation', 'Photographer'],
          ['education', 'Master in Visual Arts'],
          ['language', 'de', 'native'],
          ['language', 'en', 'fluent'],
          ['language', 'fr', 'intermediate'],
          ['t', 'cycling'],
          ['t', 'hiking'],
          ['t', 'meetup'],
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
      expect(profile.name, 'Alice Nomad');
      expect(profile.bestTravelerName, 'Alice Nomad');
      expect(profile.gender, 'female');
      expect(profile.birthYear, 1995);
      expect(profile.birthMonth, 4);
      expect(profile.birthDay, 12);
      expect(profile.calculatedAge, isNotNull);
      expect(profile.originCountry, 'DE');
      expect(profile.originCity, 'Munich');
      expect(profile.formattedOrigin, 'Munich, Germany');
      expect(profile.formattedHome, 'Lyon, France');
      expect(profile.formattedCurrent, 'Oaxaca, Mexico');
      expect(profile.currentCountry, 'MX');
      expect(profile.currentCity, 'Oaxaca');
      expect(profile.geohashes, ['9g3w8', '9g3w', '9g3']);
      expect(profile.occupation, 'Photographer');
      expect(profile.education, 'Master in Visual Arts');
      expect(profile.languages.length, 3);
      expect(profile.languages[0].code, 'de');
      expect(profile.languages[0].level, 'native');
      expect(profile.interests, ['cycling', 'hiking', 'meetup']);
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
        name: 'DartDev',
        gender: 'non-binary',
        birthYear: 1998,
        birthMonth: 8,
        birthDay: 20,
        originCountry: 'US',
        originCity: 'Seattle',
        homeCountry: 'MX',
        homeCity: 'Oaxaca',
        currentCountry: 'GT',
        currentCity: 'Antigua',
        geohashes: const ['9fxsn', '9fxs', '9fx'],
        occupation: 'Dart Engineer',
        languages: const [
          LanguageProficiency(code: 'en', level: 'native'),
          LanguageProficiency(code: 'es', level: 'conversational'),
        ],
        interests: const ['nostr', 'open_source', 'meetup'],
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

      final nameTag = event.tags.firstWhere((t) => t.isNotEmpty && t[0] == 'name');
      expect(nameTag[1], 'DartDev');

      final genderTag = event.tags.firstWhere((t) => t.isNotEmpty && t[0] == 'gender');
      expect(genderTag[1], 'non-binary');

      final birthYearTag = event.tags.firstWhere((t) => t.isNotEmpty && t[0] == 'birth_year');
      expect(birthYearTag[1], '1998');

      final birthMonthTag = event.tags.firstWhere((t) => t.isNotEmpty && t[0] == 'birth_month');
      expect(birthMonthTag[1], '8');

      final birthDayTag = event.tags.firstWhere((t) => t.isNotEmpty && t[0] == 'birth_day');
      expect(birthDayTag[1], '20');

      final originCountryTag = event.tags.firstWhere((t) => t.isNotEmpty && t[0] == 'origin_country');
      expect(originCountryTag[1], 'US');

      final currentCountryTag = event.tags.firstWhere((t) => t.isNotEmpty && t[0] == 'current_country');
      expect(currentCountryTag[1], 'GT');

      final currentCityTag = event.tags.firstWhere((t) => t.isNotEmpty && t[0] == 'current_city');
      expect(currentCityTag[1], 'Antigua');

      final gTags = event.tags.where((t) => t.isNotEmpty && t[0] == 'g').map((t) => t[1]).toList();
      expect(gTags, ['9fxsn', '9fxs', '9fx']);

      final imageTag = event.tags.firstWhere((t) => t.isNotEmpty && t[0] == 'image');
      expect(imageTag[1], 'https://image.nostr.build/oaxaca_sunset.jpg');

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
