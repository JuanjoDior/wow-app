import 'package:wow_companion/features/search/domain/search_entry.dart';

/// Contract for search history storage.
abstract class SearchHistoryRepository {
  Future<List<SearchEntry>> getHistory();
  Future<void> addEntry(SearchEntry entry);
  Future<void> removeEntry(String key);
  Future<void> clearHistory();
}
