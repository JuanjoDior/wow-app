import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wow_companion/features/builds/domain/entities/build.dart';
import 'package:wow_companion/features/builds/domain/repositories/builds_repository.dart';

class BuildsRepositoryImpl implements BuildsRepository {
  static const _storageKey = 'wow_builds';

  @override
  Future<List<Build>> getBuilds() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_storageKey);
    if (data == null) return [];

    final List<dynamic> list = jsonDecode(data) as List<dynamic>;
    return list.map((e) => Build.fromJson(e as Map<String, dynamic>)).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<void> saveBuild(Build build) async {
    final builds = await getBuilds();
    final index = builds.indexWhere((b) => b.id == build.id);
    if (index >= 0) {
      builds[index] = build;
    } else {
      builds.add(build);
    }
    await _save(builds);
  }

  @override
  Future<void> deleteBuild(String id) async {
    final builds = await getBuilds();
    builds.removeWhere((b) => b.id == id);
    await _save(builds);
  }

  Future<void> _save(List<Build> builds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode(builds.map((b) => b.toJson()).toList()),
    );
  }
}
