import 'package:dio/dio.dart';
import 'package:wow_companion/core/error/exceptions.dart';
import 'package:wow_companion/core/network/api_client.dart';
import 'package:wow_companion/features/items/data/models/item_model.dart';
import 'package:wow_companion/core/cache/memory_cache.dart';

class BlizzardItemsDataSource {
  final ApiClient _client;
  final _searchCache = MemoryCache<List<ItemModel>>(
    ttl: const Duration(minutes: 5),
  );
  final _detailCache = MemoryCache<ItemModel>(
    ttl: const Duration(minutes: 10),
  );

  static const _workerUrl =
      'https://wow-companion-api.wow-comp-app.workers.dev';

  BlizzardItemsDataSource(this._client);

  Future<List<ItemModel>> searchItems(
    String name, {
    String? inventoryType,
    String locale = 'en_GB',
  }) async {
    final key = '${name.toLowerCase()}:${inventoryType ?? ''}:$locale';
    final cached = _searchCache.get(key);
    if (cached != null) return cached;

    try {
      final queryParams = <String, dynamic>{'name': name, 'locale': locale};
      if (inventoryType != null && inventoryType.isNotEmpty) {
        queryParams['inventoryType'] = inventoryType;
      }

      final data = await _client.get(
        '$_workerUrl/api/items/search',
        queryParameters: queryParams,
      );

      final results = data['results'] as List<dynamic>? ?? [];
      final items = results
          .map((e) => ItemModel.fromJson(e as Map<String, dynamic>))
          .toList();

      _searchCache.set(key, items);
      return items;
    } on DioException catch (e) {
      if (e.response?.statusCode == 429) throw const RateLimitException();
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw const NetworkException(message: 'Request timed out.');
      }
      if (e.type == DioExceptionType.connectionError) {
        throw const NetworkException();
      }
      throw ServerException(
        message: e.message ?? 'Unknown error',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<ItemModel> getItemById(int id) async {
    final cached = _detailCache.get('$id');
    if (cached != null) return cached;

    try {
      final data = await _client.get('$_workerUrl/api/items/$id');
      final item = ItemModel.fromJson(data);
      _detailCache.set('$id', item);
      return item;
    } on DioException catch (e) {
      if (e.response?.statusCode == 429) throw const RateLimitException();
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw const NetworkException(message: 'Request timed out.');
      }
      if (e.type == DioExceptionType.connectionError) {
        throw const NetworkException();
      }
      throw ServerException(
        message: e.message ?? 'Unknown error',
        statusCode: e.response?.statusCode,
      );
    }
  }
}
