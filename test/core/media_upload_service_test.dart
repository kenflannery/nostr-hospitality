import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MediaUploadService Response Parsing Tests', () {
    test('Parses NIP-96 nip94_event tags correctly', () {
      const responseBody = '''{
        "status": "success",
        "nip94_event": {
          "tags": [
            ["url", "https://image.nostr.build/123456abcdef.jpg"],
            ["dim", "1920x1080"],
            ["m", "image/jpeg"]
          ]
        }
      }''';

      final decoded = jsonDecode(responseBody) as Map<String, dynamic>;
      String? extractedUrl;
      if (decoded['nip94_event'] != null && decoded['nip94_event']['tags'] is List) {
        final tags = decoded['nip94_event']['tags'] as List;
        for (final tag in tags) {
          if (tag is List && tag.length > 1 && tag[0] == 'url') {
            extractedUrl = tag[1].toString();
            break;
          }
        }
      }

      expect(extractedUrl, 'https://image.nostr.build/123456abcdef.jpg');
    });

    test('Parses nostr.build v2 data array response correctly', () {
      const responseBody = '''{
        "status": "success",
        "data": [
          {
            "url": "https://image.nostr.build/789012uvwxyz.png",
            "blurhash": "LEHLh[WB2yk8pyoJadR*.7kCMdnj",
            "dim": "1200x800"
          }
        ]
      }''';

      final decoded = jsonDecode(responseBody) as Map<String, dynamic>;
      String? extractedUrl;
      if (decoded['data'] is List && (decoded['data'] as List).isNotEmpty) {
        final first = (decoded['data'] as List).first;
        if (first is Map<String, dynamic> && first['url'] != null) {
          extractedUrl = first['url'].toString();
        }
      }

      expect(extractedUrl, 'https://image.nostr.build/789012uvwxyz.png');
    });
  });
}
