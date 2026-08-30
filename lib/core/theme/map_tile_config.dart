import 'package:flutter/material.dart';

/// Centralized configuration for map tile layers.
///
/// Uses standard OpenStreetMap tile CDN which provides full browser CORS support,
/// zero watermarks, no API keys required, and reliable global caching for web and mobile.
class MapTileConfig {
  MapTileConfig._();

  static const String lightTileUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  static const String darkTileUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  static const List<String> subdomains = ['a', 'b', 'c'];

  static const String userAgentPackageName = 'com.hospitalitylibre.app';

  /// Returns the tile URL template.
  static String getTileUrl(BuildContext context) {
    return lightTileUrl;
  }
}
