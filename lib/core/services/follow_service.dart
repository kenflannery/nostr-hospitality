import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:ndk/entities.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/nostr_constants.dart';
import '../nostr/nostr_service.dart';
import '../../models/follow_list.dart';

/// Service managing user follows across:
/// - Universal Contact List (NIP-02 Kind 3)
/// - Hospitality Libre Follow Set (NIP-51 Kind 30000)
class FollowService extends ChangeNotifier {
  final NostrService _nostrService;
  final SharedPreferences _prefs;

  static const String _prefKeyFollowingPubkeys = 'following_pubkeys';

  final ValueNotifier<Set<String>> followingNotifier =
      ValueNotifier<Set<String>>({});

  NostrContactList? _cachedContactList;
  HospitalityFollowSet? _cachedFollowSet;

  FollowService(this._nostrService, this._prefs) {
    _loadFromCache();
  }

  Set<String> get followingPubkeys => followingNotifier.value;

  void _loadFromCache() {
    final cached = _prefs.getStringList(_prefKeyFollowingPubkeys) ?? [];
    followingNotifier.value = cached.map((p) => p.toLowerCase()).toSet();
  }

  final Map<String, NostrContactList> _userContactsCache = {};

  /// Synchronous check if a given pubkey is followed.
  bool isFollowing(String pubkey) {
    return followingNotifier.value.contains(pubkey.trim().toLowerCase());
  }

  /// Retrieves the Kind 3 contact list (or Kind 30000 fallback) for any user pubkey.
  Future<NostrContactList?> getContactsForUser(
    String pubkey, {
    bool forceRefresh = false,
  }) async {
    final clean = pubkey.trim().toLowerCase();
    if (clean.isEmpty) return null;

    final activePubkey =
        _nostrService.signerService.activePublicKey?.toLowerCase();
    if (clean == activePubkey && _cachedContactList != null && !forceRefresh) {
      return _cachedContactList;
    }

    if (!forceRefresh && _userContactsCache.containsKey(clean)) {
      return _userContactsCache[clean];
    }

    // 1. Try Kind 3 Contact List
    try {
      final contactFilter = Filter(
        kinds: [NostrConstants.contactListKind],
        authors: [clean],
        limit: 1,
      );

      final events = await _nostrService
          .queryEvents(filters: [contactFilter])
          .timeout(const Duration(seconds: 4), onTimeout: (sink) => sink.close())
          .toList();

      if (events.isNotEmpty) {
        events.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        final parsed = NostrContactList.fromNip01Event(events.first);
        if (parsed != null) {
          _userContactsCache[clean] = parsed;
          if (clean == activePubkey) {
            _cachedContactList = parsed;
          }
          return parsed;
        }
      }
    } catch (e) {
      debugPrint('FollowService: Error loading contacts for $clean: $e');
    }

    // 2. Fallback to Kind 30000 Hospitality Follow Set if no Kind 3
    try {
      final setFilter = Filter(
        kinds: [NostrConstants.followSetKind],
        authors: [clean],
        dTags: [NostrConstants.followSetDTag],
        limit: 1,
      );

      final setEvents = await _nostrService
          .queryEvents(filters: [setFilter])
          .timeout(const Duration(seconds: 3), onTimeout: (sink) => sink.close())
          .toList();

      if (setEvents.isNotEmpty) {
        setEvents.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        final setParsed = HospitalityFollowSet.fromNip01Event(setEvents.first);
        if (setParsed != null && setParsed.followedPubkeys.isNotEmpty) {
          final synthetic = NostrContactList(
            contacts: setParsed.followedPubkeys
                .map((pk) => ContactEntry(pubkey: pk))
                .toList(),
            createdAt: setParsed.createdAt,
            rawTags: setParsed.rawTags,
          );
          _userContactsCache[clean] = synthetic;
          return synthetic;
        }
      }
    } catch (_) {}

    return _userContactsCache[clean];
  }

  /// Initializes by fetching the active user's Kind 3 and Kind 30000 from relays.
  Future<void> syncWithRelays() async {
    final pubkey = _nostrService.signerService.activePublicKey;
    if (pubkey == null) return;

    final mergedFollows = Set<String>.from(followingNotifier.value);

    // 1. Fetch Kind 3 (NIP-02 Contact List)
    try {
      final contactFilter = Filter(
        kinds: [NostrConstants.contactListKind],
        authors: [pubkey],
        limit: 1,
      );

      final events = await _nostrService
          .queryEvents(filters: [contactFilter])
          .first
          .timeout(
            const Duration(seconds: 3),
            onTimeout: () => Nip01Event(
              pubKey: pubkey,
              kind: 0,
              tags: [],
              content: '',
              createdAt: 0,
            ),
          );

      final parsedContacts = NostrContactList.fromNip01Event(events);
      if (parsedContacts != null) {
        _cachedContactList = parsedContacts;
        mergedFollows.addAll(parsedContacts.followedPubkeys);
      }
    } catch (e) {
      debugPrint('FollowService: Failed to sync Kind 3 contact list: $e');
    }

    // 2. Fetch Kind 30000 (NIP-51 Hospitality Follow Set)
    try {
      final followSetFilter = Filter(
        kinds: [NostrConstants.followSetKind],
        authors: [pubkey],
        dTags: [NostrConstants.followSetDTag],
        limit: 1,
      );

      final setEvent = await _nostrService
          .queryEvents(filters: [followSetFilter])
          .first
          .timeout(
            const Duration(seconds: 3),
            onTimeout: () => Nip01Event(
              pubKey: pubkey,
              kind: 0,
              tags: [],
              content: '',
              createdAt: 0,
            ),
          );

      final parsedSet = HospitalityFollowSet.fromNip01Event(setEvent);
      if (parsedSet != null) {
        _cachedFollowSet = parsedSet;
        mergedFollows.addAll(parsedSet.followedPubkeys);
      }
    } catch (e) {
      debugPrint('FollowService: Failed to sync Kind 30000 follow set: $e');
    }

    followingNotifier.value = mergedFollows;
    await _prefs.setStringList(_prefKeyFollowingPubkeys, mergedFollows.toList());
    notifyListeners();
  }

  /// Follows a user:
  /// 1. Optimistically updates local cache and reactive notifier.
  /// 2. Non-destructively merges into NIP-02 Kind 3 contact list and broadcasts.
  /// 3. Adds to NIP-51 Kind 30000 follow set and broadcasts.
  Future<void> followUser(String targetPubkey) async {
    final clean = targetPubkey.trim().toLowerCase();
    if (clean.isEmpty) return;

    // Optimistic local update
    final updated = Set<String>.from(followingNotifier.value)..add(clean);
    followingNotifier.value = updated;
    await _prefs.setStringList(_prefKeyFollowingPubkeys, updated.toList());
    notifyListeners();

    final activePubkey = _nostrService.signerService.activePublicKey;
    if (activePubkey == null) return;

    // Update Kind 3
    final contactList = (_cachedContactList ??
            NostrContactList(
              contacts: [ContactEntry(pubkey: clean)],
              createdAt: DateTime.now(),
            ))
        .addFollow(clean);
    _cachedContactList = contactList;

    try {
      final kind3Event = contactList.toNip01Event(authorPubkey: activePubkey);
      await _nostrService.broadcastEvent(kind3Event);
    } catch (e) {
      debugPrint('FollowService: Error broadcasting Kind 3: $e');
    }

    // Update Kind 30000
    final followSet = (_cachedFollowSet ??
            HospitalityFollowSet(
              followedPubkeys: {clean},
              createdAt: DateTime.now(),
            ))
        .addFollow(clean);
    _cachedFollowSet = followSet;

    try {
      final kind30000Event = followSet.toNip01Event(authorPubkey: activePubkey);
      await _nostrService.broadcastEvent(kind30000Event);
    } catch (e) {
      debugPrint('FollowService: Error broadcasting Kind 30000: $e');
    }
  }

  /// Unfollows a user:
  /// 1. Optimistically removes from local cache and reactive notifier.
  /// 2. Removes from NIP-02 Kind 3 contact list and broadcasts.
  /// 3. Removes from NIP-51 Kind 30000 follow set and broadcasts.
  Future<void> unfollowUser(String targetPubkey) async {
    final clean = targetPubkey.trim().toLowerCase();
    if (clean.isEmpty) return;

    // Optimistic local update
    final updated = Set<String>.from(followingNotifier.value)..remove(clean);
    followingNotifier.value = updated;
    await _prefs.setStringList(_prefKeyFollowingPubkeys, updated.toList());
    notifyListeners();

    final activePubkey = _nostrService.signerService.activePublicKey;
    if (activePubkey == null) return;

    // Update Kind 3
    if (_cachedContactList != null) {
      final contactList = _cachedContactList!.removeFollow(clean);
      _cachedContactList = contactList;
      try {
        final kind3Event = contactList.toNip01Event(authorPubkey: activePubkey);
        await _nostrService.broadcastEvent(kind3Event);
      } catch (e) {
        debugPrint('FollowService: Error broadcasting unfollow Kind 3: $e');
      }
    }

    // Update Kind 30000
    if (_cachedFollowSet != null) {
      final followSet = _cachedFollowSet!.removeFollow(clean);
      _cachedFollowSet = followSet;
      try {
        final kind30000Event = followSet.toNip01Event(authorPubkey: activePubkey);
        await _nostrService.broadcastEvent(kind30000Event);
      } catch (e) {
        debugPrint('FollowService: Error broadcasting unfollow Kind 30000: $e');
      }
    }
  }
}
