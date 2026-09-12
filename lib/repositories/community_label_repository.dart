import 'dart:async';
import 'package:ndk/entities.dart';
import '../core/constants/nostr_constants.dart';
import '../core/nostr/nostr_service.dart';
import '../models/community_label.dart';

/// Repository for querying and publishing Kind 1985 Community Labels (NIP-32).
/// Maintains an in-memory reactive cache so published and deleted labels
/// reflect in the UI immediately without requiring a manual pull-to-refresh.
class CommunityLabelRepository {
  final NostrService _nostrService;

  final Map<String, Map<String, CommunityLabel>> _cache = {};
  final Map<String, StreamController<List<CommunityLabel>>> _controllers = {};

  CommunityLabelRepository(this._nostrService);

  void _emitForSubject(String subjectPubkey) {
    final controller = _controllers[subjectPubkey];
    if (controller != null && !controller.isClosed) {
      final list = (_cache[subjectPubkey]?.values.toList() ?? [])
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      controller.add(list);
    }
  }

  /// Streams community labels targeting a specific subject pubkey.
  Stream<List<CommunityLabel>> getLabelsForUserStream(String subjectPubkey) {
    _cache.putIfAbsent(subjectPubkey, () => {});

    // Create a broadcast controller so multiple widgets can listen
    final controller = StreamController<List<CommunityLabel>>.broadcast();
    _controllers[subjectPubkey] = controller;

    // Immediately emit current cached labels if available
    scheduleMicrotask(() {
      _emitForSubject(subjectPubkey);
    });

    final filter = Filter(
      kinds: [NostrConstants.labelKind],
      pTags: [subjectPubkey],
      limit: 100,
    );

    final subscription = _nostrService.queryEvents(filters: [filter]).listen(
      (event) {
        final label = CommunityLabel.fromNip01Event(event);
        if (label != null && label.targetPubkey == subjectPubkey) {
          final map = _cache[subjectPubkey]!;
          if (!map.containsKey(label.id)) {
            map[label.id] = label;
            _emitForSubject(subjectPubkey);
          }
        }
      },
      onError: (_) {
        _emitForSubject(subjectPubkey);
      },
      onDone: () {
        _emitForSubject(subjectPubkey);
      },
    );

    controller.onCancel = () {
      subscription.cancel();
    };

    return controller.stream;
  }

  /// Publishes a new Kind 1985 Community Label to Nostr relays and updates local cache immediately.
  Future<CommunityLabel> publishLabel(CommunityLabel draft) async {
    final pubkey = _nostrService.signerService.activePublicKey;
    if (pubkey == null) {
      throw StateError('Cannot publish label: user is not authenticated.');
    }

    final nip01Event = draft.toNip01Event(authorPubkey: pubkey);
    final signedEvent = await _nostrService.signEvent(nip01Event);
    await _nostrService.broadcastEvent(signedEvent);

    final published = CommunityLabel.fromNip01Event(signedEvent) ?? draft;

    // Optimistically update memory cache and notify active listeners immediately
    final target = draft.targetPubkey;
    _cache.putIfAbsent(target, () => {})[published.id] = published;
    _emitForSubject(target);

    return published;
  }

  /// Deletes an authored label event via a standard Kind 5 deletion request (NIP-09).
  Future<void> deleteLabel(String labelEventId, {String? targetPubkey}) async {
    final pubkey = _nostrService.signerService.activePublicKey;
    if (pubkey == null) {
      throw StateError('Cannot delete label: user is not authenticated.');
    }

    // Optimistically remove from cache and notify UI
    if (targetPubkey != null && _cache.containsKey(targetPubkey)) {
      _cache[targetPubkey]!.remove(labelEventId);
      _emitForSubject(targetPubkey);
    } else {
      for (final target in _cache.keys) {
        if (_cache[target]!.containsKey(labelEventId)) {
          _cache[target]!.remove(labelEventId);
          _emitForSubject(target);
          break;
        }
      }
    }

    final deleteEvent = Nip01Event(
      pubKey: pubkey,
      kind: 5, // NIP-09 deletion
      tags: [
        ['e', labelEventId],
        ['k', NostrConstants.labelKind.toString()],
      ],
      content: 'Deleted community label',
      createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );

    await _nostrService.broadcastEvent(deleteEvent);
  }
}
