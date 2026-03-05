import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class WeeklyPlannerLocalProgressRepository {
  static const _storageKey = 'wow_weekly_planner_local_progress_v1';

  String buildPlannerKey({
    required String region,
    required String realm,
    required String name,
  }) {
    final normalizedRegion = region.trim().toLowerCase();
    final normalizedRealm = realm.trim().toLowerCase();
    final normalizedName = name.trim().toLowerCase();
    return '$normalizedRegion|$normalizedRealm|$normalizedName';
  }

  String buildWeekKey(DateTime date) {
    final utcDate = date.toUtc();
    final monday = utcDate.subtract(Duration(days: utcDate.weekday - 1));
    final year = monday.year.toString().padLeft(4, '0');
    final month = monday.month.toString().padLeft(2, '0');
    final day = monday.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  Future<Set<String>> getCompletedTaskIds({
    required String plannerKey,
    required String weekKey,
  }) async {
    final payload = await _loadPayload();
    final key = _entryKey(plannerKey, weekKey);
    final rawValue = payload[key];
    if (rawValue is! List) return <String>{};
    return rawValue
        .whereType<String>()
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet();
  }

  Future<void> setCompletedTaskIds({
    required String plannerKey,
    required String weekKey,
    required Set<String> taskIds,
  }) async {
    final payload = await _loadPayload();
    final key = _entryKey(plannerKey, weekKey);
    if (taskIds.isEmpty) {
      payload.remove(key);
    } else {
      payload[key] = taskIds.toList()..sort();
    }
    await _savePayload(payload);
  }

  Future<void> clearCompletedTaskIds({
    required String plannerKey,
    required String weekKey,
  }) async {
    final payload = await _loadPayload();
    final key = _entryKey(plannerKey, weekKey);
    payload.remove(key);
    await _savePayload(payload);
  }

  String _entryKey(String plannerKey, String weekKey) => '$plannerKey|$weekKey';

  Future<Map<String, dynamic>> _loadPayload() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.trim().isEmpty) {
      return <String, dynamic>{};
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      if (decoded is Map) {
        return decoded.map((key, value) => MapEntry(key.toString(), value));
      }
    } catch (_) {
      return <String, dynamic>{};
    }
    return <String, dynamic>{};
  }

  Future<void> _savePayload(Map<String, dynamic> payload) async {
    final prefs = await SharedPreferences.getInstance();
    if (payload.isEmpty) {
      await prefs.remove(_storageKey);
      return;
    }
    await prefs.setString(_storageKey, jsonEncode(payload));
  }
}
