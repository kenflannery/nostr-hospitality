import 'package:ndk/entities.dart';
import '../core/constants/nostr_constants.dart';

/// Represents a Kind 7654 Interaction Reference (Draft NIP).
///
/// A reference is a historical, non-replaceable statement by one user
/// ([authorPubkey]) about another user ([subjectPubkey]).
class InteractionReference {
  final String id;
  final String authorPubkey;
  final String subjectPubkey;
  final String content;
  final DateTime createdAt;
  final List<String> contexts;
  final String? role;
  final String? sentiment;
  final String? associatedAddress; // "30402:<pubkey>:<d-tag>"
  final String? associatedEventId;
  final List<List<String>> rawTags;

  const InteractionReference({
    required this.id,
    required this.authorPubkey,
    required this.subjectPubkey,
    required this.content,
    required this.createdAt,
    this.contexts = const [],
    this.role,
    this.sentiment,
    this.associatedAddress,
    this.associatedEventId,
    this.rawTags = const [],
  });

  /// The primary context or 'hospitality' by default.
  String get primaryContext =>
      contexts.isNotEmpty ? contexts.first : NostrConstants.contextHospitality;

  bool get isPositive => sentiment == NostrConstants.sentimentPositive;
  bool get isNeutral => sentiment == NostrConstants.sentimentNeutral;
  bool get isNegative => sentiment == NostrConstants.sentimentNegative;

  /// Returns whether this reference was created in the context of hospitality.
  bool get isHospitality => contexts.contains(NostrConstants.contextHospitality);

  /// Returns whether the author was the host.
  bool get isAuthorHost => role == NostrConstants.roleHost;

  /// Returns whether the author was the guest.
  bool get isAuthorGuest => role == NostrConstants.roleGuest;

  /// Human-readable relationship direction description.
  ///
  /// Example: If author is guest referencing host: "Stayed as a guest with [Subject]"
  /// If author is host referencing guest: "Hosted [Subject]"
  String getRelationshipDescription({String? authorName, String? subjectName}) {
    final author = authorName ?? 'Author';
    final subject = subjectName ?? 'Host/Guest';

    if (role == NostrConstants.roleGuest) {
      return '$author stayed with $subject';
    } else if (role == NostrConstants.roleHost) {
      return '$author hosted $subject';
    } else if (role == NostrConstants.roleTravelCompanion ||
        role == NostrConstants.roleTraveler) {
      return '$author traveled with $subject';
    } else if (role != null && role!.isNotEmpty) {
      final formattedRole = role![0].toUpperCase() + role!.substring(1);
      return '$formattedRole interaction with $subject';
    } else if (contexts.contains(NostrConstants.contextMeeting)) {
      return '$author met $subject';
    } else {
      return 'Reference from $author for $subject';
    }
  }

  /// Parses a [Nip01Event] into an [InteractionReference].
  ///
  /// Returns null if the event kind is not 7654 or missing the required `p` tag.
  static InteractionReference? fromNip01Event(Nip01Event event) {
    if (event.kind != NostrConstants.interactionReferenceKind) {
      return null;
    }

    String? subjectPubkey;
    final contexts = <String>[];
    String? role;
    String? sentiment;
    String? associatedAddress;
    String? associatedEventId;

    for (final tag in event.tags) {
      if (tag.isEmpty) continue;
      final key = tag[0];

      if (key == NostrConstants.tagP && tag.length > 1) {
        subjectPubkey ??= tag[1]; // First p tag is the primary subject
      } else if (key == NostrConstants.tagContext && tag.length > 1) {
        contexts.add(tag[1]);
      } else if (key == NostrConstants.tagRole && tag.length > 1) {
        role ??= tag[1];
      } else if (key == NostrConstants.tagSentiment && tag.length > 1) {
        sentiment ??= tag[1];
      } else if (key == NostrConstants.tagA && tag.length > 1) {
        associatedAddress ??= tag[1];
      } else if (key == NostrConstants.tagE && tag.length > 1) {
        associatedEventId ??= tag[1];
      }
    }

    if (subjectPubkey == null || subjectPubkey.isEmpty) {
      return null;
    }

    return InteractionReference(
      id: event.id,
      authorPubkey: event.pubKey,
      subjectPubkey: subjectPubkey,
      content: event.content,
      createdAt: DateTime.fromMillisecondsSinceEpoch(event.createdAt * 1000),
      contexts: contexts,
      role: role,
      sentiment: sentiment, // strictly null if missing
      associatedAddress: associatedAddress,
      associatedEventId: associatedEventId,
      rawTags: event.tags,
    );
  }

  /// Converts this draft reference into an unsigned [Nip01Event].
  Nip01Event toNip01Event({required String authorPubkey}) {
    final tags = <List<String>>[
      [NostrConstants.tagP, subjectPubkey],
    ];

    for (final ctx in contexts) {
      if (ctx.isNotEmpty) {
        tags.add([NostrConstants.tagContext, ctx]);
      }
    }

    if (role != null && role!.isNotEmpty) {
      tags.add([NostrConstants.tagRole, role!]);
    }

    if (sentiment != null && sentiment!.isNotEmpty) {
      tags.add([NostrConstants.tagSentiment, sentiment!]);
    }

    if (associatedAddress != null && associatedAddress!.isNotEmpty) {
      tags.add([NostrConstants.tagA, associatedAddress!]);
    }

    if (associatedEventId != null && associatedEventId!.isNotEmpty) {
      tags.add([NostrConstants.tagE, associatedEventId!]);
    }

    return Nip01Event(
      pubKey: authorPubkey,
      kind: NostrConstants.interactionReferenceKind,
      tags: tags,
      content: content,
      createdAt: createdAt.millisecondsSinceEpoch ~/ 1000,
    );
  }

  InteractionReference copyWith({
    String? id,
    String? authorPubkey,
    String? subjectPubkey,
    String? content,
    DateTime? createdAt,
    List<String>? contexts,
    String? role,
    String? sentiment,
    String? associatedAddress,
    String? associatedEventId,
    List<List<String>>? rawTags,
  }) {
    return InteractionReference(
      id: id ?? this.id,
      authorPubkey: authorPubkey ?? this.authorPubkey,
      subjectPubkey: subjectPubkey ?? this.subjectPubkey,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      contexts: contexts ?? this.contexts,
      role: role ?? this.role,
      sentiment: sentiment ?? this.sentiment,
      associatedAddress: associatedAddress ?? this.associatedAddress,
      associatedEventId: associatedEventId ?? this.associatedEventId,
      rawTags: rawTags ?? this.rawTags,
    );
  }
}
