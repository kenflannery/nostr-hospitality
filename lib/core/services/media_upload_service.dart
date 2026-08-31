import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:ndk/entities.dart';
import '../nostr/nostr_service.dart';

/// Service for uploading media files to Nostr media servers (NIP-96 / NIP-98).
class MediaUploadService {
  final NostrService? _nostrService;

  MediaUploadService([this._nostrService]);

  static const String nostrBuildNip96Endpoint = 'https://nostr.build/api/v2/nip96/upload';
  static const String nostrBuildV2Endpoint = 'https://nostr.build/api/v2/upload/files';

  /// Uploads raw image bytes to nostr.build using NIP-96 / NIP-98 authentication.
  ///
  /// Returns the permanent HTTPS image URL on success.
  Future<String> uploadImage({
    required Uint8List bytes,
    required String filename,
  }) async {
    try {
      return await _uploadToEndpoint(
        endpoint: nostrBuildNip96Endpoint,
        bytes: bytes,
        filename: filename,
      );
    } catch (e) {
      // Secondary fallback to nostrcheck.me
      try {
        return await _uploadToEndpoint(
          endpoint: 'https://cdn.nostrcheck.me/api/v2/nip96/upload',
          bytes: bytes,
          filename: filename,
        );
      } catch (_) {
        rethrow;
      }
    }
  }

  Future<String> _uploadToEndpoint({
    required String endpoint,
    required Uint8List bytes,
    required String filename,
  }) async {
    final uri = Uri.parse(endpoint);
    final request = http.MultipartRequest('POST', uri);

    // Attach image file
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: filename.isNotEmpty ? filename : 'upload.jpg',
      ),
    );

    // Attach NIP-98 HTTP Auth token if NostrService is available
    if (_nostrService != null) {
      try {
        final authEvent = await _createNip98AuthHeader(endpoint, 'POST');
        if (authEvent != null && authEvent.sig != null) {
          final payload = jsonEncode({
            'id': authEvent.id,
            'pubkey': authEvent.pubKey,
            'created_at': authEvent.createdAt,
            'kind': authEvent.kind,
            'tags': authEvent.tags,
            'content': authEvent.content,
            'sig': authEvent.sig,
          });
          final base64Token = base64Encode(utf8.encode(payload));
          request.headers['Authorization'] = 'Nostr $base64Token';
        }
      } catch (_) {
        // Fall back to unauthenticated public tier if signing is not active
      }
    }

    final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final decoded = jsonDecode(response.body);

      // 1. Try NIP-96 nip94_event tags
      if (decoded is Map<String, dynamic>) {
        if (decoded['nip94_event'] != null && decoded['nip94_event']['tags'] is List) {
          final tags = decoded['nip94_event']['tags'] as List;
          for (final tag in tags) {
            if (tag is List && tag.length > 1 && tag[0] == 'url') {
              return tag[1].toString();
            }
          }
        }

        // 2. Try v2 data array: data[0].url
        if (decoded['data'] is List && (decoded['data'] as List).isNotEmpty) {
          final first = (decoded['data'] as List).first;
          if (first is Map<String, dynamic> && first['url'] != null) {
            return first['url'].toString();
          }
        }

        // 3. Try direct url property
        if (decoded['url'] != null) {
          return decoded['url'].toString();
        }
      }

      throw Exception('Could not extract image URL from server response.');
    } else {
      throw Exception('Upload failed with status code ${response.statusCode}: ${response.body}');
    }
  }

  /// Generates a signed NIP-98 authorization event (Kind 27235).
  Future<Nip01Event?> _createNip98AuthHeader(String url, String method) async {
    if (_nostrService == null) return null;

    final unsigned = Nip01Event(
      pubKey: _nostrService.signerService.activePublicKey ?? '',
      kind: 27235, // NIP-98 HTTP Auth
      tags: [
        ['u', url],
        ['method', method],
      ],
      content: '',
      createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );

    return await _nostrService.signEvent(unsigned);
  }
}
