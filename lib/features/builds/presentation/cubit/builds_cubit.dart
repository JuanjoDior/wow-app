import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wow_companion/features/builds/domain/entities/build.dart';
import 'package:wow_companion/features/builds/domain/repositories/builds_repository.dart';
import 'package:wow_companion/features/builds/presentation/cubit/builds_state.dart';

class BuildsCubit extends Cubit<BuildsState> {
  final BuildsRepository _repository;

  BuildsCubit(this._repository) : super(const BuildsLoading());

  Future<void> loadBuilds() async {
    try {
      final builds = await _repository.getBuilds();
      emit(BuildsLoaded(builds));
    } catch (e) {
      emit(BuildsError(e.toString()));
    }
  }

  Future<void> saveBuild(Build build) async {
    await _repository.saveBuild(build);
    await loadBuilds();
  }

  Future<void> deleteBuild(String id) async {
    await _repository.deleteBuild(id);
    await loadBuilds();
  }
}
