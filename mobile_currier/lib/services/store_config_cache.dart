import 'api_service.dart';

/// Cached store configuration. Loaded from the backend on first access,
/// falls back to the legacy hard-coded values defined in
/// `NominatimService.STORE_*` if the API call fails.
class StoreConfigCache {
  StoreConfigCache._();

  static final StoreConfigCache instance = StoreConfigCache._();

  Map<String, dynamic>? _cached;
  Future<void>? _inFlight;

  /// Returns the cached config if available, otherwise triggers a fetch.
  /// If you need to force a re-fetch (e.g. after a known change), pass
  /// `forceRefresh: true`.
  Future<Map<String, dynamic>> get({bool forceRefresh = false}) async {
    if (!forceRefresh && _cached != null) return _cached!;
    if (_inFlight != null) {
      await _inFlight;
      return _cached ?? _fallback();
    }
    _inFlight = _load();
    try {
      await _inFlight;
    } finally {
      _inFlight = null;
    }
    return _cached ?? _fallback();
  }

  /// Synchronous accessor for the cached value or null. Call `get()` first
  /// if you need to ensure the data is loaded.
  Map<String, dynamic>? get cachedOrNull => _cached;

  Future<void> _load() async {
    try {
      final config = await ApiService.fetchStoreConfig();
      _cached = config;
    } catch (_) {
      _cached = _fallback();
    }
  }

  Map<String, dynamic> _fallback() => const {
        'address': 'Jl. Kedung Rukem IV / 55',
        'lat': -7.2628478,
        'lng': 112.7336368,
      };

  /// For tests / hot-reload.
  void clear() {
    _cached = null;
  }
}