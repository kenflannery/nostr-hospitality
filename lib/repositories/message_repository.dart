import 'dart:async';
import 'package:ndk/entities.dart';
import '../core/nostr/nostr_service.dart';
import '../models/chat_message.dart';

/// Repository managing NIP-17 private user-to-user messaging.
class MessageRepository {
  final NostrService _nostrService;

  MessageRepository(this._nostrService);

  /// Ensures the user's NIP-17 DM Relays (Kind 10050) and NIP-65 Relays (Kind 10002) are published.
  Future<void> ensureUserRelayListsPublished() async {
    final myPubkey = _nostrService.signerService.activePublicKey;
    if (myPubkey == null) return;

    final relays = _nostrService.relayConfig.relays;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    final nip17RelayEvent = Nip01Event(
      pubKey: myPubkey,
      kind: 10050,
      tags: relays.map((r) => ['relay', r]).toList(),
      content: '',
      createdAt: now,
    );

    final nip65RelayEvent = Nip01Event(
      pubKey: myPubkey,
      kind: 10002,
      tags: relays.map((r) => ['r', r]).toList(),
      content: '',
      createdAt: now,
    );

    try {
      await _nostrService.broadcastEvent(nip17RelayEvent);
      await _nostrService.broadcastEvent(nip65RelayEvent);
    } catch (_) {}
  }

  /// Loads all conversation summaries for the logged-in user.
  Future<List<ConversationSummary>> loadConversations({bool forceRefresh = false}) async {
    try {
      final conversations = await _nostrService.ndk.dms.loadConversations(
        forceRefresh: forceRefresh,
        timeout: const Duration(seconds: 4),
      );

      final results = <ConversationSummary>[];

      for (final conv in conversations) {
        final lastMsg = conv.latestMessage;
        final createdAt = conv.latestCreatedAt;
        results.add(
          ConversationSummary(
            otherPubkey: conv.peerPubKey,
            lastMessage: lastMsg.content,
            lastMessageTime: DateTime.fromMillisecondsSinceEpoch(createdAt * 1000),
            unreadCount: 0,
          ),
        );
      }

      results.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
      return results;
    } catch (_) {
      return [];
    }
  }

  /// Loads the message history for a specific conversation with [peerPubkey].
  Future<List<ChatMessage>> loadMessages(String peerPubkey, {bool forceRefresh = false}) async {
    try {
      final messagesList = await _nostrService.ndk.dms.loadConversation(
        peerPubKey: peerPubkey,
        forceRefresh: forceRefresh,
        timeout: const Duration(seconds: 4),
      );

      final myPubkey = _nostrService.signerService.activePublicKey;

      final messages = messagesList.map((m) {
        final isMine = m.isOutgoing;
        return ChatMessage(
          id: m.id,
          senderPubkey: isMine ? (myPubkey ?? '') : peerPubkey,
          recipientPubkey: isMine ? peerPubkey : (myPubkey ?? ''),
          content: m.content,
          createdAt: DateTime.fromMillisecondsSinceEpoch(m.createdAt * 1000),
          isMine: isMine,
        );
      }).toList();

      messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return messages;
    } catch (_) {
      return [];
    }
  }

  /// Sends a private NIP-17 direct message to [recipientPubkey].
  Future<ChatMessage> sendMessage({
    required String recipientPubkey,
    required String content,
  }) async {
    final myPubkey = _nostrService.signerService.activePublicKey;
    if (myPubkey == null) {
      throw StateError('Cannot send message: user is not authenticated.');
    }

    // Guarantee sender and recipient have fallback relay routing in cache
    await _nostrService.ensureUserRelayListInCache(myPubkey);
    await _nostrService.ensureUserRelayListInCache(recipientPubkey);
    await ensureUserRelayListsPublished();

    try {
      await _nostrService.ndk.dms.sendMessage(
        recipientPubKey: recipientPubkey,
        content: content.trim(),
      );
    } catch (e) {
      // Re-ensure cache routing and retry
      await _nostrService.ensureUserRelayListInCache(recipientPubkey);
      await _nostrService.ndk.dms.sendMessage(
        recipientPubKey: recipientPubkey,
        content: content.trim(),
      );
    }

    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderPubkey: myPubkey,
      recipientPubkey: recipientPubkey,
      content: content.trim(),
      createdAt: DateTime.now(),
      isMine: true,
    );
  }
}
