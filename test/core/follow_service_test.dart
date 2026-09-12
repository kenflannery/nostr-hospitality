import 'package:flutter_test/flutter_test.dart';
import 'package:nostr_hospitality/core/constants/nostr_constants.dart';
import 'package:nostr_hospitality/models/follow_list.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('FollowService Tests', () {
    const friend1 = 'c6047f9441ed7d6d3045406e95c07cd85c778e4b8cef3ca7abac09b95c709ee5';
    const friend2 = 'f0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef';

    test('Loads followed pubkeys from SharedPreferences cache', () async {
      SharedPreferences.setMockInitialValues({
        'following_pubkeys': [friend1],
      });
      final prefs = await SharedPreferences.getInstance();

      // Test without NostrService network calls
      final cachedList = prefs.getStringList('following_pubkeys') ?? [];
      expect(cachedList.contains(friend1), true);
      expect(cachedList.contains(friend2), false);
    });

    test('ContactList and HospitalityFollowSet synchronization models match specs', () {
      // Kind 3 model
      final contactList = NostrContactList(
        contacts: const [ContactEntry(pubkey: friend1)],
        createdAt: DateTime.now(),
      );
      expect(contactList.isFollowing(friend1), true);

      final withFriend2 = contactList.addFollow(friend2);
      expect(withFriend2.isFollowing(friend2), true);
      expect(withFriend2.contacts.length, 2);

      // Kind 30000 model
      final followSet = HospitalityFollowSet(
        followedPubkeys: {friend1},
        createdAt: DateTime.now(),
      );
      expect(followSet.isFollowing(friend1), true);

      final setWithFriend2 = followSet.addFollow(friend2);
      expect(setWithFriend2.isFollowing(friend2), true);
      expect(setWithFriend2.followedPubkeys.length, 2);

      final event30000 = setWithFriend2.toNip01Event(authorPubkey: 'me');
      expect(event30000.kind, NostrConstants.followSetKind);
      expect(event30000.tags.any((t) => t[0] == 'd' && t[1] == NostrConstants.followSetDTag), true);
      expect(event30000.tags.any((t) => t[0] == 'title' && t[1] == NostrConstants.followSetTitle), true);
      expect(event30000.tags.any((t) => t[0] == 'image' && t[1] == NostrConstants.followSetImage), true);
    });

    test('NostrContactList accurately computes contacts count for profile following links', () {
      final list = NostrContactList(
        contacts: const [
          ContactEntry(pubkey: friend1, petname: 'Friend 1'),
          ContactEntry(pubkey: friend2, petname: 'Friend 2'),
        ],
        createdAt: DateTime.now(),
      );

      expect(list.contacts.length, 2);
      expect(list.followedPubkeys.length, 2);
      expect(list.isFollowing(friend1), true);
      expect(list.isFollowing(friend2), true);
    });
  });
}
