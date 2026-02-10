/// Generic in-memory cache with TTL (Time To Live).
/// Usable for any feature, not coupled to Character.
class MemoryCache<T> {
  final Duration ttl;
  final Map<String, _CacheEntry<T>> _store = {};

  MemoryCache({this.ttl = const Duration(minutes: 5)});

  /// Get a cached value by key. Returns null if expired or missing.
  T? get(String key) {
    final entry = _store[key];
    if (entry == null) return null;

    if (DateTime.now().isAfter(entry.expiry)) {
      _store.remove(key);
      return null;
    }

    return entry.value;
  }

  /// Store a value with automatic expiry based on TTL.
  void set(String key, T value) {
    _store[key] = _CacheEntry(value: value, expiry: DateTime.now().add(ttl));
  }

  /// Remove a specific entry.
  void remove(String key) => _store.remove(key);

  /// Clear all cached entries.
  void clear() => _store.clear();

  /// Number of entries currently in cache.
  int get length => _store.length;
}

class _CacheEntry<T> {
  final T value;
  final DateTime expiry;

  _CacheEntry({required this.value, required this.expiry});
}
