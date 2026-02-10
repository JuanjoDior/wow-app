import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wow_companion/features/search/domain/search_entry.dart';
import 'package:wow_companion/features/search/domain/search_history_repository.dart';

class SearchHistoryRepositoryImpl implements SearchHistoryRepository {
  static const _storageKey = 'wow_search_history';
  static const _maxEntries = 10;

  @override
  Future<List<SearchEntry>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_storageKey);
    if (data == null) return [];

    final List<dynamic> list = jsonDecode(data) as List<dynamic>;
    return list
        .map((e) => SearchEntry.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.searchedAt.compareTo(a.searchedAt));
  }

  @override
  Future<void> addEntry(SearchEntry entry) async {
    final history = await getHistory();

    // Remove duplicate if exists (will be re-added at top with new timestamp)
    history.removeWhere((e) => e.key == entry.key);

    // Insert at beginning
    history.insert(0, entry);

    // Trim to max size
    final trimmed = history.take(_maxEntries).toList();

    await _save(trimmed);
  }

  @override
  Future<void> removeEntry(String key) async {
    final history = await getHistory();
    history.removeWhere((e) => e.key == key);
    await _save(history);
  }

  @override
  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }

  Future<void> _save(List<SearchEntry> history) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode(history.map((e) => e.toJson()).toList()),
    );
  }
}
