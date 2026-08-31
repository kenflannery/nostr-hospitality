import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'package:ndk/entities.dart';

JSObject? _getNostrObject() {
  if (!globalContext.hasProperty('nostr'.toJS).toDart) {
    return null;
  }
  return globalContext.getProperty('nostr'.toJS) as JSObject?;
}

Future<bool> isNip07Available() async {
  return _getNostrObject() != null;
}

Future<String> getNip07PublicKey() async {
  final nostr = _getNostrObject();
  if (nostr == null) {
    throw StateError('No NIP-07 browser extension (e.g. Alby, nos2x) detected on window.nostr');
  }

  final promise = nostr.callMethod('getPublicKey'.toJS) as JSPromise;
  final result = await promise.toDart;
  return (result as JSString).toDart;
}

Future<Nip01Event> signEventWithNip07(Nip01Event event) async {
  final nostr = _getNostrObject();
  if (nostr == null) {
    throw StateError('No NIP-07 extension detected');
  }

  // Convert Nip01Event to JS Object
  final eventMap = {
    'kind': event.kind,
    'content': event.content,
    'tags': event.tags,
    'created_at': event.createdAt,
    'pubkey': event.pubKey,
  };

  final jsEvent = jsonEncode(eventMap).toJS;
  final parsedJsObj = globalContext.getProperty('JSON'.toJS) as JSObject;
  final jsEventObj = parsedJsObj.callMethod('parse'.toJS, jsEvent) as JSObject;

  final promise = nostr.callMethod('signEvent'.toJS, jsEventObj) as JSPromise;
  final signedJsResult = await promise.toDart;
  final stringified = (parsedJsObj.callMethod('stringify'.toJS, signedJsResult as JSAny) as JSString).toDart;
  final decoded = jsonDecode(stringified) as Map<String, dynamic>;

  return Nip01Event(
    id: decoded['id'] as String? ?? event.id,
    pubKey: decoded['pubkey'] as String? ?? event.pubKey,
    kind: decoded['kind'] as int? ?? event.kind,
    tags: (decoded['tags'] as List<dynamic>?)
            ?.map((t) => (t as List<dynamic>).map((e) => e.toString()).toList())
            .toList() ??
        event.tags,
    content: decoded['content'] as String? ?? event.content,
    createdAt: decoded['created_at'] as int? ?? event.createdAt,
    sig: decoded['sig'] as String? ?? event.sig,
  );
}

Future<String?> nip04EncryptWithNip07(String plaintext, String recipientPubKey) async {
  final nostr = _getNostrObject();
  if (nostr == null || !nostr.hasProperty('nip04'.toJS).toDart) return null;

  final nip04 = nostr.getProperty('nip04'.toJS) as JSObject;
  final promise = nip04.callMethod('encrypt'.toJS, recipientPubKey.toJS, plaintext.toJS) as JSPromise;
  final result = await promise.toDart;
  return (result as JSString).toDart;
}

Future<String?> nip04DecryptWithNip07(String ciphertext, String senderPubKey) async {
  final nostr = _getNostrObject();
  if (nostr == null || !nostr.hasProperty('nip04'.toJS).toDart) return null;

  final nip04 = nostr.getProperty('nip04'.toJS) as JSObject;
  final promise = nip04.callMethod('decrypt'.toJS, senderPubKey.toJS, ciphertext.toJS) as JSPromise;
  final result = await promise.toDart;
  return (result as JSString).toDart;
}

Future<String?> nip44EncryptWithNip07(String plaintext, String recipientPubKey) async {
  final nostr = _getNostrObject();
  if (nostr == null || !nostr.hasProperty('nip44'.toJS).toDart) return null;

  final nip44 = nostr.getProperty('nip44'.toJS) as JSObject;
  final promise = nip44.callMethod('encrypt'.toJS, recipientPubKey.toJS, plaintext.toJS) as JSPromise;
  final result = await promise.toDart;
  return (result as JSString).toDart;
}

Future<String?> nip44DecryptWithNip07(String ciphertext, String senderPubKey) async {
  final nostr = _getNostrObject();
  if (nostr == null || !nostr.hasProperty('nip44'.toJS).toDart) return null;

  final nip44 = nostr.getProperty('nip44'.toJS) as JSObject;
  final promise = nip44.callMethod('decrypt'.toJS, senderPubKey.toJS, ciphertext.toJS) as JSPromise;
  final result = await promise.toDart;
  return (result as JSString).toDart;
}
