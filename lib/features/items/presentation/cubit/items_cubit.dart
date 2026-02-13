import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wow_companion/features/items/domain/usecases/search_items.dart';
import 'package:wow_companion/features/items/presentation/cubit/items_state.dart';

class ItemsCubit extends Cubit<ItemsState> {
  final SearchItems _searchItems;

  ItemsCubit(this._searchItems) : super(const ItemsInitial());

  Future<void> search(
    String query, {
    String? inventoryType,
    String locale = 'en_GB',
  }) async {
    if (query.trim().length < 2) {
      emit(const ItemsInitial());
      return;
    }

    emit(const ItemsLoading());

    final result = await _searchItems(
      query.trim(),
      inventoryType: inventoryType,
      locale: locale,
    );

    result.fold(
      (failure) => emit(ItemsError(failure.message)),
      (items) =>
          items.isEmpty ? emit(const ItemsEmpty()) : emit(ItemsLoaded(items)),
    );
  }

  void clear() => emit(const ItemsInitial());
}
