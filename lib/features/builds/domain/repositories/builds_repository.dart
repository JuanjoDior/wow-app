// TODO Implement this library.
import 'package:wow_companion/features/builds/domain/entities/build.dart';

abstract class BuildsRepository {
  Future<List<Build>> getBuilds();
  Future<void> saveBuild(Build build);
  Future<void> deleteBuild(String id);
}
