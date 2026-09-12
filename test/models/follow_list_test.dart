import 'package:flutter_test/flutter_test.dart';
import 'package:ndk/entities.dart';
import 'package:nostr_hospitality/core/constants/nostr_constants.dart';
import 'package:nostr_hospitality/models/follow_list.dart';

void main() {
  group('Follow List Models Tests', () {
    const authorPubkey = '79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798';
    const friendPubkey1 = 'c6047f9441ed7d6d3045406e95c07cd85c778e4b8cef3ca7abac09b95c709ee5';
    const friendPubkey2 = 'f0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef';

    group('Kind 3 ContactList (NIP-02)', () {
      test('Parses ContactList with relay and petname', () {
        final nip01 = Nip01Event(
          pubKey: authorPubkey,
          kind: NostrConstants.contactListKind,
          tags: [
            ['p', friendPubkey1, 'wss://relay.damus.io', 'alice'],
            ['p', friendPubkey2],
            ['client', 'custom_client'],
          ],
          content: '',
          createdAt: 1719234800,
        );

        final contacts = NostrContactList.fromNip01Event(nip01);
        expect(contacts, isNotNull);
        expect(contacts!.contacts.length, 2);
        expect(contacts.isFollowing(friendPubkey1), true);
        expect(contacts.isFollowing(friendPubkey2), true);
        expect(contacts.isFollowing('unknown_pubkey'), false);

        final first = contacts.contacts.first;
        expect(first.pubkey, friendPubkey1);
        expect(first.relayUrl, 'wss://relay.damus.io');
        expect(first.petname, 'alice');
      });

      test('addFollow appends new contact non-destructively', () {
        final initialList = NostrContactList(
          contacts: const [
            ContactEntry(
              pubkey: friendPubkey1,
              relayUrl: 'wss://relay.damus.io',
              petname: 'alice',
            ),
          ],
          createdAt: DateTime(2026, 1, 1),
        );

        final updated = initialList.addFollow(friendPubkey2);
        expect(updated.contacts.length, 2);
        expect(updated.isFollowing(friendPubkey1), true);
        expect(updated.isFollowing(friendPubkey2), true);

        // Does not add duplicates
        final dupe = updated.addFollow(friendPubkey1);
        expect(dupe.contacts.length, 2);
      });

      test('removeFollow removes only the target contact', () {
        final initialList = NostrContactList(
          contacts: const [
            ContactEntry(pubkey: friendPubkey1),
            ContactEntry(pubkey: friendPubkey2),
          ],
          createdAt: DateTime(2026, 1, 1),
        );

        final updated = initialList.removeFollow(friendPubkey1);
        expect(updated.contacts.length, 1);
        expect(updated.isFollowing(friendPubkey1), false);
        expect(updated.isFollowing(friendPubkey2), true);
      });

      test('Converts ContactList to Nip01Event preserving non-p tags', () {
        final contactList = NostrContactList(
          contacts: const [
            ContactEntry(
              pubkey: friendPubkey1,
              relayUrl: 'wss://relay.damus.io',
              petname: 'alice',
            ),
          ],
          rawTags: const [
            ['client', 'custom_client'],
          ],
          createdAt: DateTime.now(),
        );

        final event = contactList.toNip01Event(authorPubkey: authorPubkey);
        expect(event.kind, NostrConstants.contactListKind);
        expect(event.pubKey, authorPubkey);
        expect(event.tags.length, 2);
        expect(event.tags[0], ['client', 'custom_client']);
        expect(event.tags[1], ['p', friendPubkey1, 'wss://relay.damus.io', 'alice']);
      });
    });

    group('Kind 30000 HospitalityFollowSet (NIP-51)', () {
      test('Parses HospitalityFollowSet correctly', () {
        final nip01 = Nip01Event(
          pubKey: authorPubkey,
          kind: NostrConstants.followSetKind,
          tags: [
            ['d', NostrConstants.followSetDTag],
            ['title', NostrConstants.followSetTitle],
            ['description', NostrConstants.followSetDescription],
            ['image', NostrConstants.followSetImage],
            ['p', friendPubkey1],
            ['p', friendPubkey2],
          ],
          content: '',
          createdAt: 1719234800,
        );

        final followSet = HospitalityFollowSet.fromNip01Event(nip01);
        expect(followSet, isNotNull);
        expect(followSet!.dTag, NostrConstants.followSetDTag);
        expect(followSet.title, NostrConstants.followSetTitle);
        expect(followSet.description, NostrConstants.followSetDescription);
        expect(followSet.image, NostrConstants.followSetImage);
        expect(followSet.followedPubkeys.length, 2);
        expect(followSet.isFollowing(friendPubkey1), true);
        expect(followSet.isFollowing(friendPubkey2), true);
        expect(followSet.isFollowing('unknown_pubkey'), false);
      });

      test('addFollow and removeFollow manipulate follow set', () {
        final followSet = HospitalityFollowSet(
          createdAt: DateTime.now(),
          followedPubkeys: {friendPubkey1},
        );

        final added = followSet.addFollow(friendPubkey2);
        expect(added.followedPubkeys.length, 2);
        expect(added.isFollowing(friendPubkey2), true);

        final removed = added.removeFollow(friendPubkey1);
        expect(removed.followedPubkeys.length, 1);
        expect(removed.isFollowing(friendPubkey1), false);
        expect(removed.isFollowing(friendPubkey2), true);
      });

      test('Converts HospitalityFollowSet to Nip01Event', () {
        final followSet = HospitalityFollowSet(
          followedPubkeys: {friendPubkey1},
          createdAt: DateTime.now(),
        );

        final event = followSet.toNip01Event(authorPubkey: authorPubkey);
        expect(event.kind, NostrConstants.followSetKind);
        expect(event.pubKey, authorPubkey);

        final dTag = event.tags.firstWhere((t) => t.first == 'd');
        expect(dTag[1], NostrConstants.followSetDTag);

        final titleTag = event.tags.firstWhere((t) => t.first == 'title');
        expect(titleTag[1], NostrConstants.followSetTitle);

        final imageTag = event.tags.firstWhere((t) => t.first == 'image');
        expect(imageTag[1], NostrConstants.followSetImage);

        final pTags = event.tags.where((t) => t.first == 'p').toList();
        expect(pTags.length, 1);
        expect(pTags.first[1], friendPubkey1);
      });
    });
  });
}
