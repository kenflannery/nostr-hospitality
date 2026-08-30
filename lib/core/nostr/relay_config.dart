import 'package:shared_preferences/shared_preferences.dart';
import '../constants/nostr_constants.dart';

/// Manages active relays and persists user-configured relay lists.
class RelayConfig {
  static const String _storageKey = 'nostr_configured_relays';

  final SharedPreferences _prefs;
  List<String> _relays;

  RelayConfig(this._prefs, {List<String>? initialRelays})
      : _relays = initialRelays ?? _prefs.getStringList(_storageKey) ?? List.from(NostrConstants.defaultRelays);

  List<String> get relays => List.unmodifiable(_relays);

  Future<void> addRelay(String url) async {
    final trimmed = url.trim();
    if (trimmed.isEmpty || _relays.contains(trimmed)) return;
    _relays = [..._relays, trimmed];
    await _prefs.setStringList(_storageKey, _relays);
  }

  Future<void> removeRelay(String url) async {
    _relays = _relays.where((r) => r != url).toList();
    if (_relays.isEmpty) {
      _relays = List.from(NostrConstants.defaultRelays);
    }
    await _prefs.setStringList(_storageKey, _relays);
  }

  Future<void> resetToDefaults() async {
    _relays = List.from(NostrConstants.defaultRelays);
    await _prefs.remove(_storageKey);
  }
}
