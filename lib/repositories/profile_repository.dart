import 'package:ndk/entities.dart';
import '../core/constants/nostr_constants.dart';
import '../core/nostr/nostr_service.dart';
import '../models/travel_profile.dart';
import '../models/user_profile.dart';

/// Repository for retrieving and publishing Nostr Kind 0 user metadata
/// and Kind 30602 Travel & Community Profiles.
class ProfileRepository {
  final NostrService _nostrService;
  final Map<String, UserProfile> _profileCache = {};
  final Map<String, TravelProfile> _travelProfileCache = {};
  final Map<String, DateTime> _lastActiveCache = {};

  ProfileRepository(this._nostrService);

  /// Retrieves the standard Kind 0 user profile for a pubkey.
  Future<UserProfile?> getProfile(String pubkey, {bool forceRefresh = false}) async {
    if (!forceRefresh && _profileCache.containsKey(pubkey)) {
      return _profileCache[pubkey];
    }

    try {
      final ndkMetadata = await _nostrService.loadMetadata(pubkey);
      if (ndkMetadata != null) {
        final profile = UserProfile(
          pubkey: pubkey,
          name: ndkMetadata.name,
          displayName: ndkMetadata.displayName,
          picture: ndkMetadata.picture,
          banner: ndkMetadata.banner,
          about: ndkMetadata.about,
          nip05: ndkMetadata.nip05,
          website: ndkMetadata.website,
          lud16: ndkMetadata.lud16,
        );
        _profileCache[pubkey] = profile;
        return profile;
      }
    } catch (_) {
      // Fall through to direct filter query
    }

    final filter = Filter(
      kinds: [NostrConstants.metadataKind],
      authors: [pubkey],
      limit: 1,
    );

    try {
      final events = await _nostrService
          .queryEvents(filters: [filter])
          .timeout(const Duration(seconds: 4), onTimeout: (sink) => sink.close())
          .toList();

      if (events.isNotEmpty) {
        events.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        final profile = UserProfile.fromNip01Event(events.first);
        if (profile != null) {
          _profileCache[pubkey] = profile;
          return profile;
        }
      }
    } catch (_) {
      // Query error or timeout
    }

    return _profileCache[pubkey] ?? UserProfile(pubkey: pubkey);
  }

  /// Updates and broadcasts a Kind 0 user profile.
  Future<UserProfile> saveProfile(UserProfile profile) async {
    final event = profile.toNip01Event();
    await _nostrService.broadcastEvent(event);
    _profileCache[profile.pubkey] = profile;
    return profile;
  }

  /// Retrieves the Kind 30602 Travel & Community Profile for a pubkey.
  Future<TravelProfile?> getTravelProfile(String pubkey, {bool forceRefresh = false}) async {
    if (!forceRefresh && _travelProfileCache.containsKey(pubkey)) {
      return _travelProfileCache[pubkey];
    }

    final filter = Filter(
      kinds: [NostrConstants.travelProfileKind],
      authors: [pubkey],
      limit: 5,
    );

    try {
      final events = await _nostrService
          .queryEvents(filters: [filter])
          .timeout(const Duration(seconds: 4), onTimeout: (sink) => sink.close())
          .toList();

      if (events.isNotEmpty) {
        events.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        final travelProfile = TravelProfile.fromNip01Event(events.first);
        if (travelProfile != null) {
          _travelProfileCache[pubkey] = travelProfile;
          return travelProfile;
        }
      }
    } catch (_) {
      // Timeout or relay error
    }

    return _travelProfileCache[pubkey];
  }

  /// Updates and broadcasts a Kind 30602 Travel & Community Profile.
  Future<TravelProfile> saveTravelProfile(TravelProfile profile) async {
    final event = profile.toNip01Event(authorPubkey: profile.authorPubkey);
    await _nostrService.broadcastEvent(event);
    _travelProfileCache[profile.authorPubkey] = profile;
    return profile;
  }

  /// Retrieves the most recent public activity timestamp on Nostr for a pubkey.
  Future<DateTime?> getLastActive(String pubkey, {bool forceRefresh = false}) async {
    if (!forceRefresh && _lastActiveCache.containsKey(pubkey)) {
      return _lastActiveCache[pubkey];
    }

    final filter = Filter(
      authors: [pubkey],
      limit: 1,
    );

    try {
      final events = await _nostrService
          .queryEvents(filters: [filter])
          .timeout(const Duration(seconds: 4), onTimeout: (sink) => sink.close())
          .toList();

      if (events.isNotEmpty) {
        events.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        final latest = DateTime.fromMillisecondsSinceEpoch(events.first.createdAt * 1000);
        _lastActiveCache[pubkey] = latest;
        return latest;
      }
    } catch (_) {
      // Timeout or relay error
    }

    return _lastActiveCache[pubkey];
  }
}
