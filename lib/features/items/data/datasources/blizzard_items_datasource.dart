import 'package:dio/dio.dart';
import 'package:wow_companion/core/error/exceptions.dart';
import 'package:wow_companion/core/network/api_client.dart';
import 'package:wow_companion/features/items/data/models/item_model.dart';
import 'package:wow_companion/core/cache/memory_cache.dart';
import 'package:wow_companion/features/items/domain/entities/item_search_mode.dart';

class BlizzardItemsDataSource {
  final ApiClient _client;
  final bool _catalogV2Enabled;
  final _searchCache = MemoryCache<List<ItemModel>>(
    ttl: const Duration(minutes: 5),
  );
  final _detailCache = MemoryCache<ItemModel>(ttl: const Duration(minutes: 10));

  static const _workerUrl =
      'https://wow-companion-api.wow-comp-app.workers.dev';
  static const _catalogWorkerUrl =
      'https://wow-recommendations.wow-comp-app.workers.dev';
  static const _catalogV2Endpoint = '$_catalogWorkerUrl/v2/catalog/search';
  static const _catalogHealthEndpoint = '$_catalogWorkerUrl/health';
  static const _catalogV2EnabledByFlag = bool.fromEnvironment(
    'CATALOG_SEARCH_V2',
    defaultValue: false,
  );

  bool? _supportsCatalogV2;

  BlizzardItemsDataSource(this._client, {bool? catalogV2Enabled})
    : _catalogV2Enabled = catalogV2Enabled ?? _catalogV2EnabledByFlag;

  Future<List<ItemModel>> searchItems(
    String name, {
    ItemSearchMode mode = ItemSearchMode.item,
    String? inventoryType,
    String? slot,
    String region = 'eu',
    String locale = 'en_GB',
  }) async {
    final key = [
      name.toLowerCase(),
      mode.apiValue,
      inventoryType ?? '',
      slot ?? '',
      region.toLowerCase(),
      locale,
    ].join(':');
    final cached = _searchCache.get(key);
    if (cached != null) return cached;

    try {
      List<ItemModel> items;
      if (_catalogV2Enabled) {
        items = await _searchItemsCatalogV2(
          name,
          mode: mode,
          inventoryType: inventoryType,
          slot: slot,
          region: region,
          locale: locale,
        );
        // Si no hay candidatos en V2 para un modo especializado, intentamos legacy.
        if (items.isEmpty && mode != ItemSearchMode.item) {
          items = await _searchItemsLegacy(
            name,
            inventoryType: inventoryType,
            locale: locale,
          );
        }
      } else {
        items = await _searchItemsLegacy(
          name,
          inventoryType: inventoryType,
          locale: locale,
        );
      }

      _searchCache.set(key, items);
      return items;
    } on DioException catch (e) {
      if (_catalogV2Enabled && _shouldFallbackFromCatalogError(e)) {
        final items = await _searchItemsLegacy(
          name,
          inventoryType: inventoryType,
          locale: locale,
        );
        _searchCache.set(key, items);
        return items;
      }
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

  Future<List<ItemModel>> _searchItemsCatalogV2(
    String name, {
    required ItemSearchMode mode,
    String? inventoryType,
    String? slot,
    String region = 'eu',
    String locale = 'en_GB',
  }) async {
    final supportsV2 = await _isCatalogV2Supported();
    if (!supportsV2) {
      return _searchItemsLegacy(
        name,
        inventoryType: inventoryType,
        locale: locale,
      );
    }

    final queryParams = <String, dynamic>{
      'q': name,
      'mode': mode.apiValue,
      'locale': locale,
      'region': region.toLowerCase(),
      'limit': '40',
    };
    if (inventoryType != null && inventoryType.isNotEmpty) {
      queryParams['inventory_type'] = inventoryType;
    }
    if (slot != null && slot.trim().isNotEmpty) {
      queryParams['slot'] = slot.trim();
    }

    final data = await _client.get(
      _catalogV2Endpoint,
      queryParameters: queryParams,
      expectedErrorStatusCodes: {404, 405, 501, 503},
    );

    final rawResults = data['results'];
    if (rawResults is! List) {
      throw const FormatException('Invalid catalog response');
    }

    return rawResults
        .whereType<Map<String, dynamic>>()
        .map(_mapCatalogResultToItemModel)
        .toList();
  }

  Future<List<ItemModel>> _searchItemsLegacy(
    String name, {
    String? inventoryType,
    String locale = 'en_GB',
  }) async {
    final queryParams = <String, dynamic>{'name': name, 'locale': locale};
    if (inventoryType != null && inventoryType.isNotEmpty) {
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
  }

  ItemModel _mapCatalogResultToItemModel(Map<String, dynamic> raw) {
    final id = (raw['id'] as num).toInt();
    final localizedName = _asTrimmedString(raw['name_localized']);
    final canonicalName = _asTrimmedString(raw['name_en_us']);
    final fallbackName =
        _asTrimmedString(raw['display_name']) ??
        localizedName ??
        canonicalName ??
        'Unknown';
    final storedName = canonicalName?.isNotEmpty == true
        ? canonicalName!
        : fallbackName;
    final quality = _asTrimmedString(raw['quality']) ?? 'COMMON';

    return ItemModel(
      id: id,
      name: storedName,
      quality: quality,
      level: (raw['level'] as num?)?.toInt(),
      itemClass: _asTrimmedString(raw['item_class']),
      itemSubclass: _asTrimmedString(raw['item_subclass']),
      inventoryType: _asTrimmedString(raw['inventory_type']),
      inventoryName: _asTrimmedString(raw['inventory_name']),
      iconUrl: _asTrimmedString(raw['icon_url']),
      localizedName: localizedName,
      canonicalNameEn: canonicalName ?? storedName,
    );
  }

  String? _asTrimmedString(dynamic value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  Future<bool> _isCatalogV2Supported() async {
    if (_supportsCatalogV2 != null) return _supportsCatalogV2!;
    try {
      final health = await _client.get(
        _catalogHealthEndpoint,
        expectedErrorStatusCodes: {404, 405, 501, 503},
      );
      final capabilities = health['capabilities'];
      if (capabilities is Map<String, dynamic>) {
        _supportsCatalogV2 = capabilities['catalog_search_v2'] == true;
      } else {
        _supportsCatalogV2 = false;
      }
    } on DioException {
      _supportsCatalogV2 = false;
    }
    return _supportsCatalogV2 ?? false;
  }

  bool _shouldFallbackFromCatalogError(DioException e) {
    final status = e.response?.statusCode;
    if (status != null && const {404, 405, 501, 503}.contains(status)) {
      return true;
    }
    return e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError;
  }

  Future<ItemModel> getItemById(int id, {String locale = 'en_GB'}) async {
    final key = '$id:$locale';
    final cached = _detailCache.get(key);
    if (cached != null) return cached;

    try {
      final data = await _client.get(
        '$_workerUrl/api/items/$id',
        queryParameters: {'locale': locale},
      );
      final item = ItemModel.fromJson(data);
      _detailCache.set(key, item);
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
