import 'package:equatable/equatable.dart';

/// Represents a recent character search entry.
class SearchEntry extends Equatable {
  final String region;
  final String realm;
  final String name;
  final DateTime searchedAt;

  SearchEntry({
    required this.region,
    required this.realm,
    required this.name,
    DateTime? searchedAt,
  }) : searchedAt = searchedAt ?? DateTime.now();

  /// Unique key to avoid duplicates
  String get key =>
      '${region.toLowerCase()}-${realm.toLowerCase()}-${name.toLowerCase()}';

  /// Slug for navigation
  String get realmSlug => realm.toLowerCase().replaceAll(' ', '-');

  /// Display-friendly realm name
  String get displayRealm =>
      realm.split('-').map((w) {
        if (w.isEmpty) return w;
        return w[0].toUpperCase() + w.substring(1).toLowerCase();
      }).join(' ');

  Map<String, dynamic> toJson() => {
    'region': region,
    'realm': realm,
    'name': name,
    'searchedAt': searchedAt.toIso8601String(),
  };

  factory SearchEntry.fromJson(Map<String, dynamic> json) {
    return SearchEntry(
      region: json['region'] as String,
      realm: json['realm'] as String,
      name: json['name'] as String,
      searchedAt: DateTime.parse(json['searchedAt'] as String),
    );
  }

  @override
  List<Object?> get props => [region, realm, name];
}
