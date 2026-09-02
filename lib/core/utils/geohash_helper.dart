import 'dart:convert';
import 'package:http/http.dart' as http;

/// City location result with coordinates and geohash.
class CitySearchResult {
  final String displayName;
  final double latitude;
  final double longitude;
  final String geohash;

  const CitySearchResult({
    required this.displayName,
    required this.latitude,
    required this.longitude,
    required this.geohash,
  });
}

/// Pure Dart implementation of standard Base32 Geohash encoding, decoding, and area bounding.
///
/// Follows the Nostr hospitality / classifieds privacy policy where locations
/// are bounded to 3 to 5 characters (defaulting to 5 characters, ~5km neighborhood box).
class GeohashHelper {
  GeohashHelper._();

  static const String _base32 = '0123456789bcdefghjkmnpqrstuvwxyz';
  static final Map<String, int> _base32Map = {
    for (int i = 0; i < _base32.length; i++) _base32[i]: i,
  };

  /// Encodes latitude and longitude into a geohash string of [precision] characters.
  /// Defaults to 5 characters for Kind 30402 homeshare neighborhood privacy (~5km box).
  static String encode(double latitude, double longitude, {int precision = 5}) {
    if (latitude < -90.0 || latitude > 90.0) {
      throw ArgumentError('Latitude must be between -90 and 90');
    }
    if (longitude < -180.0 || longitude > 180.0) {
      throw ArgumentError('Longitude must be between -180 and 180');
    }

    double latMin = -90.0;
    double latMax = 90.0;
    double lonMin = -180.0;
    double lonMax = 180.0;

    final StringBuffer result = StringBuffer();
    int bit = 0;
    int ch = 0;
    bool isEven = true;

    while (result.length < precision) {
      if (isEven) {
        final double mid = (lonMin + lonMax) / 2;
        if (longitude >= mid) {
          ch |= (1 << (4 - bit));
          lonMin = mid;
        } else {
          lonMax = mid;
        }
      } else {
        final double mid = (latMin + latMax) / 2;
        if (latitude >= mid) {
          ch |= (1 << (4 - bit));
          latMin = mid;
        } else {
          latMax = mid;
        }
      }

      isEven = !isEven;
      if (bit < 4) {
        bit++;
      } else {
        result.write(_base32[ch]);
        bit = 0;
        ch = 0;
      }
    }

    return result.toString();
  }

  /// Decodes a geohash into its center latitude, longitude, and bounding box corners.
  static ({double latitude, double longitude, double latMin, double latMax, double lonMin, double lonMax})?
      decode(String geohash) {
    if (geohash.trim().isEmpty) return null;

    final normalized = geohash.trim().toLowerCase();
    double latMin = -90.0;
    double latMax = 90.0;
    double lonMin = -180.0;
    double lonMax = 180.0;

    bool isEven = true;

    for (int i = 0; i < normalized.length; i++) {
      final char = normalized[i];
      final val = _base32Map[char];
      if (val == null) return null; // Invalid geohash character

      for (int bit = 4; bit >= 0; bit--) {
        final bitValue = (val >> bit) & 1;
        if (isEven) {
          final mid = (lonMin + lonMax) / 2;
          if (bitValue == 1) {
            lonMin = mid;
          } else {
            lonMax = mid;
          }
        } else {
          final mid = (latMin + latMax) / 2;
          if (bitValue == 1) {
            latMin = mid;
          } else {
            latMax = mid;
          }
        }
        isEven = !isEven;
      }
    }

    final centerLat = (latMin + latMax) / 2;
    final centerLon = (lonMin + lonMax) / 2;

    return (
      latitude: centerLat,
      longitude: centerLon,
      latMin: latMin,
      latMax: latMax,
      lonMin: lonMin,
      lonMax: lonMax,
    );
  }

  /// Generates the 4 corner points of a geohash bounding box for drawing rectangles on maps.
  static List<({double lat, double lon})>? getBoundingBoxCorners(String geohash) {
    final decoded = decode(geohash);
    if (decoded == null) return null;

    return [
      (lat: decoded.latMin, lon: decoded.lonMin), // Bottom-Left
      (lat: decoded.latMax, lon: decoded.lonMin), // Top-Left
      (lat: decoded.latMax, lon: decoded.lonMax), // Top-Right
      (lat: decoded.latMin, lon: decoded.lonMax), // Bottom-Right
    ];
  }

  /// Generates cascading prefix geohashes up to [maxPrecision] for Nostr `g` tag spatial queries.
  /// (e.g. "c23nb" -> ["c", "c2", "c23", "c23n", "c23nb"])
  static List<String> cascadingPrefixes(String geohash, {int maxPrecision = 5}) {
    final clean = geohash.trim().toLowerCase();
    final limit = clean.length < maxPrecision ? clean.length : maxPrecision;
    final prefixes = <String>[];
    for (int i = 1; i <= limit; i++) {
      prefixes.add(clean.substring(0, i));
    }
    return prefixes;
  }

  /// Asynchronously searches for cities by query string.
  /// Uses OpenStreetMap Nominatim with a fallback to local offline cities.
  static Future<List<CitySearchResult>> searchCities(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return [];

    final results = <CitySearchResult>[];

    // Check local offline database first
    for (final entry in defaultLocations.entries) {
      if (entry.key.toLowerCase().contains(cleanQuery.toLowerCase())) {
        results.add(
          CitySearchResult(
            displayName: entry.key,
            latitude: entry.value.lat,
            longitude: entry.value.lon,
            geohash: entry.value.geohash,
          ),
        );
      }
    }

    // Attempt online OpenStreetMap Nominatim search
    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
        'q': cleanQuery,
        'format': 'json',
        'addressdetails': '1',
        'limit': '6',
      });

      final response = await http.get(
        uri,
        headers: {'User-Agent': 'nostr-hospitality-app/1.0 (contact@nostrhospitality.org)'},
      ).timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        for (final item in data) {
          final lat = double.tryParse(item['lat']?.toString() ?? '');
          final lon = double.tryParse(item['lon']?.toString() ?? '');
          final name = item['display_name']?.toString();

          if (lat != null && lon != null && name != null) {
            // Simplify long display name to City, State/Country
            final parts = name.split(',').map((s) => s.trim()).toList();
            final shortName = parts.length > 2
                ? '${parts[0]}, ${parts[1]}, ${parts.last}'
                : name;

            final g = encode(lat, lon, precision: 5);

            // Avoid duplicate entries
            if (!results.any((r) => r.geohash == g)) {
              results.add(
                CitySearchResult(
                  displayName: shortName,
                  latitude: lat,
                  longitude: lon,
                  geohash: g,
                ),
              );
            }
          }
        }
      }
    } catch (_) {
      // Offline fallback
    }

    return results;
  }

  /// Sample known city coordinates for offline fallback and quick suggestions.
  static const Map<String, ({double lat, double lon, String geohash})> defaultLocations = {
    'Seattle, WA, USA': (lat: 47.6062, lon: -122.3321, geohash: 'c23nb'),
    'Portland, OR, USA': (lat: 45.5152, lon: -122.6784, geohash: 'c20fb'),
    'San Francisco, CA, USA': (lat: 37.7749, lon: -122.4194, geohash: '9q8yy'),
    'Los Angeles, CA, USA': (lat: 34.0522, lon: -118.2437, geohash: '9q5ct'),
    'Austin, TX, USA': (lat: 30.2672, lon: -97.7431, geohash: '9v6kn'),
    'Denver, CO, USA': (lat: 39.7392, lon: -104.9903, geohash: '9xj3v'),
    'New York, NY, USA': (lat: 40.7128, lon: -74.0060, geohash: 'dr5re'),
    'Vancouver, BC, Canada': (lat: 49.2827, lon: -123.1207, geohash: 'c2b2q'),
    'Mexico City, Mexico': (lat: 19.4326, lon: -99.1332, geohash: '9g3w4'),
    'Berlin, Germany': (lat: 52.5200, lon: 13.4050, geohash: 'u33dc'),
    'London, UK': (lat: 51.5074, lon: -0.1278, geohash: 'gcpvj'),
    'Paris, France': (lat: 48.8566, lon: 2.3522, geohash: 'u09tv'),
    'Barcelona, Spain': (lat: 41.3879, lon: 2.1699, geohash: 'sp3e5'),
    'Rome, Italy': (lat: 41.9028, lon: 12.4964, geohash: 'sr2yk'),
    'Tokyo, Japan': (lat: 35.6762, lon: 139.6503, geohash: 'xn774'),
    'Buenos Aires, Argentina': (lat: -34.6037, lon: -58.3816, geohash: '69y7p'),
    'Sydney, Australia': (lat: -33.8688, lon: 151.2093, geohash: 'r3gx2'),
  };
}
