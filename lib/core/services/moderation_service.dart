import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:ndk/entities.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/nostr_constants.dart';
import '../nostr/nostr_service.dart';
import '../../models/moderation_models.dart';

/// Service managing user moderation:
/// - Mute / Block List (NIP-51 Kind 10000)
/// - Reporting (NIP-56 Kind 1984)
/// - Cautionary Tag Interest Set (NIP-51 Kind 30015)
class ModerationService {
  final NostrService _nostrService;
  final SharedPreferences _prefs;

  static const String _prefKeyMutedPubkeys = 'moderation_muted_pubkeys';
  static const String _prefKeyCautionTags = 'moderation_caution_tags';

  final ValueNotifier<Set<String>> mutedPubkeysNotifier = ValueNotifier<Set<String>>({});
  final ValueNotifier<Set<String>> cautionTagsNotifier = ValueNotifier<Set<String>>({});

  ModerationService(this._nostrService, this._prefs) {
    _loadFromCache();
  }

  Set<String> get mutedPubkeys => mutedPubkeysNotifier.value;
  Set<String> get cautionTags => cautionTagsNotifier.value;

  void _loadFromCache() {
    final cachedMuted = _prefs.getStringList(_prefKeyMutedPubkeys) ?? [];
    mutedPubkeysNotifier.value = cachedMuted.map((p) => p.toLowerCase()).toSet();

    final cachedCaution = _prefs.getStringList(_prefKeyCautionTags);
    if (cachedCaution != null && cachedCaution.isNotEmpty) {
      cautionTagsNotifier.value = cachedCaution.map((t) => t.toLowerCase()).toSet();
    } else {
      cautionTagsNotifier.value = Set.from(NostrConstants.defaultCautionaryTags);
    }
  }

  /// Initializes by fetching the active user's Kind 10000 and Kind 30015 from relays.
  Future<void> syncWithRelays() async {
    final pubkey = _nostrService.signerService.activePublicKey;
    if (pubkey == null) return;

    try {
      // 1. Fetch Kind 10000 (Mute List)
      final muteFilter = Filter(
        kinds: [NostrConstants.muteListKind],
        authors: [pubkey],
        limit: 1,
      );

      final events = await _nostrService.queryEvents(filters: [muteFilter]).first.timeout(
            const Duration(seconds: 3),
            onTimeout: () => Nip01Event(
              pubKey: pubkey,
              kind: 0,
              tags: [],
              content: '',
              createdAt: 0,
            ),
          );

      final parsedMute = MuteList.fromNip01Event(events);
      if (parsedMute != null && parsedMute.mutedPubkeys.isNotEmpty) {
        final merged = {...mutedPubkeysNotifier.value, ...parsedMute.mutedPubkeys};
        mutedPubkeysNotifier.value = merged;
        await _prefs.setStringList(_prefKeyMutedPubkeys, merged.toList());
      }
    } catch (_) {}

    try {
      // 2. Fetch Kind 30015 (Cautionary Tag Set)
      final cautionFilter = Filter(
        kinds: [NostrConstants.interestSetKind],
        authors: [pubkey],
        dTags: [NostrConstants.cautionaryTagsSetDTag],
        limit: 1,
      );

      final cautionEvent = await _nostrService.queryEvents(filters: [cautionFilter]).first.timeout(
            const Duration(seconds: 3),
            onTimeout: () => Nip01Event(
              pubKey: pubkey,
              kind: 0,
              tags: [],
              content: '',
              createdAt: 0,
            ),
          );

      final parsedCaution = CautionaryTagSet.fromNip01Event(cautionEvent);
      if (parsedCaution != null && parsedCaution.tags.isNotEmpty) {
        cautionTagsNotifier.value = parsedCaution.tags;
        await _prefs.setStringList(_prefKeyCautionTags, parsedCaution.tags.toList());
      }
    } catch (_) {}
  }

  /// Synchronous check if a given pubkey is muted.
  bool isMuted(String pubkey) {
    return mutedPubkeysNotifier.value.contains(pubkey.toLowerCase());
  }

  /// Returns true if the given tag is classified as cautionary by user or defaults.
  bool isCautionary(String tag) {
    final clean = tag.trim().toLowerCase();
    if (cautionTagsNotifier.value.isNotEmpty) {
      return cautionTagsNotifier.value.contains(clean);
    }
    return NostrConstants.defaultCautionaryTags.contains(clean);
  }

  /// Adds a pubkey to the mute list, updates local cache, and broadcasts Kind 10000.
  Future<void> mutePubkey(String pubkey) async {
    final clean = pubkey.trim().toLowerCase();
    final updated = Set<String>.from(mutedPubkeysNotifier.value)..add(clean);
    mutedPubkeysNotifier.value = updated;
    await _prefs.setStringList(_prefKeyMutedPubkeys, updated.toList());

    final activePubkey = _nostrService.signerService.activePublicKey;
    if (activePubkey != null) {
      final muteList = MuteList(mutedPubkeys: updated, createdAt: DateTime.now());
      final event = muteList.toNip01Event(authorPubkey: activePubkey);
      try {
        await _nostrService.broadcastEvent(event);
      } catch (e) {
        debugPrint('Failed to broadcast Kind 10000 mute list: $e');
      }
    }
  }

  /// Removes a pubkey from the mute list, updates local cache, and broadcasts Kind 10000.
  Future<void> unmutePubkey(String pubkey) async {
    final clean = pubkey.trim().toLowerCase();
    final updated = Set<String>.from(mutedPubkeysNotifier.value)..remove(clean);
    mutedPubkeysNotifier.value = updated;
    await _prefs.setStringList(_prefKeyMutedPubkeys, updated.toList());

    final activePubkey = _nostrService.signerService.activePublicKey;
    if (activePubkey != null) {
      final muteList = MuteList(mutedPubkeys: updated, createdAt: DateTime.now());
      final event = muteList.toNip01Event(authorPubkey: activePubkey);
      try {
        await _nostrService.broadcastEvent(event);
      } catch (e) {
        debugPrint('Failed to broadcast Kind 10000 mute list: $e');
      }
    }
  }

  /// Submits a NIP-56 Kind 1984 report, optionally muting the target as well.
  Future<void> submitReport({
    String? targetPubkey,
    String? targetEventId,
    required String reportType,
    String content = '',
    bool alsoMute = true,
  }) async {
    final activePubkey = _nostrService.signerService.activePublicKey;
    if (activePubkey == null) {
      throw StateError('Cannot report: User is not authenticated.');
    }

    final report = ReportEvent(
      id: '',
      authorPubkey: activePubkey,
      targetPubkey: targetPubkey,
      targetEventId: targetEventId,
      reportType: reportType,
      content: content.trim(),
      createdAt: DateTime.now(),
    );

    final event = report.toNip01Event(authorPubkey: activePubkey);
    await _nostrService.broadcastEvent(event);

    if (alsoMute && targetPubkey != null && targetPubkey.isNotEmpty) {
      await mutePubkey(targetPubkey);
    }
  }

  /// Updates the user's customized cautionary tags (Kind 30015).
  Future<void> updateCautionaryTags(Set<String> newTags) async {
    final cleanTags = newTags.map((t) => t.trim().toLowerCase()).where((t) => t.isNotEmpty).toSet();
    cautionTagsNotifier.value = cleanTags;
    await _prefs.setStringList(_prefKeyCautionTags, cleanTags.toList());

    final activePubkey = _nostrService.signerService.activePublicKey;
    if (activePubkey != null) {
      final cautionSet = CautionaryTagSet(tags: cleanTags, createdAt: DateTime.now());
      final event = cautionSet.toNip01Event(authorPubkey: activePubkey);
      try {
        await _nostrService.broadcastEvent(event);
      } catch (e) {
        debugPrint('Failed to broadcast Kind 30015 caution set: $e');
      }
    }
  }
}
