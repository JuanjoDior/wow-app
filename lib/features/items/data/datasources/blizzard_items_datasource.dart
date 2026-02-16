import 'package:dio/dio.dart';
import 'package:wow_companion/core/error/exceptions.dart';
import 'package:wow_companion/core/network/api_client.dart';
import 'package:wow_companion/features/items/data/models/item_model.dart';

class BlizzardItemsDataSource {
  final ApiClient _client;

  static const _workerUrl =
      'https://wow-companion-api.wow-comp-app.workers.dev';

  BlizzardItemsDataSource(this._client);

  Future<List<ItemModel>> searchItems(
    String name, {
    String? inventoryType,
    String locale = 'en_GB',
  }) async {
    try {
      final queryParams = <String, dynamic>{'name': name, 'locale': locale};
      if (inventoryType != null) {
        queryParams['inventoryType'] = inventoryType;
      }

      final data = await _client.get(
        '$_workerUrl/api/items/search',
        queryParameters: queryParams,
      );

      final results = data['results'] as List<dynamic>? ?? [];
      return results
          .map((e) => ItemModel.fromJson(e as Map<String, dynamic>))
          .toList();
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
    try {
      final data = await _client.get('$_workerUrl/api/items/$id');
      return ItemModel.fromJson(data as Map<String, dynamic>);
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
