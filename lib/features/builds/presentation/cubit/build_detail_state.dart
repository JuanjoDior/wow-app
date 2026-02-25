import 'package:equatable/equatable.dart';
import 'package:wow_companion/features/builds/domain/entities/build.dart';

abstract class BuildDetailState extends Equatable {
  const BuildDetailState();
  @override
  List<Object?> get props => [];
}

class BuildDetailLoading extends BuildDetailState {
  const BuildDetailLoading();
}

class BuildDetailLoaded extends BuildDetailState {
  final Build build;
  const BuildDetailLoaded(this.build);

  BuildDetailLoaded copyWith({Build? build}) =>
      BuildDetailLoaded(build ?? this.build);

  @override
  List<Object?> get props => [build];
}

class BuildDetailError extends BuildDetailState {
  final String message;
  const BuildDetailError(this.message);
  @override
  List<Object?> get props => [message];
}
