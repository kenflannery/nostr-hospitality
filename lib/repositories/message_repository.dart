import 'dart:async';
import 'package:ndk/entities.dart';
import '../core/nostr/nostr_service.dart';
import '../core/nostr/signer_service.dart';
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
    final myPubkey = _nostrService.signerService.activePublicKey;
    if (myPubkey == null) return [];

    // ignore: avoid_print
    print('[MessageRepo] Starting loadConversations for pubkey: $myPubkey, signer: ${_nostrService.signerService.activeSignerType}');

    await _nostrService.ensureUserRelayListInCache(myPubkey);

    try {
      final isRemoteSigner = _nostrService.signerService.activeSignerType != SignerType.localKey;
      final timeout = isRemoteSigner ? const Duration(seconds: 15) : const Duration(seconds: 5);

      final conversations = await _nostrService.ndk.dms.loadConversations(
        forceRefresh: forceRefresh,
        timeout: timeout,
      );

      // ignore: avoid_print
      print('[MessageRepo] ndk.dms.loadConversations returned ${conversations.length} conversations');

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

      if (results.isNotEmpty) {
        results.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
        return results;
      }
    } catch (e) {
      // ignore: avoid_print
      print('[MessageRepo] ndk.dms.loadConversations error: $e');
    }

    // Fallback: Directly query Gift Wraps (Kind 1059) from configured relays and parse
    try {
      // ignore: avoid_print
      print('[MessageRepo] Running direct Kind 1059 query fallback on relays: ${_nostrService.relayConfig.relays}');
      final events = await _nostrService.queryEvents(
        filters: [
          Filter(
            kinds: [1059],
            pTags: [myPubkey],
            limit: 50,
          ),
        ],
      ).toList().timeout(const Duration(seconds: 8), onTimeout: () => []);

      // ignore: avoid_print
      print('[MessageRepo] Direct query returned ${events.length} Kind 1059 events');

      final byPeer = <String, Nip17Message>{};
      for (final event in events) {
        try {
          final msg = await _nostrService.ndk.dms.parseWrappedMessage(wrappedEvent: event);
          if (msg != null) {
            final existing = byPeer[msg.peerPubKey];
            if (existing == null || existing.createdAt < msg.createdAt) {
              byPeer[msg.peerPubKey] = msg;
            }
          }
        } catch (e) {
          // ignore: avoid_print
          print('[MessageRepo] parseWrappedMessage error: $e');
        }
      }

      final results = byPeer.entries.map((e) {
        return ConversationSummary(
          otherPubkey: e.key,
          lastMessage: e.value.content,
          lastMessageTime: DateTime.fromMillisecondsSinceEpoch(e.value.createdAt * 1000),
          unreadCount: 0,
        );
      }).toList();

      if (results.isNotEmpty) {
        results.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
        return results;
      }
    } catch (e) {
      // ignore: avoid_print
      print('[MessageRepo] Direct query fallback error: $e');
    }

    // Offline cache snapshot fallback
    try {
      final cached = await _nostrService.ndk.dms.loadConversationsSnapshot();
      final results = <ConversationSummary>[];
      for (final conv in cached) {
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
    final myPubkey = _nostrService.signerService.activePublicKey;
    if (myPubkey == null) return [];

    await _nostrService.ensureUserRelayListInCache(myPubkey);
    await _nostrService.ensureUserRelayListInCache(peerPubkey);

    try {
      final isRemoteSigner = _nostrService.signerService.activeSignerType != SignerType.localKey;
      final timeout = isRemoteSigner ? const Duration(seconds: 15) : const Duration(seconds: 5);

      final messagesList = await _nostrService.ndk.dms.loadConversation(
        peerPubKey: peerPubkey,
        forceRefresh: forceRefresh,
        timeout: timeout,
      );

      final messages = messagesList.map((m) {
        final isMine = m.isOutgoing;
        return ChatMessage(
          id: m.id,
          senderPubkey: isMine ? myPubkey : peerPubkey,
          recipientPubkey: isMine ? peerPubkey : myPubkey,
          content: m.content,
          createdAt: DateTime.fromMillisecondsSinceEpoch(m.createdAt * 1000),
          isMine: isMine,
        );
      }).toList();

      if (messages.isNotEmpty) {
        messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        return messages;
      }
    } catch (_) {}

    // Fallback direct query
    try {
      final events = await _nostrService.queryEvents(
        filters: [
          Filter(
            kinds: [1059],
            pTags: [myPubkey],
            limit: 100,
          ),
        ],
      ).toList().timeout(const Duration(seconds: 8), onTimeout: () => []);

      final messages = <ChatMessage>[];
      for (final event in events) {
        try {
          final msg = await _nostrService.ndk.dms.parseWrappedMessage(wrappedEvent: event);
          if (msg != null && msg.peerPubKey == peerPubkey) {
            final isMine = msg.isOutgoing;
            messages.add(
              ChatMessage(
                id: msg.id,
                senderPubkey: isMine ? myPubkey : peerPubkey,
                recipientPubkey: isMine ? peerPubkey : myPubkey,
                content: msg.content,
                createdAt: DateTime.fromMillisecondsSinceEpoch(msg.createdAt * 1000),
                isMine: isMine,
              ),
            );
          }
        } catch (_) {}
      }

      if (messages.isNotEmpty) {
        messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        return messages;
      }
    } catch (_) {}

    // Cache fallback
    try {
      final cached = await _nostrService.ndk.dms.loadConversationSnapshot(peerPubKey: peerPubkey);
      final messages = cached.map((m) {
        final isMine = m.isOutgoing;
        return ChatMessage(
          id: m.id,
          senderPubkey: isMine ? myPubkey : peerPubkey,
          recipientPubkey: isMine ? peerPubkey : myPubkey,
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
