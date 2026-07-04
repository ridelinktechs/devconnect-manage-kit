import 'dart:collection';

/// A simple LRU (least-recently-used) cache with a byte-based size cap
/// and opt-in pinning for entries that must survive eviction.
///
/// Sizing is approximate: each entry's "weight" is whatever the caller
/// reports via [weightOf]. The cache evicts the oldest non-pinned entries
/// whenever the total reported weight exceeds [maxBytes]. Pinned entries
/// are preserved across evictions; only when EVERY remaining entry is
/// pinned do we fall back to evicting from the head.
///
/// Insertion order is preserved by [LinkedHashMap]'s iteration order —
/// `get` re-inserts the entry to mark it as most-recently used, and
/// eviction removes from the head.
///
/// Usage:
/// ```dart
/// final cache = LruCache<int, MyValue>(
///   maxBytes: 10 * 1024 * 1024,
///   weightOf: (v) => v.estimatedBytes,
/// );
/// cache.put(1, value);
/// cache.pin(1); // entry 1 will survive subsequent evictions
/// ```
class LruCache<K, V> {
  /// Maximum total reported weight before eviction kicks in.
  final int maxBytes;

  /// Returns the weight of a single cached value (bytes).
  final int Function(V value) weightOf;

  /// Optional callback invoked once per evicted entry. Useful for logging
  /// or for releasing external resources held by the value.
  final void Function(K key, V value)? onEvict;

  final LinkedHashMap<K, V> _map = LinkedHashMap<K, V>();
  final Set<K> _pinned = <K>{};
  int _currentBytes = 0;

  LruCache({
    required this.maxBytes,
    required this.weightOf,
    this.onEvict,
  });

  /// Number of entries currently cached.
  int get length => _map.length;

  /// Sum of weights reported by all entries. Approximate.
  int get currentBytes => _currentBytes;

  /// Returns the cached value for [key] and marks it as most-recently used,
  /// or `null` if absent.
  V? get(K key) {
    final v = _map.remove(key);
    if (v == null) return null;
    _map[key] = v; // re-insert → moves to tail (most-recently used)
    return v;
  }

  /// Returns true if [key] is in the cache. Does NOT mark as recently used.
  bool containsKey(K key) => _map.containsKey(key);

  /// Returns true if [key] is currently pinned (immune to eviction).
  bool isPinned(K key) => _pinned.contains(key);

  /// Marks [key] as pinned — its entry will not be evicted by [put] unless
  /// every remaining entry is also pinned (in which case eviction falls
  /// back to LRU).
  ///
  /// Pinning is idempotent. The pin survives even if [key] is not yet in
  /// the cache — a subsequent [put] for the same key will be pinned
  /// automatically. This matters when callers pin during [initState] but
  /// the entry is inserted asynchronously by a later [put].
  void pin(K key) {
    _pinned.add(key);
  }

  /// Removes the pin on [key]. The entry becomes evictable again. Does
  /// not remove the entry itself.
  void unpin(K key) {
    _pinned.remove(key);
  }

  /// Inserts or replaces [key]'s value. If the new entry alone exceeds
  /// [maxBytes], the entry is refused to keep memory bounded.
  ///
  /// Eviction walks the map from the head (least-recently-used) and
  /// removes the first non-pinned entry. If every remaining entry is
  /// pinned, falls back to evicting from the head regardless.
  void put(K key, V value) {
    final w = weightOf(value);
    if (w >= maxBytes) {
      // Refuse pathological entries that would dominate the budget.
      _map.remove(key);
      _pinned.remove(key);
      _currentBytes = _totalWeight();
      return;
    }

    // Replace existing entry — adjust byte count first.
    final existing = _map.remove(key);
    if (existing != null) {
      _currentBytes -= weightOf(existing);
    }

    _map[key] = value;
    _currentBytes += w;

    // Evict from head until under budget. Skip pinned entries; fall back
    // to head-of-map only if everything left is pinned.
    while (_currentBytes > maxBytes && _map.isNotEmpty) {
      K? victimKey;
      for (final k in _map.keys) {
        if (!_pinned.contains(k)) {
          victimKey = k;
          break;
        }
      }
      // All entries pinned — evict head anyway to honor the budget.
      victimKey ??= _map.keys.first;
      final victimValue = _map.remove(victimKey);
      _pinned.remove(victimKey);
      if (victimValue != null && victimKey != null) {
        _currentBytes -= weightOf(victimValue);
        onEvict?.call(victimKey, victimValue);
      }
    }
  }

  /// Removes [key]. Returns the removed value, or `null` if absent.
  V? remove(K key) {
    _pinned.remove(key);
    final v = _map.remove(key);
    if (v != null) _currentBytes -= weightOf(v);
    return v;
  }

  /// Empties the cache, invoking [onEvict] for every removed entry.
  void clear() {
    if (onEvict != null) {
      for (final e in _map.entries) {
        onEvict!(e.key, e.value);
      }
    }
    _map.clear();
    _pinned.clear();
    _currentBytes = 0;
  }

  int _totalWeight() {
    var total = 0;
    for (final v in _map.values) {
      total += weightOf(v);
    }
    return total;
  }
}