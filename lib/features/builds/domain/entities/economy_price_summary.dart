import 'package:equatable/equatable.dart';

class EconomyPriceSummarySource extends Equatable {
  final String? policy;
  final String? market;
  final String? data;

  const EconomyPriceSummarySource({this.policy, this.market, this.data});

  factory EconomyPriceSummarySource.fromJson(Map<String, dynamic> json) {
    return EconomyPriceSummarySource(
      policy: json['policy'] as String?,
      market: json['market'] as String?,
      data: json['data'] as String?,
    );
  }

  @override
  List<Object?> get props => [policy, market, data];
}

class EconomyPriceSummaryStats extends Equatable {
  final int requestedItems;
  final int resolvedItems;
  final int missingItems;

  const EconomyPriceSummaryStats({
    required this.requestedItems,
    required this.resolvedItems,
    required this.missingItems,
  });

  factory EconomyPriceSummaryStats.fromJson(Map<String, dynamic> json) {
    return EconomyPriceSummaryStats(
      requestedItems: (json['requested_items'] as num?)?.toInt() ?? 0,
      resolvedItems: (json['resolved_items'] as num?)?.toInt() ?? 0,
      missingItems: (json['missing_items'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  List<Object?> get props => [requestedItems, resolvedItems, missingItems];
}

class EconomyPriceResult extends Equatable {
  final int itemId;
  final String? market;
  final String? currency;
  final int? minPrice;
  final int? medianPrice;
  final int? p95Price;
  final int totalQuantity;
  final int listingCount;

  const EconomyPriceResult({
    required this.itemId,
    this.market,
    this.currency,
    this.minPrice,
    this.medianPrice,
    this.p95Price,
    required this.totalQuantity,
    required this.listingCount,
  });

  factory EconomyPriceResult.fromJson(Map<String, dynamic> json) {
    return EconomyPriceResult(
      itemId: (json['item_id'] as num?)?.toInt() ?? 0,
      market: json['market'] as String?,
      currency: json['currency'] as String?,
      minPrice: (json['min_price'] as num?)?.toInt(),
      medianPrice: (json['median_price'] as num?)?.toInt(),
      p95Price: (json['p95_price'] as num?)?.toInt(),
      totalQuantity: (json['total_quantity'] as num?)?.toInt() ?? 0,
      listingCount: (json['listing_count'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  List<Object?> get props => [
    itemId,
    market,
    currency,
    minPrice,
    medianPrice,
    p95Price,
    totalQuantity,
    listingCount,
  ];
}

class EconomyPriceSummary extends Equatable {
  final String? version;
  final String? endpoint;
  final EconomyPriceSummarySource? source;
  final EconomyPriceSummaryStats summary;
  final List<EconomyPriceResult> results;

  const EconomyPriceSummary({
    this.version,
    this.endpoint,
    this.source,
    required this.summary,
    required this.results,
  });

  factory EconomyPriceSummary.fromJson(Map<String, dynamic> json) {
    final sourceRaw = json['source'] as Map<String, dynamic>?;
    final summaryRaw = json['summary'] as Map<String, dynamic>? ?? {};
    final resultsRaw = json['results'] as List<dynamic>? ?? [];
    return EconomyPriceSummary(
      version: json['version'] as String?,
      endpoint: json['endpoint'] as String?,
      source: sourceRaw == null
          ? null
          : EconomyPriceSummarySource.fromJson(sourceRaw),
      summary: EconomyPriceSummaryStats.fromJson(summaryRaw),
      results: resultsRaw
          .whereType<Map<String, dynamic>>()
          .map(EconomyPriceResult.fromJson)
          .toList(),
    );
  }

  @override
  List<Object?> get props => [version, endpoint, source, summary, results];
}
