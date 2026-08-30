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
          ['i', 'trustroots:alice_nomad'],
          ['i', 'couchsurfing:alice.traveler'],
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
      expect(profile.externalIdentities.length, 2);
      expect(profile.externalIdentities[0].platform, 'trustroots');
      expect(profile.externalIdentities[0].username, 'alice_nomad');
      expect(profile.externalIdentities[0].platformName, 'Trustroots');
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
        externalIdentities: const [
          ExternalIdentity(platform: 'github', username: 'dartdev'),
        ],
      );

      final event = profile.toNip01Event(authorPubkey: authorHex);
      expect(event.kind, 30602);
      expect(event.pubKey, authorHex);

      final dTag = event.tags.firstWhere((t) => t.isNotEmpty && t[0] == 'd');
      expect(dTag[1], 'travel-profile');

      final genderTag = event.tags.firstWhere((t) => t.isNotEmpty && t[0] == 'gender');
      expect(genderTag[1], 'non-binary');

      final birthYearTag = event.tags.firstWhere((t) => t.isNotEmpty && t[0] == 'birth_year');
      expect(birthYearTag[1], '1998');

      final modeTags = event.tags.where((t) => t.isNotEmpty && t[0] == 'mode').map((t) => t[1]).toList();
      expect(modeTags, ['host', 'rideshare']);

      final iTags = event.tags.where((t) => t.isNotEmpty && t[0] == 'i').map((t) => t[1]).toList();
      expect(iTags, ['github:dartdev']);
    });
  });
}
