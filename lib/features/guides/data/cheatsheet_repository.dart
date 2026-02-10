import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:wow_companion/features/guides/domain/entities/cheatsheet.dart';

class CheatsheetRepository {
  List<Cheatsheet>? _cache;

  Future<List<Cheatsheet>> getAll() async {
    if (_cache != null) return _cache!;

    final jsonString = await rootBundle.loadString(
      'assets/cheatsheets/cheatsheets.json',
    );
    final jsonList = json.decode(jsonString) as List<dynamic>;
    _cache = jsonList
        .map((e) => Cheatsheet.fromJson(e as Map<String, dynamic>))
        .toList();
    return _cache!;
  }

  Future<Cheatsheet?> getBySpec(String classSlug, String specSlug) async {
    final all = await getAll();
    try {
      return all.firstWhere(
        (c) => c.classSlug == classSlug && c.specSlug == specSlug,
      );
    } catch (_) {
      return null;
    }
  }

  Future<List<Cheatsheet>> getByRole(String role) async {
    final all = await getAll();
    return all
        .where((c) => c.role.toLowerCase() == role.toLowerCase())
        .toList();
  }
}
