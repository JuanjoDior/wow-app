import 'package:equatable/equatable.dart';
import 'package:wow_companion/core/wow/character_search_input.dart';

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
  String get realmSlug => normalizeRealmForRequest(_safeDecodeRealm(realm));

  /// Display-friendly realm name
  String get displayRealm {
    final decoded = _safeDecodeRealm(realm).trim();
    if (decoded.isEmpty) return decoded;
    final asWords = decoded.replaceAll('-', ' ');
    return asWords
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .map(_capitalizeApostropheWord)
        .join(' ');
  }

  String _capitalizeApostropheWord(String word) {
    return word
        .split("'")
        .map((part) {
          if (part.isEmpty) return part;
          return part[0].toUpperCase() + part.substring(1).toLowerCase();
        })
        .join("'");
  }

  String _safeDecodeRealm(String input) {
    try {
      return Uri.decodeComponent(input);
    } catch (_) {
      return input;
    }
  }

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
