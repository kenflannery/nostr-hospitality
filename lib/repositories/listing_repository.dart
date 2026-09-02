import 'dart:async';
import 'package:ndk/entities.dart';
import '../core/constants/nostr_constants.dart';
import '../core/nostr/nostr_service.dart';
import '../models/hospitality_listing.dart';

/// Filter for listing classification intent (Offer vs. Request).
enum ListingTypeFilter {
  all,
  offersOnly,
  requestsOnly,
}

/// Repository for creating, updating, and querying NIP-99 Kind 30402 hospitality listings.
class ListingRepository {
  final NostrService _nostrService;

  ListingRepository(this._nostrService);

  /// Streams available hospitality listings from relays and cache.
  Stream<List<HospitalityListing>> getHospitalityListingsStream({
    String? locationFilter,
    ListingTypeFilter typeFilter = ListingTypeFilter.all,
    int limit = 50,
  }) {
    final filter = Filter(
      kinds: [NostrConstants.classifiedListingKind],
      tTags: [NostrConstants.topicHospitality],
      limit: limit,
    );

    final controller = StreamController<List<HospitalityListing>>();
    final Map<String, HospitalityListing> listingsMap = {};
    bool hasEmitted = false;

    void emitCurrent() {
      if (controller.isClosed) return;
      var list = listingsMap.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      if (typeFilter == ListingTypeFilter.offersOnly) {
        list = list.where((l) => l.isOffer).toList();
      } else if (typeFilter == ListingTypeFilter.requestsOnly) {
        list = list.where((l) => l.isRequest).toList();
      }

      if (locationFilter != null && locationFilter.trim().isNotEmpty) {
        final query = locationFilter.toLowerCase();
        final filtered = list.where((l) =>
            l.location.toLowerCase().contains(query) ||
            l.title.toLowerCase().contains(query) ||
            l.content.toLowerCase().contains(query)).toList();
        controller.add(filtered);
      } else {
        controller.add(list);
      }
      hasEmitted = true;
    }

    // Fallback timer to ensure initial UI loads even if 0 events exist on relay
    final timer = Timer(const Duration(milliseconds: 1200), () {
      if (!hasEmitted && !controller.isClosed) {
        emitCurrent();
      }
    });

    final subscription = _nostrService.queryEvents(filters: [filter]).listen(
      (event) {
        final listing = HospitalityListing.fromNip01Event(event);
        if (listing != null) {
          final existing = listingsMap[listing.addressCoordinate];
          if (existing == null || listing.createdAt.isAfter(existing.createdAt)) {
            listingsMap[listing.addressCoordinate] = listing;
            emitCurrent();
          }
        }
      },
      onError: (e) {
        if (!controller.isClosed) {
          if (!hasEmitted) emitCurrent();
        }
      },
      onDone: () {
        if (!hasEmitted) emitCurrent();
        if (!controller.isClosed) controller.close();
      },
    );

    controller.onCancel = () {
      timer.cancel();
      subscription.cancel();
    };

    return controller.stream;
  }

  /// Streams all listings (both hosting offers and stay requests) published by an author.
  Stream<List<HospitalityListing>> getAuthorListingsStream(String authorPubkey) {
    final filter = Filter(
      kinds: [NostrConstants.classifiedListingKind],
      authors: [authorPubkey],
      tTags: [NostrConstants.topicHospitality],
      limit: 20,
    );

    final controller = StreamController<List<HospitalityListing>>();
    final Map<String, HospitalityListing> listingsMap = {};
    bool hasEmitted = false;

    void emitCurrent() {
      if (controller.isClosed) return;
      final list = listingsMap.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      controller.add(list);
      hasEmitted = true;
    }

    final timer = Timer(const Duration(milliseconds: 1000), () {
      if (!hasEmitted && !controller.isClosed) {
        emitCurrent();
      }
    });

    final sub = _nostrService.queryEvents(filters: [filter]).listen(
      (event) {
        final listing = HospitalityListing.fromNip01Event(event);
        if (listing != null) {
          final existing = listingsMap[listing.dTag];
          if (existing == null || listing.createdAt.isAfter(existing.createdAt)) {
            listingsMap[listing.dTag] = listing;
            emitCurrent();
          }
        }
      },
      onError: (_) {
        if (!controller.isClosed) {
          if (!hasEmitted) emitCurrent();
        }
      },
      onDone: () {
        if (!hasEmitted) emitCurrent();
        if (!controller.isClosed) controller.close();
      },
    );

    controller.onCancel = () {
      timer.cancel();
      sub.cancel();
    };

    return controller.stream;
  }

  /// Fetches all listings published by a specific author.
  Future<List<HospitalityListing>> getListingsForAuthor(String authorPubkey) async {
    final filter = Filter(
      kinds: [NostrConstants.classifiedListingKind],
      authors: [authorPubkey],
      tTags: [NostrConstants.topicHospitality],
      limit: 20,
    );

    final Map<String, HospitalityListing> listingsMap = {};

    try {
      final completer = Completer<List<HospitalityListing>>();

      final sub = _nostrService.queryEvents(filters: [filter]).listen(
        (event) {
          final listing = HospitalityListing.fromNip01Event(event);
          if (listing != null) {
            final existing = listingsMap[listing.dTag];
            if (existing == null || listing.createdAt.isAfter(existing.createdAt)) {
              listingsMap[listing.dTag] = listing;
            }
          }
        },
        onDone: () {
          if (!completer.isCompleted) {
            final list = listingsMap.values.toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
            completer.complete(list);
          }
        },
        onError: (_) {
          if (!completer.isCompleted) completer.complete([]);
        },
      );

      return await completer.future.timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          sub.cancel();
          return listingsMap.values.toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        },
      );
    } catch (_) {
      return [];
    }
  }

  /// Fetches the primary hosting offer for a specific author pubkey.
  /// Prefers an offer (`isOffer = true`), falling back to the latest listing.
  Future<HospitalityListing?> getListingForAuthor(String authorPubkey) async {
    final listings = await getListingsForAuthor(authorPubkey);
    if (listings.isEmpty) return null;

    // Prefer explicit offer
    final offer = listings.where((l) => l.isOffer).firstOrNull;
    return offer ?? listings.first;
  }

  /// Fetches a listing by its addressable coordinate "30402:`pubkey`:`d-tag`".
  Future<HospitalityListing?> getListingByCoordinate(String coordinate) async {
    final parts = coordinate.split(':');
    if (parts.length < 3) return null;

    final author = parts[1];
    final dTag = parts.sublist(2).join(':');

    final filter = Filter(
      kinds: [NostrConstants.classifiedListingKind],
      authors: [author],
      dTags: [dTag],
      limit: 1,
    );

    try {
      final completer = Completer<HospitalityListing?>();

      final sub = _nostrService.queryEvents(filters: [filter]).listen(
        (event) {
          final listing = HospitalityListing.fromNip01Event(event);
          if (listing != null && !completer.isCompleted) {
            completer.complete(listing);
          }
        },
        onDone: () {
          if (!completer.isCompleted) completer.complete(null);
        },
        onError: (_) {
          if (!completer.isCompleted) completer.complete(null);
        },
      );

      return await completer.future.timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          sub.cancel();
          return null;
        },
      );
    } catch (_) {
      return null;
    }
  }

  /// Publishes or updates a NIP-99 classified hospitality listing.
  Future<HospitalityListing> publishListing(HospitalityListing draft) async {
    final pubkey = _nostrService.signerService.activePublicKey;
    if (pubkey == null) {
      throw StateError('Cannot publish listing: user is not authenticated.');
    }

    final nip01Event = draft.toNip01Event(authorPubkey: pubkey);
    await _nostrService.broadcastEvent(nip01Event);

    return HospitalityListing.fromNip01Event(nip01Event) ?? draft;
  }
}
