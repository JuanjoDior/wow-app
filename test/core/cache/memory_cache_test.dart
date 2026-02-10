import 'package:flutter_test/flutter_test.dart';
import 'package:wow_companion/core/cache/memory_cache.dart';

void main() {
  group('MemoryCache', () {
    late MemoryCache<String> cache;

    setUp(() {
      cache = MemoryCache<String>(ttl: const Duration(seconds: 2));
    });

    test('returns null for missing key', () {
      expect(cache.get('missing'), isNull);
    });

    test('stores and retrieves a value', () {
      cache.set('key1', 'hello');
      expect(cache.get('key1'), 'hello');
    });

    test('overwrites existing key', () {
      cache.set('key1', 'first');
      cache.set('key1', 'second');
      expect(cache.get('key1'), 'second');
    });

    test('removes a specific key', () {
      cache.set('key1', 'hello');
      cache.remove('key1');
      expect(cache.get('key1'), isNull);
    });

    test('clears all entries', () {
      cache.set('a', '1');
      cache.set('b', '2');
      cache.clear();
      expect(cache.length, 0);
    });

    test('returns null after TTL expires', () async {
      final shortCache = MemoryCache<String>(
        ttl: const Duration(milliseconds: 50),
      );
      shortCache.set('key1', 'hello');
      expect(shortCache.get('key1'), 'hello');

      await Future.delayed(const Duration(milliseconds: 100));
      expect(shortCache.get('key1'), isNull);
    });
  });
}
