import 'package:equatable/equatable.dart';
import 'package:wow_companion/features/builds/domain/entities/build.dart';

abstract class BuildsState extends Equatable {
  const BuildsState();
  @override
  List<Object?> get props => [];
}

class BuildsLoading extends BuildsState {
  const BuildsLoading();
}

class BuildsLoaded extends BuildsState {
  final List<Build> builds;
  const BuildsLoaded(this.builds);
  @override
  List<Object?> get props => [builds];
}

class BuildsError extends BuildsState {
  final String message;
  const BuildsError(this.message);
  @override
  List<Object?> get props => [message];
}
