import 'package:ndk/entities.dart';
import '../core/constants/nostr_constants.dart';

/// Represents a Kind 10000 Mute List (NIP-51).
class MuteList {
  final Set<String> mutedPubkeys;
  final DateTime createdAt;
  final List<List<String>> rawTags;

  const MuteList({
    this.mutedPubkeys = const {},
    required this.createdAt,
    this.rawTags = const [],
  });

  bool isMuted(String pubkey) => mutedPubkeys.contains(pubkey.toLowerCase());

  /// Factory to parse from a Kind 10000 [Nip01Event].
  static MuteList? fromNip01Event(Nip01Event event) {
    if (event.kind != NostrConstants.muteListKind) return null;

    final muted = <String>{};
    for (final tag in event.tags) {
      if (tag.isNotEmpty && tag[0] == NostrConstants.tagP && tag.length > 1) {
        final pk = tag[1].trim().toLowerCase();
        if (pk.isNotEmpty) muted.add(pk);
      }
    }

    return MuteList(
      mutedPubkeys: muted,
      createdAt: DateTime.fromMillisecondsSinceEpoch(event.createdAt * 1000),
      rawTags: event.tags,
    );
  }

  /// Converts this mute list into an unsigned Kind 10000 [Nip01Event].
  Nip01Event toNip01Event({required String authorPubkey}) {
    final eventTags = <List<String>>[];
    for (final pk in mutedPubkeys) {
      eventTags.add([NostrConstants.tagP, pk]);
    }

    return Nip01Event(
      pubKey: authorPubkey,
      kind: NostrConstants.muteListKind,
      tags: eventTags,
      content: '',
      createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );
  }

  MuteList copyWith({Set<String>? mutedPubkeys, DateTime? createdAt}) {
    return MuteList(
      mutedPubkeys: mutedPubkeys ?? this.mutedPubkeys,
      createdAt: createdAt ?? this.createdAt,
      rawTags: rawTags,
    );
  }
}

/// Represents a Kind 1984 Report (NIP-56).
class ReportEvent {
  final String id;
  final String authorPubkey;
  final String? targetPubkey;
  final String? targetEventId;
  final String reportType;
  final String content;
  final DateTime createdAt;

  const ReportEvent({
    required this.id,
    required this.authorPubkey,
    this.targetPubkey,
    this.targetEventId,
    required this.reportType,
    this.content = '',
    required this.createdAt,
  });

  /// Factory to parse from a Kind 1984 [Nip01Event].
  static ReportEvent? fromNip01Event(Nip01Event event) {
    if (event.kind != NostrConstants.reportKind) return null;

    String? targetPubkey;
    String? targetEventId;
    String? reportType;

    for (final tag in event.tags) {
      if (tag.isEmpty) continue;
      final key = tag[0];

      if (key == NostrConstants.tagP && tag.length > 1) {
        targetPubkey ??= tag[1];
        if (tag.length > 2 && tag[2].isNotEmpty) {
          reportType ??= tag[2];
        }
      } else if (key == NostrConstants.tagE && tag.length > 1) {
        targetEventId ??= tag[1];
        if (tag.length > 2 && tag[2].isNotEmpty) {
          reportType ??= tag[2];
        }
      }
    }

    if (reportType == null || (targetPubkey == null && targetEventId == null)) {
      return null;
    }

    return ReportEvent(
      id: event.id,
      authorPubkey: event.pubKey,
      targetPubkey: targetPubkey,
      targetEventId: targetEventId,
      reportType: reportType,
      content: event.content.trim(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(event.createdAt * 1000),
    );
  }

  /// Converts this report into an unsigned Kind 1984 [Nip01Event].
  Nip01Event toNip01Event({required String authorPubkey}) {
    final eventTags = <List<String>>[];

    if (targetEventId != null && targetEventId!.isNotEmpty) {
      eventTags.add([NostrConstants.tagE, targetEventId!, reportType]);
      if (targetPubkey != null && targetPubkey!.isNotEmpty) {
        eventTags.add([NostrConstants.tagP, targetPubkey!]);
      }
    } else if (targetPubkey != null && targetPubkey!.isNotEmpty) {
      eventTags.add([NostrConstants.tagP, targetPubkey!, reportType]);
    }

    return Nip01Event(
      pubKey: authorPubkey,
      kind: NostrConstants.reportKind,
      tags: eventTags,
      content: content,
      createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );
  }
}

/// Represents a Kind 30015 Cautionary Tag Interest Set (NIP-51).
class CautionaryTagSet {
  final Set<String> tags;
  final DateTime createdAt;

  const CautionaryTagSet({
    this.tags = const {},
    required this.createdAt,
  });

  /// Returns true if [tag] is considered cautionary by this set or default list.
  bool isCautionary(String tag) {
    final clean = tag.trim().toLowerCase();
    if (tags.isNotEmpty) {
      return tags.contains(clean);
    }
    return NostrConstants.defaultCautionaryTags.contains(clean);
  }

  /// Factory from a Kind 30015 [Nip01Event].
  static CautionaryTagSet? fromNip01Event(Nip01Event event) {
    if (event.kind != NostrConstants.interestSetKind) return null;

    String? dTag;
    final setTags = <String>{};

    for (final tag in event.tags) {
      if (tag.isEmpty) continue;
      if (tag[0] == NostrConstants.tagD && tag.length > 1) {
        dTag = tag[1];
      } else if (tag[0] == NostrConstants.tagT && tag.length > 1) {
        final t = tag[1].trim().toLowerCase();
        if (t.isNotEmpty) setTags.add(t);
      }
    }

    if (dTag != NostrConstants.cautionaryTagsSetDTag) return null;

    return CautionaryTagSet(
      tags: setTags,
      createdAt: DateTime.fromMillisecondsSinceEpoch(event.createdAt * 1000),
    );
  }

  /// Default set using [NostrConstants.defaultCautionaryTags].
  static CautionaryTagSet defaultSet() {
    return CautionaryTagSet(
      tags: Set.from(NostrConstants.defaultCautionaryTags),
      createdAt: DateTime.now(),
    );
  }

  /// Converts to an unsigned Kind 30015 [Nip01Event].
  Nip01Event toNip01Event({required String authorPubkey}) {
    final eventTags = <List<String>>[
      [NostrConstants.tagD, NostrConstants.cautionaryTagsSetDTag],
      ...tags.map((t) => [NostrConstants.tagT, t.trim().toLowerCase()]),
    ];

    return Nip01Event(
      pubKey: authorPubkey,
      kind: NostrConstants.interestSetKind,
      tags: eventTags,
      content: '',
      createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );
  }
}
