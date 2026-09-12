import 'package:ndk/entities.dart';
import '../core/constants/nostr_constants.dart';

/// Represents a single contact in a Kind 3 Contact List (NIP-02).
class ContactEntry {
  final String pubkey;
  final String? relayUrl;
  final String? petname;

  const ContactEntry({
    required this.pubkey,
    this.relayUrl,
    this.petname,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContactEntry &&
          runtimeType == other.runtimeType &&
          pubkey.toLowerCase() == other.pubkey.toLowerCase();

  @override
  int get hashCode => pubkey.toLowerCase().hashCode;
}

/// Represents a Kind 3 Contact List (NIP-02).
///
/// This is the universal Nostr follow list recognized across all social and hospitality clients.
class NostrContactList {
  final List<ContactEntry> contacts;
  final String content;
  final DateTime createdAt;
  final List<List<String>> rawTags;

  const NostrContactList({
    this.contacts = const [],
    this.content = '',
    required this.createdAt,
    this.rawTags = const [],
  });

  /// Set of all lowercase followed pubkeys.
  Set<String> get followedPubkeys =>
      contacts.map((c) => c.pubkey.toLowerCase()).toSet();

  /// Checks if a pubkey is in this follow list.
  bool isFollowing(String pubkey) =>
      followedPubkeys.contains(pubkey.toLowerCase());

  /// Returns a new [NostrContactList] with [pubkey] added, preserving existing contacts and details.
  NostrContactList addFollow(String pubkey, {String? relayUrl, String? petname}) {
    final cleanPk = pubkey.trim().toLowerCase();
    if (isFollowing(cleanPk)) return this;

    final updated = List<ContactEntry>.from(contacts)
      ..add(ContactEntry(
        pubkey: pubkey.trim(),
        relayUrl: relayUrl,
        petname: petname,
      ));

    return NostrContactList(
      contacts: updated,
      content: content,
      createdAt: DateTime.now(),
      rawTags: rawTags,
    );
  }

  /// Returns a new [NostrContactList] with [pubkey] removed.
  NostrContactList removeFollow(String pubkey) {
    final cleanPk = pubkey.trim().toLowerCase();
    final updated = contacts
        .where((c) => c.pubkey.trim().toLowerCase() != cleanPk)
        .toList();

    return NostrContactList(
      contacts: updated,
      content: content,
      createdAt: DateTime.now(),
      rawTags: rawTags,
    );
  }

  /// Factory to parse from a Kind 3 [Nip01Event].
  static NostrContactList? fromNip01Event(Nip01Event event) {
    if (event.kind != NostrConstants.contactListKind) return null;

    final entries = <ContactEntry>[];
    for (final tag in event.tags) {
      if (tag.isNotEmpty && tag[0] == NostrConstants.tagP && tag.length > 1) {
        final pk = tag[1].trim();
        if (pk.isNotEmpty) {
          final relay = tag.length > 2 && tag[2].isNotEmpty ? tag[2] : null;
          final petname = tag.length > 3 && tag[3].isNotEmpty ? tag[3] : null;
          entries.add(ContactEntry(
            pubkey: pk,
            relayUrl: relay,
            petname: petname,
          ));
        }
      }
    }

    return NostrContactList(
      contacts: entries,
      content: event.content,
      createdAt: DateTime.fromMillisecondsSinceEpoch(event.createdAt * 1000),
      rawTags: event.tags,
    );
  }

  /// Converts this contact list into an unsigned Kind 3 [Nip01Event],
  /// preserving non-p tags from [rawTags].
  Nip01Event toNip01Event({required String authorPubkey}) {
    final eventTags = <List<String>>[];

    // Preserve non-'p' tags (e.g. relay lists or client tags)
    for (final tag in rawTags) {
      if (tag.isNotEmpty && tag[0] != NostrConstants.tagP) {
        eventTags.add(tag);
      }
    }

    // Add all contact entries with preserved metadata
    for (final contact in contacts) {
      final pTag = <String>[NostrConstants.tagP, contact.pubkey];
      if (contact.petname != null && contact.petname!.isNotEmpty) {
        pTag.add(contact.relayUrl ?? '');
        pTag.add(contact.petname!);
      } else if (contact.relayUrl != null && contact.relayUrl!.isNotEmpty) {
        pTag.add(contact.relayUrl!);
      }
      eventTags.add(pTag);
    }

    return Nip01Event(
      pubKey: authorPubkey,
      kind: NostrConstants.contactListKind,
      tags: eventTags,
      content: content,
      createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );
  }
}

/// Represents a Kind 30000 Categorized People List / Follow Set (NIP-51)
/// specifically for Hospitality Libre connections.
class HospitalityFollowSet {
  final String dTag;
  final String title;
  final String description;
  final String image;
  final Set<String> followedPubkeys;
  final DateTime createdAt;
  final List<List<String>> rawTags;

  const HospitalityFollowSet({
    this.dTag = NostrConstants.followSetDTag,
    this.title = NostrConstants.followSetTitle,
    this.description = NostrConstants.followSetDescription,
    this.image = NostrConstants.followSetImage,
    this.followedPubkeys = const {},
    required this.createdAt,
    this.rawTags = const [],
  });

  /// Checks if a pubkey is in this follow set.
  bool isFollowing(String pubkey) =>
      followedPubkeys.contains(pubkey.toLowerCase());

  /// Returns a new [HospitalityFollowSet] with [pubkey] added.
  HospitalityFollowSet addFollow(String pubkey) {
    final cleanPk = pubkey.trim().toLowerCase();
    if (isFollowing(cleanPk)) return this;

    final updated = Set<String>.from(followedPubkeys)..add(cleanPk);
    return HospitalityFollowSet(
      dTag: dTag,
      title: title,
      description: description,
      image: image,
      followedPubkeys: updated,
      createdAt: DateTime.now(),
      rawTags: rawTags,
    );
  }

  /// Returns a new [HospitalityFollowSet] with [pubkey] removed.
  HospitalityFollowSet removeFollow(String pubkey) {
    final cleanPk = pubkey.trim().toLowerCase();
    final updated = Set<String>.from(followedPubkeys)..remove(cleanPk);

    return HospitalityFollowSet(
      dTag: dTag,
      title: title,
      description: description,
      image: image,
      followedPubkeys: updated,
      createdAt: DateTime.now(),
      rawTags: rawTags,
    );
  }

  /// Factory to parse from a Kind 30000 [Nip01Event].
  static HospitalityFollowSet? fromNip01Event(Nip01Event event) {
    if (event.kind != NostrConstants.followSetKind) return null;

    String dTag = NostrConstants.followSetDTag;
    String title = NostrConstants.followSetTitle;
    String description = NostrConstants.followSetDescription;
    String image = NostrConstants.followSetImage;
    final pubkeys = <String>{};

    for (final tag in event.tags) {
      if (tag.isEmpty) continue;
      final key = tag[0];

      if (key == NostrConstants.tagD && tag.length > 1) {
        dTag = tag[1];
      } else if (key == 'title' && tag.length > 1) {
        title = tag[1];
      } else if (key == 'description' && tag.length > 1) {
        description = tag[1];
      } else if (key == 'image' && tag.length > 1) {
        image = tag[1];
      } else if (key == NostrConstants.tagP && tag.length > 1) {
        final pk = tag[1].trim().toLowerCase();
        if (pk.isNotEmpty) {
          pubkeys.add(pk);
        }
      }
    }

    return HospitalityFollowSet(
      dTag: dTag,
      title: title,
      description: description,
      image: image,
      followedPubkeys: pubkeys,
      createdAt: DateTime.fromMillisecondsSinceEpoch(event.createdAt * 1000),
      rawTags: event.tags,
    );
  }

  /// Converts this follow set into an unsigned Kind 30000 [Nip01Event].
  Nip01Event toNip01Event({required String authorPubkey}) {
    final eventTags = <List<String>>[
      [NostrConstants.tagD, dTag],
      ['title', title],
      ['description', description],
      ['image', image],
    ];

    // Preserve non-standard tags from rawTags if any
    for (final tag in rawTags) {
      if (tag.isNotEmpty &&
          tag[0] != NostrConstants.tagD &&
          tag[0] != 'title' &&
          tag[0] != 'description' &&
          tag[0] != 'image' &&
          tag[0] != NostrConstants.tagP) {
        eventTags.add(tag);
      }
    }

    // Add all followed pubkeys
    for (final pk in followedPubkeys) {
      eventTags.add([NostrConstants.tagP, pk]);
    }

    return Nip01Event(
      pubKey: authorPubkey,
      kind: NostrConstants.followSetKind,
      tags: eventTags,
      content: '',
      createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );
  }
}
