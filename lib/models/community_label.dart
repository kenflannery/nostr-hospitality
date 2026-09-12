import 'package:ndk/entities.dart';
import '../core/constants/nostr_constants.dart';

/// Represents a Kind 1985 Community Label (NIP-32).
///
/// A label is an assertion or community note applied by [authorPubkey]
/// to a target pubkey [targetPubkey], or optionally a specific event [targetEventId]
/// or coordinate [targetCoordinate].
class CommunityLabel {
  final String id;
  final String authorPubkey;
  final String targetPubkey;
  final String? targetEventId;
  final String? targetCoordinate;
  final String tag;
  final String namespace;
  final String comment;
  final DateTime createdAt;
  final List<List<String>> rawTags;

  const CommunityLabel({
    required this.id,
    required this.authorPubkey,
    required this.targetPubkey,
    this.targetEventId,
    this.targetCoordinate,
    required this.tag,
    this.namespace = NostrConstants.labelNamespaceTopic,
    this.comment = '',
    required this.createdAt,
    this.rawTags = const [],
  });

  /// Factory to parse a [CommunityLabel] from a raw [Nip01Event].
  static CommunityLabel? fromNip01Event(Nip01Event event) {
    if (event.kind != NostrConstants.labelKind) return null;

    String? targetPubkey;
    String? targetEventId;
    String? targetCoordinate;
    String? namespace;
    String? labelTag;

    for (final tag in event.tags) {
      if (tag.isEmpty) continue;
      final key = tag[0];

      if (key == NostrConstants.tagP && tag.length > 1) {
        targetPubkey ??= tag[1];
      } else if (key == NostrConstants.tagE && tag.length > 1) {
        targetEventId ??= tag[1];
      } else if (key == NostrConstants.tagA && tag.length > 1) {
        targetCoordinate ??= tag[1];
      } else if (key == NostrConstants.tagL && tag.length > 1) {
        namespace ??= tag[1];
      } else if (key == NostrConstants.tagSmallL && tag.length > 1) {
        labelTag ??= tag[1].trim().toLowerCase();
        if (tag.length > 2 && tag[2].isNotEmpty) {
          namespace ??= tag[2];
        }
      }
    }

    if (targetPubkey == null || labelTag == null || labelTag.isEmpty) {
      return null;
    }

    return CommunityLabel(
      id: event.id,
      authorPubkey: event.pubKey,
      targetPubkey: targetPubkey,
      targetEventId: targetEventId,
      targetCoordinate: targetCoordinate,
      tag: labelTag,
      namespace: namespace ?? NostrConstants.labelNamespaceTopic,
      comment: event.content.trim(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(event.createdAt * 1000),
      rawTags: event.tags,
    );
  }

  /// Converts this label into an unsigned [Nip01Event].
  Nip01Event toNip01Event({required String authorPubkey}) {
    final eventTags = <List<String>>[
      [NostrConstants.tagL, namespace],
      [NostrConstants.tagSmallL, tag.trim().toLowerCase(), namespace],
      [NostrConstants.tagP, targetPubkey],
    ];

    if (targetEventId != null && targetEventId!.isNotEmpty) {
      eventTags.add([NostrConstants.tagE, targetEventId!]);
    }

    if (targetCoordinate != null && targetCoordinate!.isNotEmpty) {
      eventTags.add([NostrConstants.tagA, targetCoordinate!]);
    }

    return Nip01Event(
      pubKey: authorPubkey,
      kind: NostrConstants.labelKind,
      tags: eventTags,
      content: comment,
      createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );
  }
}
