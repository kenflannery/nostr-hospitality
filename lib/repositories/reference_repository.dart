import 'dart:async';
import 'package:ndk/entities.dart';
import '../core/constants/nostr_constants.dart';
import '../core/nostr/nostr_service.dart';
import '../models/interaction_reference.dart';
import '../models/reference_summary.dart';

/// Repository for creating and querying Kind 7654 Interaction References.
class ReferenceRepository {
  final NostrService _nostrService;

  ReferenceRepository(this._nostrService);

  /// Streams references received by a given subject pubkey.
  Stream<List<InteractionReference>> getReferencesForUserStream(String subjectPubkey) {
    final filter = Filter(
      kinds: [NostrConstants.interactionReferenceKind],
      pTags: [subjectPubkey],
      limit: 100,
    );

    final controller = StreamController<List<InteractionReference>>();
    final Map<String, InteractionReference> referencesMap = {};
    bool hasEmitted = false;

    void emitCurrent() {
      if (controller.isClosed) return;
      final list = referencesMap.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      controller.add(list);
      hasEmitted = true;
    }

    final timer = Timer(const Duration(milliseconds: 1200), () {
      if (!hasEmitted && !controller.isClosed) {
        emitCurrent();
      }
    });

    final subscription = _nostrService.queryEvents(filters: [filter]).listen(
      (event) {
        final ref = InteractionReference.fromNip01Event(event);
        if (ref != null && ref.subjectPubkey == subjectPubkey) {
          if (!referencesMap.containsKey(ref.id)) {
            referencesMap[ref.id] = ref;
            emitCurrent();
          }
        }
      },
      onError: (e) {
        if (!controller.isClosed && !hasEmitted) emitCurrent();
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

  /// Fetches references for a user synchronously with a timeout.
  Future<List<InteractionReference>> getReferencesForUser(
    String subjectPubkey, {
    Duration timeout = const Duration(seconds: 3),
  }) async {
    final filter = Filter(
      kinds: [NostrConstants.interactionReferenceKind],
      pTags: [subjectPubkey],
      limit: 100,
    );

    final references = <InteractionReference>[];
    final completer = Completer<List<InteractionReference>>();

    final sub = _nostrService.queryEvents(filters: [filter]).listen(
      (event) {
        final ref = InteractionReference.fromNip01Event(event);
        if (ref != null && ref.subjectPubkey == subjectPubkey) {
          references.add(ref);
        }
      },
      onDone: () {
        if (!completer.isCompleted) completer.complete(references);
      },
      onError: (_) {
        if (!completer.isCompleted) completer.complete(references);
      },
    );

    try {
      return await completer.future.timeout(
        timeout,
        onTimeout: () {
          sub.cancel();
          return references;
        },
      );
    } catch (_) {
      return references;
    }
  }

  /// Computes a factual [ReferenceSummary] aggregation from a list of references.
  ReferenceSummary calculateSummary(List<InteractionReference> references) {
    return ReferenceSummary.fromReferences(references);
  }

  /// Publishes a new Kind 7654 Interaction Reference event to Nostr relays.
  Future<InteractionReference> publishReference(InteractionReference draft) async {
    final pubkey = _nostrService.signerService.activePublicKey;
    if (pubkey == null) {
      throw StateError('Cannot publish reference: user is not authenticated.');
    }

    final nip01Event = draft.toNip01Event(authorPubkey: pubkey);
    await _nostrService.broadcastEvent(nip01Event);

    return InteractionReference.fromNip01Event(nip01Event) ?? draft;
  }
}
