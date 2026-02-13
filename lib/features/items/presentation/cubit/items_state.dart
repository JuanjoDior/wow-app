import 'package:equatable/equatable.dart';
import 'package:wow_companion/features/items/domain/entities/item.dart';

abstract class ItemsState extends Equatable {
  const ItemsState();
  @override
  List<Object?> get props => [];
}

class ItemsInitial extends ItemsState {
  const ItemsInitial();
}

class ItemsLoading extends ItemsState {
  const ItemsLoading();
}

class ItemsLoaded extends ItemsState {
  final List<Item> items;
  const ItemsLoaded(this.items);
  @override
  List<Object?> get props => [items];
}

class ItemsEmpty extends ItemsState {
  const ItemsEmpty();
}

class ItemsError extends ItemsState {
  final String message;
  const ItemsError(this.message);
  @override
  List<Object?> get props => [message];
}
